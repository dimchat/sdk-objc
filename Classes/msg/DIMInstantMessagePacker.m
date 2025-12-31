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

#import "DIMEncryptedBundle.h"
#import "DKDMessageDelegates.h"

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
- (instancetype)initWithDelegate:(id<DKDInstantMessageDelegate>)messenger {
    if (self = [super init]) {
        self.delegate = messenger;
    }
    return self;
}

@end

@implementation DIMInstantMessagePacker (Encryption)

- (nullable id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg
                                        withKey:(id<MKSymmetricKey>)password {
    NSArray *members = nil;
    return [self encryptMessage:iMsg withKey:password forMembers:members];
}

- (nullable id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg
                                        withKey:(id<MKSymmetricKey>)password
                                     forMembers:(NSArray<id<MKMID>> *)members {
    // TODO: check attachment for File/Image/Audio/Video message content
    //      (do it by application)
    id<DKDInstantMessageDelegate> transceiver = [self delegate];
    NSAssert(transceiver, @"instant message delegate not found");

    //
    //  1. Serialize 'message.content' to data (JsON / ProtoBuf / ...)
    //
    NSData *body = [transceiver message:iMsg
                       serializeContent:iMsg.content
                                withKey:password];
    if ([body length] == 0) {
        NSAssert(false, @"failed to serialize content: %@", iMsg.content);
        return nil;
    }
    
    //
    //  2. Encrypt content data to 'message.data' with symmetric key
    //
    NSData *ciphertext = [transceiver message:iMsg
                               encryptContent:body
                                      withKey:password];
    if ([ciphertext length] == 0) {
        NSAssert(false, @"failed to encrypt content with key: %@", password);
        return nil;
    }

    //
    //  3. Encode 'message.data' to String (Base64)
    //
    NSObject *encodedData;
    if ([DIMMessage isBroadcast:iMsg]) {
        // broadcast message content will not be encrypted (just encoded to JsON),
        // so no need to encode to Base64 here
        encodedData = MKUTF8Decode(ciphertext);
    } else {
        // message content had been encrypted by a symmetric key,
        // so the data should be encoded here (with algorithm 'base64' as default).
        encodedData = MKTransportableDataEncode(ciphertext);
    }
    if (!encodedData) {
        NSAssert(false, @"failed to encode content data: %lu byte(s)", ciphertext.length);
        return nil;
    }
    
    // replace 'content' with encrypted 'data'
    NSMutableDictionary *info = [iMsg copyDictionary:NO];
    [info removeObjectForKey:@"content"];
    [info setObject:encodedData forKey:@"data"];
    
    //
    //  4. Serialize message key to data (JsON / ProtoBuf / ...)
    //
    NSData *pwd = [transceiver message:iMsg serializeKey:password];
    if (!pwd) {
        // A) broadcast message has no key
        // B) reused key
        return DKDSecureMessageParse(info);
    }
    // encrypt + encode key
    
    if (!members) {
        // personal message
        id<MKMID> receiver = [iMsg receiver];
        NSAssert([receiver isUser], @"message.receiver error: %@", receiver);
        members = @[
            receiver
        ];
    }
    
    NSMutableDictionary<id<MKMID>, id<DIMEncryptedBundle>> *bundleMap = [[NSMutableDictionary alloc] init];
    id<DIMEncryptedBundle> bundle;
    for (id<MKMID> receiver in members) {
        //
        //  5. Encrypt key data to 'message.keys' with member's public key
        //
        bundle = [transceiver message:iMsg encryptKey:pwd forReceiver:receiver];
        if (!bundle || [bundle isEmpty]) {
            // public key for member not found
            // TODO: suspend this message for waiting member's visa
            continue;;
        }
        [bundleMap setObject:bundle forKey:receiver];;
    }
    
    //
    //  6. Encode message key to String (Base64)
    //
    NSDictionary<NSString *, id> *msgKeys = [self message:iMsg encodeKeys:bundleMap];
    if ([msgKeys count] == 0) {
        // public key for member(s) not found
        // TODO: suspend this message for waiting member's visa
        return nil;
    }
    
    // insert as 'keys'
    [info setObject:msgKeys forKey:@"keys"];

    // OK, pack message
    return DKDSecureMessageParse(info);
}

@end

@implementation DIMInstantMessagePacker (Extended)

- (NSDictionary<NSString *, id> *)message:(id<DKDInstantMessage>)iMsg
                               encodeKeys:(NSDictionary<id<MKMID>, id<DIMEncryptedBundle>> *)bundleMap {
    id<DKDInstantMessageDelegate> transceiver = [self delegate];
    NSAssert(transceiver, @"instant message delegate not found");
    NSMutableDictionary<NSString *, id> *msgKeys = [[NSMutableDictionary alloc] init];
    [bundleMap enumerateKeysAndObjectsUsingBlock:^(id<MKMID> receiver, id<DIMEncryptedBundle> bundle, BOOL *stop) {
        NSDictionary<NSString *, id> *encoded = [transceiver message:iMsg
                                                           encodeKey:bundle
                                                         forReceiver:receiver];
        if ([encoded count] > 0) {
            // insert to 'message.keys' with ID + terminal
            [msgKeys addEntriesFromDictionary:encoded];
        } else {
            NSAssert(false, @"failed to encode key data: %@", receiver);
        }
    }];
    // TODO: put key digest
    return msgKeys;
}

@end
