// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2020 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2020 Albert Moky
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
//  DIMMessageProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/8.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "DIMContentProcessorCreator.h"
#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMMessageProcessor.h"

@interface DIMMessageProcessor ()

@property (strong, nonatomic) id<DIMContentProcessorFactory> factory;

@end

@implementation DIMMessageProcessor

/* designated initializer */
- (instancetype)initWithFacebook:(DIMFacebook *)facebook
                       messenger:(DIMMessenger *)transceiver {
    if (self = [super initWithFacebook:facebook messenger:transceiver]) {
        self.factory = [self createFactoryWithFacebook:facebook
                                             messenger:transceiver];
    }
    return self;
}

- (id<DIMContentProcessorFactory>)createFactoryWithFacebook:(DIMFacebook *)facebook
                                                  messenger:(DIMMessenger *)transceiver {
    NSAssert(false, @"implement me!");
    return nil;
}

//
//  Processing Message
//

// Override
- (NSArray<NSData *> *)processPackage:(NSData *)data {
    DIMMessenger *transceiver = [self messenger];
    NSAssert(transceiver, @"messenger not ready");
    // 1. deserialize message
    id<DKDReliableMessage> rMsg = [transceiver deserializeMessage:data];
    if (!rMsg) {
        // no valid message received
        return nil;
    }
    // 2. process message
    NSArray<id<DKDReliableMessage>> *responses = [transceiver processReliableMessage:rMsg];
    if ([responses count] == 0) {
        // nothing to response
        return nil;
    }
    // 3. serialize messages
    NSMutableArray *packages = [[NSMutableArray alloc] initWithCapacity:responses.count];
    NSData * pack;
    for (id<DKDReliableMessage> res in responses) {
        pack = [transceiver serializeMessage:res];
        if ([pack length] == 0) {
            // should not happen
            continue;
        }
        [packages addObject:pack];
    }
    return packages;
}

// Override
- (NSArray<id<DKDReliableMessage>> *)processReliableMessage:(id<DKDReliableMessage>)rMsg {
    // TODO: override to check broadcast message before calling it
    DIMMessenger *transceiver = [self messenger];
    NSAssert(transceiver, @"messenger not ready");
    // 1. verify message
    id<DKDSecureMessage> sMsg = [transceiver verifyMessage:rMsg];
    if (!sMsg) {
        // TODO: suspend and waiting for sender's meta if not exists
        return nil;
    }
    // 2. process message
    NSArray<id<DKDSecureMessage>> *responses = [transceiver processSecureMessage:sMsg
                                                      withReliableMessageMessage:rMsg];
    if ([responses count] == 0) {
        // nothing to respond
        return nil;
    }
    // 3. sign messages
    NSMutableArray *messages = [[NSMutableArray alloc] initWithCapacity:responses.count];
    id<DKDReliableMessage> msg;
    for (id<DKDSecureMessage> res in responses) {
        msg = [transceiver signMessage:res];
        if (!msg) {
            // should not happen
            continue;
        }
        [messages addObject:msg];
    }
    return messages;
}

// Override
- (NSArray<id<DKDSecureMessage>> *)processSecureMessage:(id<DKDSecureMessage>)sMsg
                             withReliableMessageMessage:(id<DKDReliableMessage>)rMsg {
    DIMMessenger *transceiver = [self messenger];
    NSAssert(transceiver, @"messenger not ready");
    // 1. decrypt message
    id<DKDInstantMessage> iMsg = [transceiver decryptMessage:sMsg];
    if (!iMsg) {
        // cannot decrypt this message, not for you?
        // delivering message to other receiver?
        return nil;
    }
    // 2. process message
    NSArray<id<DKDInstantMessage>> *responses = [transceiver processInstantMessage:iMsg
                                                        withReliableMessageMessage:rMsg];
    if ([responses count] == 0) {
        // nothing to respond
        return nil;
    }
    // 3. encrypt messages
    NSMutableArray<id<DKDSecureMessage>> *messages = [[NSMutableArray alloc] initWithCapacity:[responses count]];
    id<DKDSecureMessage> msg;
    for (id<DKDInstantMessage> res in responses) {
        msg = [transceiver encryptMessage:res];
        if (!msg) {
            // should not happen
            continue;
        }
        [messages addObject:msg];
    }
    return messages;
}

// Override
- (NSArray<id<DKDInstantMessage>> *)processInstantMessage:(id<DKDInstantMessage>)iMsg
                               withReliableMessageMessage:(id<DKDReliableMessage>)rMsg {
    DIMFacebook *facebook = [self facebook];
    DIMMessenger *transceiver = [self messenger];
    NSAssert(facebook && transceiver, @"twins not ready");
    // 1. process content
    NSArray<id<DKDContent>> * responses = [transceiver processContent:iMsg.content
                                           withReliableMessageMessage:rMsg];
    if ([responses count] == 0) {
        // nothing to respond
        return nil;
    }
    
    // 2. select a local user to build message
    id<MKMID> sender = iMsg.sender;
    id<MKMID> receiver = iMsg.receiver;
    id<MKMID> me = [facebook selectLocalUser:receiver];
    if (!me) {
        NSAssert(false, @"receiver error: %@", receiver);
        return nil;
    }
    
    // 3. pack messages
    NSMutableArray<id<DKDInstantMessage>> *messages = [[NSMutableArray alloc] initWithCapacity:[responses count]];
    id<DKDEnvelope> env;
    id<DKDInstantMessage> msg;
    for (id<DKDContent> res in responses) {
        if (!res) {
            // should not happen
            continue;
        }
        env = DKDEnvelopeCreate(me, sender, nil);
        msg = DKDInstantMessageCreate(env, res);
        if (!msg) {
            // should not happen
            continue;
        }
        [messages addObject:msg];
    }
    return messages;
}

// Override
- (NSArray<id<DKDContent>> *)processContent:(__kindof id<DKDContent>)content
                 withReliableMessageMessage:(id<DKDReliableMessage>)rMsg {
    // TODO: override to check group before calling this
    id<DIMContentProcessorFactory> factory = [self factory];
    id<DIMContentProcessor> cpu = [factory getContentProcessor:content];
    if (!cpu) {
        // default content processor
        cpu = [factory getContentProcessorForType:DKDContentType_Any];
        NSAssert(cpu, @"failed to get default CPU");
    }
    return [cpu processContent:content withMessage:rMsg];
    // TODO: override to filter the response after called this
}

@end
