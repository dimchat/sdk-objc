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
//  DIMInstantMessagePacker.m
//  DIMCore
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DIMInstantMessagePacker.h"

@interface DIMInstantMessagePacker ()

@property (weak, nonatomic) id<DKDInstantMessageDelegate> delegate;

@end

@implementation DIMInstantMessagePacker

- (instancetype)init {
    NSAssert(false, @"DON'T call me!");
    id<DKDInstantMessageDelegate> delegate = nil;
    return [self initWithDelegate:delegate];
}

/* designated initializer */
- (instancetype)initWithDelegate:(id<DKDInstantMessageDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
    }
    return self;
}

@end

@implementation DIMInstantMessagePacker (Encryption)

- (nullable id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg
                                        withKey:(id<MKMSymmetricKey>)password {
    NSArray *members = nil;
    return [self encryptMessage:iMsg withKey:password forMembers:members];
}

- (nullable id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg
                                        withKey:(id<MKMSymmetricKey>)password
                                     forMembers:(NSArray<id<MKMID>> *)members {
    // TODO: check attachment for File/Image/Audio/Video message content
    //      (do it by application)
    id<DKDInstantMessageDelegate> delegate = [self delegate];

    //
    //  1. Serialize 'message.content' to data (JsON / ProtoBuf / ...)
    //
    NSData *body = [delegate message:iMsg
                    serializeContent:iMsg.content
                             withKey:password];
    NSAssert([body length] > 0, @"failed to serialize content: %@", iMsg.content);
    
    //
    //  2. Encrypt content data to 'message.data' with symmetric key
    //
    NSData *ciphertext = [delegate message:iMsg
                            encryptContent:body
                                   withKey:password];
    NSAssert([ciphertext length] > 0, @"failed to encrypt content with key: %@", password);

    //
    //  3. Encode 'message.data' to String (Base64)
    //
    NSObject *encodedData;
    if ([DIMMessage isBroadcast:iMsg]) {
        // broadcast message content will not be encrypted (just encoded to JsON),
        // so no need to encode to Base64 here
        encodedData = MKMUTF8Decode(ciphertext);
    } else {
        // message content had been encrypted by a symmetric key,
        // so the data should be encoded here (with algorithm 'base64' as default).
        encodedData = MKMTransportableDataEncode(ciphertext);
    }
    NSAssert(encodedData, @"failed to encode content data: %@", ciphertext);
    
    // replace 'content' with encrypted 'data'
    NSMutableDictionary *info = [iMsg dictionary:NO];
    [info removeObjectForKey:@"content"];
    [info setObject:encodedData forKey:@"data"];
    
    //
    //  4. Serialize message key to data (JsON / ProtoBuf / ...)
    //
    NSData *pwd = [delegate message:iMsg serializeKey:password];
    if (!pwd) {
        // A) broadcast message has no key
        // B) reused key
        return DKDSecureMessageParse(info);
    }
    
    NSData *encryptedKey;
    NSObject *encodedKey;
    if (!members)  // personal message
    {
        id<MKMID> receiver = [iMsg receiver];
        NSAssert([receiver isUser], @"message.receiver error: %@", receiver);
        //
        //  5. Encrypt key data to 'message.key/keys' with receiver's public key
        //
        encryptedKey = [delegate message:iMsg encryptKey:pwd forReceiver:receiver];
        if (!encryptedKey) {
            // public key for encryption not found
            // TODO: suspend this message for waiting receiver's visa
            return nil;
        }
        //
        //  6. Encode message key to String (Base64)
        //
        encodedKey = MKMTransportableDataEncode(encryptedKey);
        NSAssert(encodedKey, @"failed to encode key data: %@", encryptedKey);
        // insert as 'key'
        [info setObject:encodedKey forKey:@"key"];
    }
    else  // group message
    {
        NSMutableDictionary *keys = [[NSMutableDictionary alloc] initWithCapacity:members.count];
        for (id<MKMID> receiver in members) {
            //
            //  5. Encrypt key data to 'message.key/keys' with receiver's public key
            //
            encryptedKey = [delegate message:iMsg encryptKey:pwd forReceiver:receiver];
            if (!encryptedKey) {
                // public key for member not found
                // TODO: suspend this message for waiting member's visa
                continue;
            }
            //
            //  6. Encode message key to String (Base64)
            //
            encodedKey = MKMTransportableDataEncode(encryptedKey);
            NSAssert(encodedKey, @"failed to encode key data: %@", encryptedKey);
            // insert to 'message.keys' with member ID
            [keys setObject:encodedKey forKey:receiver.string];
        }
        if ([keys count] == 0) {
            // public key for member(s) not found
            // TODO: suspend this message for waiting member's visa
            return nil;
        }
        // insert as 'keys'
        [info setObject:keys forKey:@"keys"];
    }

    // OK, pack message
    return DKDSecureMessageParse(info);
}

@end
