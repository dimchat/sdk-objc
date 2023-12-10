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

@interface DIMInstantMessage () {
    
    id<DKDContent> _content;
}

@end

@implementation DIMInstantMessage

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
        // lazy
        _content = nil;
    }
    return self;
}

/* designated initializer */
- (instancetype)initWithEnvelope:(id<DKDEnvelope>)env
                         content:(id<DKDContent>)content {
    NSAssert(content, @"content cannot be empty");
    NSAssert(env, @"envelope cannot be empty");
    
    if (self = [super initWithEnvelope:env]) {
        // content
        [self setDictionary:content forKey:@"content"];
        _content = content;
    }
    return self;
}

- (instancetype)initWithEnvelope:(id<DKDEnvelope>)env {
    NSAssert(false, @"DON'T call me");
    id content = nil;
    return [self initWithEnvelope:env content:content];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    DIMInstantMessage *iMsg = [super copyWithZone:zone];
    if (iMsg) {
        iMsg.innerContent = _content;
    }
    return iMsg;
}

- (id<DKDContent>)content {
    if (!_content) {
        id dict = [self objectForKey:@"content"];
        _content = DKDContentParse(dict);
    }
    return _content;
}
- (void)setContent:(id<DKDContent>)content {
    [self setDictionary:content forKey:@"content"];
    _content = content;
}
- (void)setInnerContent:(id<DKDContent>)content {
    _content = content;
}

- (NSDate *)time {
    NSDate *when = [self.content time];
    if (when) {
        return when;
    }
    return [super time];
}

- (id<MKMID>)group {
    return [self.content group];
}

- (DKDContentType)type {
    return [self.content type];
}

- (NSMutableDictionary *)_prepare:(id<MKMSymmetricKey>)PW
                         delegate:(id<DKDInstantMessageDelegate>)transceiver {
    // 1. serialize message content
    NSData *data = [transceiver message:self serializeContent:self.content withKey:PW];
    
    // 2. encrypt content data with password
    data = [transceiver message:self encryptContent:data withKey:PW];
    NSAssert(data, @"failed to encrypt content with key: %@", PW);
    
    // 3. encode encrypted data
    NSObject *base64 = [transceiver message:self encodeData:data];
    NSAssert(base64, @"failed to encode data: %@", data);
    
    // 4. replace 'content' with encrypted 'data'
    NSMutableDictionary *msg = [self dictionary:NO];
    [msg removeObjectForKey:@"content"];
    [msg setObject:base64 forKey:@"data"];
    return msg;
}

- (nullable id<DKDSecureMessage>)encryptWithKey:(id<MKMSymmetricKey>)password {
    id<DKDInstantMessageDelegate> transceiver;
    transceiver = (id<DKDInstantMessageDelegate>)[self delegate];
    NSAssert(transceiver, @"message delegate not set yet");
    // 0. check attachment for File/Image/Audio/Video message content
    //    (do it in application level)

    // 1. encrypt 'message.content' to 'message.data'
    NSMutableDictionary *msg = [self _prepare:password delegate:transceiver];
    
    // 2. encrypt symmetric key(password) to 'message.key'
    // 2.1. serialize symmetric key
    NSData *pwd = [transceiver message:self serializeKey:password];
    if (!pwd) {
        // A) broadcast message has no key
        // B) reused key
        return DKDSecureMessageParse(msg);
    }
    id<MKMID> receiver = self.receiver;

    // 2.2. encrypt symmetric key data
    NSData *key = [transceiver message:self encryptKey:pwd forReceiver:receiver];
    if (!key) {
        // public key for encryption not found
        // TODO: suspend this message for waiting receiver's visa
        return nil;
    }
    
    // 2.3. encode encrypted key data
    NSObject *b64 = [transceiver message:self encodeKey:key];
    NSAssert(b64, @"failed to encode key data: %lu byte(s)", key.length);
    // 2.4. insert as 'key'
    [msg setObject:b64 forKey:@"key"];

    // 3. pack message
    return DKDSecureMessageParse(msg);
}

- (nullable id<DKDSecureMessage>)encryptWithKey:(id<MKMSymmetricKey>)password
                                     forMembers:(NSArray<id<MKMID>> *)members {
    id<DKDInstantMessageDelegate> transceiver;
    transceiver = (id<DKDInstantMessageDelegate>)[self delegate];
    NSAssert(transceiver, @"message delegate not set yet");
    // 0. check attachment for File/Image/Audio/Video message content
    //    (do it in application level)

    // 1. encrypt 'message.content' to 'message.data'
    NSMutableDictionary *msg = [self _prepare:password delegate:transceiver];
    
    // 2. encrypt symmetric key(password) to 'message.keys'
    // 2.1. serialize symmetric key
    NSData *pwd = [transceiver message:self serializeKey:password];
    if (!pwd) {
        // A) broadcast message has no key
        // B) reused key
        return DKDSecureMessageParse(msg);
    }
    // keys map
    NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:members.count];
    NSData *key;
    NSObject *b64;
    
    for (id<MKMID> ID in members) {
        // 2.2. encrypt symmetric key data
        key = [transceiver message:self encryptKey:pwd forReceiver:ID];
        if (!key) {
            // public key for member not found
            // TODO: suspend this message for waiting member's visa
            continue;
        }
        // 2.3. encode encrypted key data
        b64 = [transceiver message:self encodeKey:key];
        NSAssert(b64, @"failed to encode key data: %lu byte(s)", key.length);
        // 2.4. insert to 'message.keys' with member ID
        [map setObject:b64 forKey:[ID string]];
    }
    if (map.count == 0) {
        // public key for member(s) not found
        // TODO: suspend this message for waiting member's visa
        return nil;
    }
    [msg setObject:map forKey:@"keys"];

    // 3. pack message
    return DKDSecureMessageParse(msg);
}

@end

@implementation DIMInstantMessagePacker

@end
