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
//  DIMClient
//
//  Created by Albert Moky on 2019/8/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMContentProcessor.h"

#import "DIMFacebook.h"
#import "DIMMessagePacker.h"
#import "DIMMessageProcessor.h"
#import "DIMMessageTransmitter.h"

#import "DIMMessenger.h"

static inline BOOL isBroadcast(id<DKDMessage> msg) {
    id<MKMID> receiver = msg.group;
    if (!receiver) {
        receiver = msg.receiver;
    }
    return MKMIDIsBroadcast(receiver);
}

@implementation DIMMessenger

#pragma mark DIMCipherKeyDelegate

- (nullable id<MKMSymmetricKey>)cipherKeyFrom:(id<MKMID>)sender
                                           to:(id<MKMID>)receiver
                                     generate:(BOOL)create {
    return [self.keyCache cipherKeyFrom:sender to:receiver generate:create];
}

- (void)cacheCipherKey:(id<MKMSymmetricKey>)key
                  from:(id<MKMID>)sender
                    to:(id<MKMID>)receiver {
    [self.keyCache cacheCipherKey:key from:sender to:receiver];
}

#pragma mark DIMPacker

- (id<MKMID>)overtGroupForContent:(id<DKDContent>)content {
    return [self.packer overtGroupForContent:content];
}

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

#pragma mark DIMProcessor

- (NSArray<NSData *> *)processData:(NSData *)data {
    return [self.processor processData:data];
}

- (NSArray<id<DKDReliableMessage>> *)processMessage:(id<DKDReliableMessage>)rMsg {
    return [self.processor processMessage:rMsg];
}

- (NSArray<id<DKDSecureMessage>> *)processSecure:(id<DKDSecureMessage>)sMsg
                                     withMessage:(id<DKDReliableMessage>)rMsg {
    return [self.processor processSecure:sMsg withMessage:rMsg];
}

- (NSArray<id<DKDInstantMessage>> *)processInstant:(id<DKDInstantMessage>)iMsg
                                       withMessage:(id<DKDReliableMessage>)rMsg {
    return [self.processor processInstant:iMsg withMessage:rMsg];
}

- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    return [self.processor processContent:content withMessage:rMsg];
}

#pragma mark DIMTransmitter

- (BOOL)sendContent:(id<DKDContent>)content
             sender:(nullable id<MKMID>)from
           receiver:(id<MKMID>)to
           callback:(nullable DIMMessengerCallback)fn
           priority:(NSInteger)prior {
    return [self.transmitter sendContent:content sender:from receiver:to callback:fn priority:prior];
}

- (BOOL)sendInstantMessage:(id<DKDInstantMessage>)iMsg
                  callback:(nullable DIMMessengerCallback)callback
                  priority:(NSInteger)prior {
    return [self.transmitter sendInstantMessage:iMsg callback:callback priority:prior];
}

- (BOOL)sendReliableMessage:(id<DKDReliableMessage>)rMsg
                   callback:(nullable DIMMessengerCallback)callback
                   priority:(NSInteger)prior {
    return [self.transmitter sendReliableMessage:rMsg callback:callback priority:prior];
}

#pragma mark DKDInstantMessageDelegate

- (id<MKMSymmetricKey>)message:(id<DKDSecureMessage>)sMsg
                       deserializeKey:(nullable NSData *)data
                                 from:(id<MKMID>)sender
                                   to:(id<MKMID>)receiver {
    if ([data length] > 0) {
        return [super message:sMsg deserializeKey:data from:sender to:receiver];
    } else {
        // get key from cache
        return [self cipherKeyFrom:sender to:receiver generate:NO];
    }
}

- (nullable id<DKDContent>)message:(id<DKDSecureMessage>)sMsg
                deserializeContent:(NSData *)data
                           withKey:(id<MKMSymmetricKey>)password {
    id<DKDContent> content = [super message:sMsg deserializeContent:data withKey:password];
    NSAssert(content, @"content error: %@", data);
    if (!isBroadcast(sMsg)) {
        // check and cache key for reuse
        id<MKMID> sender = sMsg.sender;
        id<MKMID> group = [self overtGroupForContent:content];
        if (group) {
            // group message (excludes group command)
            // cache the key with direction (sender -> group)
            [self cacheCipherKey:password from:sender to:group];
        } else {
            id<MKMID> receiver = sMsg.receiver;
            // personal message or (group) command
            // cache key with direction (sender -> receiver)
            [self cacheCipherKey:password from:sender to:receiver];
        }
    }
    // NOTICE: check attachment for File/Image/Audio/Video message content
    //         after deserialize content, this job should be do in subclass
    return content;
}

@end
