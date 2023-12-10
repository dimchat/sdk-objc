// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
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
//  DIMSecureMessagePacker.m
//  DIMCore
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DIMSecureMessagePacker.h"

@interface DIMSecureMessagePacker ()

@property (weak, nonatomic) id<DKDSecureMessageDelegate> delegate;

@end

@implementation DIMSecureMessagePacker

- (instancetype)init {
    NSAssert(false, @"DON'T call me!");
    id<DKDSecureMessageDelegate> delegate = nil;
    return [self initWithDelegate:delegate];
}

/* designated initializer */
- (instancetype)initWithDelegate:(id<DKDSecureMessageDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
    }
    return self;
}

@end

@implementation DIMSecureMessagePacker (Decryption)

- (nullable id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg
                                     forReceiver:(id<MKMID>)receiver {
    NSAssert([receiver isUser], @"receiver error: %@", receiver);
    id<DKDSecureMessageDelegate> delegate = [self delegate];
    
    //
    //  1. Decode 'message.key' to encrypted symmetric key data
    //
    NSData *encryptedKey = [sMsg encryptedKey];
    NSData *keyData;
    if (encryptedKey) {
        NSAssert([encryptedKey length] > 0, @"encrypted key data should not be empty: %@ => %@, %@", sMsg.sender, receiver, sMsg.group);
        //
        //  2. Decrypt 'message.key' with receiver's private key
        //
        keyData = [delegate message:sMsg
                         decryptKey:encryptedKey
                        forReceiver:receiver];
        if (!keyData) {
            // A: my visa updated but the sender doesn't got the new one;
            // B: key data error.
            NSAssert(false, @"failed to decrypt key in message: %@ => %@, %@", sMsg.sender, receiver, sMsg.group);
            //@throw [NSException exceptionWithName:@"ReceiverError" reason:@"failed to decrypt key in msg" userInfo:[sMsg dictionary]];
            // TODO: check whether my visa key is changed, push new visa to this contact
            return nil;
        }
        NSAssert([keyData length] > 0, @"message key data should not be empty: %@ => %@, %@", sMsg.sender, receiver, sMsg.group);
    }
    
    //
    //  3. Deserialize message key from data (JsON / ProtoBuf / ...)
    //     (if key is empty, means it should be reused, get it from key cache)
    //
    id<MKMSymmetricKey> password = [delegate message:sMsg deserializeKey:keyData];
    if (!password) {
        // A: key data is empty, and cipher key not found from local storage;
        // B: key data error.
        NSAssert(false, @"failed to decrypt key in message: %@ => %@, %@", sMsg.sender, receiver, sMsg.group);
        //@throw [NSException exceptionWithName:@"CryptoKeyError" reason:@"failed to get message key" userInfo:[sMsg dictionary]];
        // TODO: ask the sender to send again (with new message key)
        return nil;
    }
    
    //
    //  4. Decode 'message.data' to encrypted content data
    //
    NSData *ciphertext = [sMsg data];
    if ([ciphertext length] == 0) {
        NSAssert(false, @"failed to decode message data: %@ => %@, %@", sMsg.sender, receiver, sMsg.group);
        return nil;
    }
    
    //
    //  5. Decrypt 'message.data' with symmetric key
    //
    NSData *body = [delegate message:sMsg
                      decryptContent:ciphertext
                             withKey:password];
    if (!body) {
        // A: password is a reused key loaded from local storage, but it's expired;
        // B: key error.
        NSAssert(false, @"failed to decrypt message data with key: %@, data length: %lu byte(s)", password, ciphertext.length);
        //@throw [NSException exceptionWithName:@"DecryptError" reason:@"failed to decrypt message" userInfo:[sMsg dictionary]];
        // TODO: ask the sender to send again
        return nil;
    }
    NSAssert([body length] > 0, @"message data should not be empty: %@ => %@, %@", sMsg.sender, receiver, sMsg.group);
    
    //
    //  6. Deserialize message content from data (JsON / ProtoBuf / ...)
    //
    id<DKDContent> content = [delegate message:sMsg
                            deserializeContent:body
                                       withKey:password];
    if (!content) {
        NSAssert(false, @"failed to deserialize content: %lu byte(s), %@ => %@, %@", body.length, sMsg.sender, receiver, sMsg.group);
        return nil;
    }
    
    // TODO: check attachment for File/Image/Audio/Video message content
    //      if URL exists, means file data was uploaded to a CDN,
    //          1. save password as 'content.key';
    //          2. try to download file data from CDN;
    //          3. decrypt downloaded data with 'content.key'.
    //      (do it by application)

    // OK, pack message
    NSMutableDictionary *info = [sMsg dictionary:NO];
    [info removeObjectForKey:@"key"];
    [info removeObjectForKey:@"keys"];
    [info removeObjectForKey:@"data"];
    [info setObject:content.dictionary forKey:@"content"];
    return DKDInstantMessageParse(info);
}

@end

@implementation DIMSecureMessagePacker (Signature)

- (id<DKDReliableMessage>)signMessage:(id<DKDSecureMessage>)sMsg {
    id<DKDSecureMessageDelegate> delegate = [self delegate];
    
    //
    //  0. decode message data
    //
    NSData *ciphertext = [sMsg data];
    NSAssert([ciphertext length] > 0, @"failed to to decode message data: %@ => %@, %@", sMsg.sender, sMsg.receiver, sMsg.group);
    
    //
    //  1. Sign 'message.data' with sender's private key
    //
    NSData *signature = [delegate message:sMsg signData:ciphertext];
    NSAssert([signature length] > 0, @"failed to sign message: %@ => %@, %@", sMsg.sender, sMsg.receiver, sMsg.group);
    
    //
    //  2. Encode 'message.signature' to String (Base64)
    //
    NSObject *base64 = MKMTransportableDataEncode(signature);
    //NSAssert([(NSString *)base64 length] > 0, @"failed to encode signature: %lu byte(s), %@ => %@, %@", signature.length, sMsg.sender, sMsg.receiver, sMsg.group);
    
    // OK, pack message
    NSMutableDictionary *info = [sMsg dictionary:NO];
    [info setObject:base64 forKey:@"signature"];
    return DKDReliableMessageParse(info);
}

@end
