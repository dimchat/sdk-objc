// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2019 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2019 Albert Moky
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
//  DIMMessenger.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/8/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMMessenger.h"

@implementation DIMCipherKeyDelegate

- (nullable id<MKMSymmetricKey>)cipherKeyWithSender:(id<MKMID>)from
                                           receiver:(id<MKMID>)to
                                           generate:(BOOL)create {
    NSAssert(false, @"implement me!");
    return nil;
}

- (void)cacheCipherKey:(id<MKMSymmetricKey>)key
            withSender:(id<MKMID>)from
              receiver:(id<MKMID>)to {
    NSAssert(false, @"implement me!");
}

+ (id<MKMID>)destinationOfMessage:(id<DKDMessage>)msg {
    id group = [msg objectForKey:@"group"];
    return [self destinationToReceiver:msg.receiver orGroup:MKMIDParse(group)];
}

+ (id<MKMID>)destinationToReceiver:(id<MKMID>)receiver
                           orGroup:(nullable id<MKMID>)group {
    if (!group && [receiver isGroup]) {
        /// Transform:
        ///     (B) => (J)
        ///     (D) => (G)
        group = receiver;
    }
    if (!group) {
        /// A : personal message (or hidden group message)
        /// C : broadcast message for anyone
        NSAssert([receiver isUser], @"receiver error: %@", receiver);
        return receiver;
    }
    NSAssert([group isGroup], @"group error: %@, receiver: %@", group, receiver);
    if ([group isBroadcast]) {
        /// E : unencrypted message for someone
        //      return group as broadcast ID for disable encryption
        /// F : broadcast message for anyone
        /// G : (receiver == group) broadcast group message
        NSAssert([receiver isUser] || [receiver isEqual:group], @"receiver error: %@", receiver);
        return group;
    } else if ([receiver isBroadcast]) {
        /// K : unencrypted group message, usually group command
        //      return receiver as broadcast ID for disable encryption
        NSAssert([receiver isUser], @"receiver error: %@, group: %@", receiver, group);
        return receiver;
    } else {
        /// H    : group message split for someone
        /// J    : (receiver == group) non-split group message
        return group;
    }
}

@end

@implementation DIMMessenger

- (id<DIMCipherKeyDelegate>)keyCache {
    NSAssert(false, @"implement me!");
    return nil;
}

- (id<DIMPacker>)packer {
    NSAssert(false, @"implement me!");
    return nil;
}

- (id<DIMProcessor>)processor {
    NSAssert(false, @"implement me!");
    return nil;
}

//
//  Interfaces for Packing Message
//

- (id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg {
    return [self.packer encryptMessage:iMsg];
}

- (id<DKDReliableMessage>)signMessage:(id<DKDSecureMessage>)sMsg {
    return [self.packer signMessage:sMsg];
}

- (NSData *)serializeMessage:(id<DKDReliableMessage>)rMsg {
    return [self.packer serializeMessage:rMsg];
}

- (id<DKDReliableMessage>)deserializeMessage:(NSData *)data {
    return [self.packer deserializeMessage:data];
}

- (id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg {
    return [self.packer verifyMessage:rMsg];
}

- (id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg {
    return [self.packer decryptMessage:sMsg];
}

//
//  Interfaces for Processing Message
//

- (NSArray<NSData *> *)processPackage:(NSData *)data {
    return [self.processor processPackage:data];
}

- (NSArray<id<DKDReliableMessage>> *)processReliableMessage:(id<DKDReliableMessage>)rMsg {
    return [self.processor processReliableMessage:rMsg];
}

- (NSArray<id<DKDSecureMessage>> *)processSecureMessage:(id<DKDSecureMessage>)sMsg
                             withReliableMessageMessage:(id<DKDReliableMessage>)rMsg {
    return [self.processor processSecureMessage:sMsg withReliableMessageMessage:rMsg];
}

- (NSArray<id<DKDInstantMessage>> *)processInstantMessage:(id<DKDInstantMessage>)iMsg
                               withReliableMessageMessage:(id<DKDReliableMessage>)rMsg {
    return [self.processor processInstantMessage:iMsg withReliableMessageMessage:rMsg];
}

- (NSArray<id<DKDContent>> *)processContent:(__kindof id<DKDContent>)content
                 withReliableMessageMessage:(id<DKDReliableMessage>)rMsg {
    return [self.processor processContent:content withReliableMessageMessage:rMsg];
}

#pragma mark DKDInstantMessageDelegate

- (id<MKMSymmetricKey>)message:(id<DKDSecureMessage>)sMsg
                deserializeKey:(NSData *)data {
    if ([data length] == 0) {
        // get key from cache with direction: sender -> receiver(group)
        return [self decryptKeyForMessage:sMsg];
    } else {
        return [super message:sMsg deserializeKey:data];
    }
}

- (nullable id<DKDContent>)message:(id<DKDSecureMessage>)sMsg
                deserializeContent:(NSData *)data
                           withKey:(id<MKMSymmetricKey>)password {
    id<DKDContent> content = [super message:sMsg deserializeContent:data withKey:password];
    
    // cache decrypt key when success
    if (!content) {
        NSAssert(false, @"content error: %lu byte(s)", [data length]);
    } else {
        // cache the key with direction: sender -> receiver(group)
        [self cacheDecryptKey:password forMessage:sMsg];
    }
    
    // NOTICE: check attachment for File/Image/Audio/Video message content
    //         after deserialize content, this job should be do in subclass
    return content;
}

@end

@implementation DIMMessenger (CipherKey)

//
//  Interfaces for Cipher Key
//

- (nullable id<MKMSymmetricKey>)encryptKeyForMessage:(id<DKDInstantMessage>)iMsg {
    id<MKMID> sender = [iMsg sender];
    id<MKMID> target = [DIMCipherKeyDelegate destinationOfMessage:iMsg];
    return [self.keyCache cipherKeyWithSender:sender receiver:target generate:YES];
}

- (nullable id<MKMSymmetricKey>)decryptKeyForMessage:(id<DKDSecureMessage>)sMsg {
    id<MKMID> sender = [sMsg sender];
    id<MKMID> target = [DIMCipherKeyDelegate destinationOfMessage:sMsg];
    return [self.keyCache cipherKeyWithSender:sender receiver:target generate:NO];
}

- (void)cacheDecryptKey:(id<MKMSymmetricKey>)password forMessage:(id<DKDSecureMessage>)sMsg {
    id<MKMID> sender = [sMsg sender];
    id<MKMID> target = [DIMCipherKeyDelegate destinationOfMessage:sMsg];
    [self.keyCache cacheCipherKey:password withSender:sender receiver:target];
}

@end
