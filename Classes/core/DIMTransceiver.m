// license: https://mit-license.org
//
//  DIMP : Decentralized Instant Messaging Protocol
//
//                               Written in 2018 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2018 Albert Moky
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// =============================================================================
//
//  DIMTransceiver.m
//  DIMCore
//
//  Created by Albert Moky on 2018/10/7.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DIMEncryptedData.h"

#import "DIMUser.h"
#import "DIMBarrack.h"
#import "DIMMessageCompressor.h"

#import "DIMTransceiver.h"

@implementation DIMTransceiver

- (id<MKMEntityDelegate>)facebook {
    NSAssert(false, @"implement me!");
    return nil;
}

- (id<DIMCompressor>)compressor {
    NSAssert(false, @"implement me!");
    return nil;
}

#pragma mark Packer

- (nullable NSData *)serializeMessage:(id<DKDReliableMessage>)rMsg {
    NSMutableDictionary *info = [rMsg dictionary];
    id<DIMCompressor> compressor = [self compressor];
    return [compressor compressReliableMessage:info];
}

- (nullable id<DKDReliableMessage>)deserializeMessage:(NSData *)data {
    id<DIMCompressor> compressor = [self compressor];
    NSDictionary *info = [compressor extractReliableMessage:data];
    return DKDReliableMessageParse(info);
}

#pragma mark DKDInstantMessageDelegate

// Override
- (NSData *)message:(id<DKDInstantMessage>)iMsg
   serializeContent:(id<DKDContent>)content
            withKey:(id<MKSymmetricKey>)password {
    // NOTICE: check attachment for File/Image/Audio/Video message content
    //         before serialize content, this job should be do in subclass
    NSMutableDictionary *info = [content dictionary];
    NSMutableDictionary *key = [password dictionary];
    id<DIMCompressor> compressor = [self compressor];
    return [compressor compressContent:info withKey:key];
}

// Override
- (NSData *)message:(id<DKDInstantMessage>)iMsg
     encryptContent:(NSData *)data
            withKey:(id<MKSymmetricKey>)password {
    // store 'IV' in iMsg for AES decryption
    NSMutableDictionary *params = [iMsg dictionary];
    return [password encrypt:data extra:params];
}

//// Override
//- (NSObject *)message:(id<DKDInstantMessage>)iMsg
//           encodeData:(NSData *)data {
//    if ([DIMMessage isBroadcast:iMsg]) {
//        // broadcast message content will not be encrypted (just encoded to JsON),
//        // so no need to encode to Base64 here
//        return MKUTF8Decode(data);
//    }
//    // message content had been encrypted by a symmetric key,
//    // so the data should be encoded here (with algorithm 'base64' as default).
//    return MKTransportableDataEncode(data);
//}

// Override
- (nullable NSData *)message:(id<DKDInstantMessage>)iMsg
                serializeKey:(id<MKSymmetricKey>)password {
    if ([DIMMessage isBroadcast:iMsg]) {
        // broadcast message has no key
        return nil;
    }
    NSMutableDictionary *key = [password dictionary];
    id<DIMCompressor> compressor = [self compressor];
    return [compressor compressSymmetricKey:key];
}

// Override
- (nullable id<DIMEncryptedData>)message:(id<DKDInstantMessage>)iMsg
                              encryptKey:(NSData *)data
                             forReceiver:(id<MKMID>)receiver {
    NSAssert(![DIMMessage isBroadcast:iMsg], @"broadcast message has no key: %@", iMsg);
    // TODO: make sure the receiver's public key exists
    id<MKMUser> contact = [self.facebook userForID:receiver];
    NSAssert(contact, @"failed to get encrypt key for receiver: %@", receiver);
    // encrypt with receiver's public key
    return [contact encrypt:data];
}

// Override
- (NSDictionary<NSString *, id> *)message:(id<DKDInstantMessage>)iMsg
                                encodeKey:(id<DIMEncryptedData>)data
                              forReceiver:(id<MKMID>)receiver {
    NSAssert(![DIMMessage isBroadcast:iMsg], @"broadcast message has no key: %@", iMsg);
    // message key had been encrypted by a public key,
    // so the data should be encode here (with algorithm 'base64' as default).
    return [data encodeForUserID:receiver];
    // TODO: check for wildcard
}

#pragma mark DKDSecureMessageDelegate

// Override
- (nullable id<DIMEncryptedData>)message:(id<DKDSecureMessage>)sMsg
                               decodeKey:(NSDictionary<NSString *, id> *)keys
                             forReceiver:(id<MKMID>)receiver {
    NSAssert(![DIMMessage isBroadcast:sMsg], @"broadcast message has no key: %@", sMsg);
    id<MKMUser> user = [self.facebook userForID:receiver];
    NSAssert(user, @"failed to decode key: %@ => %@, %@", sMsg.sender, receiver, sMsg.group);
    NSSet<NSString *> *terminals = [user terminals];
    NSAssert([terminals count] > 0, @"visa.terminals not found: %@", user);
    id<DIMEncryptedData> data = [DIMEncryptedData decodeMap:keys
                                                  forUserID:receiver
                                                  terminals:terminals];
    // check for wildcard
    if (!data || [data isEmpty]) {
        if (![terminals containsObject:@"*"]) {
            terminals = [[NSSet alloc] initWithObjects:@"*", nil];
            data = [DIMEncryptedData decodeMap:keys forUserID:receiver terminals:terminals];
        }
    }
    return data;
}

// Override
- (nullable NSData *)message:(id<DKDSecureMessage>)sMsg
                  decryptKey:(id<DIMEncryptedData>)data
                 forReceiver:(id<MKMID>)receiver {
    // NOTICE: the receiver must be a member ID
    //         if it's a group message
    NSAssert(![DIMMessage isBroadcast:sMsg], @"broadcast message has no key: %@", sMsg);
    NSAssert([receiver isUser], @"receiver error: %@", receiver);
    id<MKMUser> user = [self.facebook userForID:receiver];
    NSAssert(user, @"failed to get decrypt keys: %@", receiver);
    // decrypt with private key of the receiver (or group member)
    return [user decrypt:data];
}

// Override
- (nullable id<MKSymmetricKey>)message:(id<DKDSecureMessage>)sMsg
                        deserializeKey:(nullable NSData *)data {
    NSAssert(![DIMMessage isBroadcast:sMsg], @"broadcast message has no key: %@", sMsg);
    if ([data length] == 0) {
        NSAssert(false, @"reused key? get it from cache: %@ => %@, %@",
                 sMsg.sender, sMsg.receiver, sMsg.group);
        return nil;
    }
    id<DIMCompressor> compressor = [self compressor];
    NSDictionary *dict = [compressor extractSymmetricKey:data];
    return MKSymmetricKeyParse(dict);
}

//// Override
//- (nullable NSData *)message:(id<DKDSecureMessage>)sMsg
//                  decodeData:(NSObject *)dataString {
//    if ([DIMMessage isBroadcast:sMsg]) {
//        // broadcast message content will not be encrypted (just encoded to JsON),
//        // so return the string data directly
//        if ([dataString isKindOfClass:[NSString class]]) {
//            NSString *string = (NSString *)dataString;
//            return MKUTF8Encode(string);
//        }
//        NSAssert(false, @"content data error: %@", dataString);
//        return nil;
//    }
//    // message content had been encrypted by a symmetric key,
//    // so the data should be encoded here (with algorithm 'base64' as default).
//    return MKTransportableDataDecode(dataString);
//}

// Override
- (nullable NSData *)message:(id<DKDSecureMessage>)sMsg
              decryptContent:(NSData *)data
                     withKey:(id<MKSymmetricKey>)password {
    // TODO: check 'IV' in sMsg for AES decryption
    NSDictionary *extra = [sMsg dictionary];
    return [password decrypt:data params:extra];
}

// Override
- (nullable id<DKDContent>)message:(id<DKDSecureMessage>)sMsg
                deserializeContent:(NSData *)data
                           withKey:(id<MKSymmetricKey>)password {
    //NSAssert([sMsg.data length] > 0, @"message data empty");
    NSDictionary *key = [password dictionary];
    id<DIMCompressor> compressor = [self compressor];
    NSDictionary *dict = [compressor extractContent:data withKey:key];
    return DKDContentParse(dict);
}

// Override
- (NSData *)message:(id<DKDSecureMessage>)sMsg
           signData:(NSData *)data {
    id<MKMID> sender = [sMsg sender];
    id<MKMUser> user = [self.facebook userForID:sender];
    NSAssert(user, @"failed to get sign key for sender: %@", sender);
    return [user sign:data];
}

//// Override
//- (NSObject *)message:(id<DKDSecureMessage>)sMsg
//      encodeSignature:(NSData *)signature {
//    return MKMTransportableDataEncode(signature);
//}

#pragma mark DKDReliableMessageDelegate

//// Override
//- (nullable NSData *)message:(id<DKDReliableMessage>)rMsg
//             decodeSignature:(NSObject *)signatureString {
//    return MKMTransportableDataDecode(signatureString);
//}

// Override
- (BOOL)message:(id<DKDReliableMessage>)rMsg
     verifyData:(NSData *)data
  withSignature:(NSData *)signature {
    id<MKMID> sender = rMsg.sender;
    id<MKMUser> user = [self.facebook userForID:sender];
    NSAssert(user, @"failed to get verify key for sender: %@", sender);
    return [user verify:data withSignature:signature];
}

@end
