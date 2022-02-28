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

#import "DIMReceiptCommand.h"
#import "DIMHandshakeCommand.h"
#import "DIMLoginCommand.h"
#import "DIMMuteCommand.h"
#import "DIMBlockCommand.h"
#import "DIMStorageCommand.h"

#import "DIMContentProcessor.h"
#import "DIMCommandProcessor.h"
#import "DIMProcessorFactory.h"

#import "DIMMessenger.h"
#import "DIMMessagePacker.h"

#import "DIMMessageProcessor.h"

@interface DIMMessageProcessor () {
    
    DIMProcessorFactory *_cpm;
}

@property (weak, nonatomic) DIMFacebook *facebook;
@property (weak, nonatomic) DIMMessenger *messenger;

@end

@implementation DIMMessageProcessor

- (instancetype)init {
    NSAssert(false, @"don't call me!");
    DIMFacebook *barrack = nil;
    DIMMessenger *transceiver = nil;
    return [self initWithFacebook:barrack messenger:transceiver];
}

/* designated initializer */
- (instancetype)initWithFacebook:(DIMFacebook *)barrack
                       messenger:(DIMMessenger *)transceiver {
    if (self = [super init]) {
        _facebook = barrack;
        _messenger = transceiver;
        _cpm = [self createProcessorFactory];
    }
    return self;
}

- (DIMProcessorFactory *)createProcessorFactory {
    return [[DIMProcessorFactory alloc] initWithFacebook:self.facebook messenger:self.messenger];
}

- (NSArray<NSData *> *)processData:(NSData *)data {
    DIMMessenger *transceiver = self.messenger;
    // 1. deserialize message
    id<DKDReliableMessage> rMsg = [transceiver deserializeMessage:data];
    if (!rMsg) {
        // no message received
        return nil;
    }
    // 2. process message
    NSArray<id<DKDReliableMessage>> *responses = [transceiver processMessage:rMsg];
    if ([responses count] == 0) {
        // nothing to response
        return nil;
    }
    // 3. serialize messages
    NSMutableArray<NSData *> *packages = [[NSMutableArray alloc] initWithCapacity:[responses count]];
    NSData * pack;
    for (id<DKDReliableMessage> res in responses) {
        pack = [transceiver serializeMessage:res];
        if ([pack length] > 0) {
            [packages addObject:pack];
        }
    }
    return packages;
}

- (NSArray<id<DKDReliableMessage>> *)processMessage:(id<DKDReliableMessage>)rMsg {
    // TODO: override to check broadcast message before calling it
    DIMMessenger *transceiver = self.messenger;
    // 1. verify message
    id<DKDSecureMessage> sMsg = [transceiver verifyMessage:rMsg];
    if (!sMsg) {
        // waiting for sender's meta if not eixsts
        return nil;
    }
    // 2. process message
    NSArray<id<DKDSecureMessage>> *responses = [transceiver processSecure:sMsg withMessage:rMsg];
    if ([responses count] == 0) {
        // nothing to respond
        return nil;
    }
    // 3. sign messages
    NSMutableArray<id<DKDReliableMessage>> *messages = [[NSMutableArray alloc] initWithCapacity:[responses count]];
    id<DKDReliableMessage> msg;
    for (id<DKDSecureMessage> res in responses) {
        msg = [transceiver signMessage:res];
        if (msg) {
            [messages addObject:msg];
        }
    }
    return messages;
    // TODO: override to deliver to the receiver when catch exception "receiver error ..."
}

- (NSArray<id<DKDSecureMessage>> *)processSecure:(id<DKDSecureMessage>)sMsg
                                     withMessage:(id<DKDReliableMessage>)rMsg {
    DIMMessenger *transceiver = self.messenger;
    // 1. decrypt message
    id<DKDInstantMessage> iMsg = [transceiver decryptMessage:sMsg];
    if (!iMsg) {
        // cannot decrypt this message, not for you?
        // delivering message to other receiver?
        return nil;
    }
    // 2. process message
    NSArray<id<DKDInstantMessage>> *responses = [transceiver processInstant:iMsg withMessage:rMsg];
    if ([responses count] == 0) {
        // nothing to respond
        return nil;
    }
    // 3. encrypt messages
    NSMutableArray<id<DKDSecureMessage>> *messages = [[NSMutableArray alloc] initWithCapacity:[responses count]];
    id<DKDSecureMessage> msg;
    for (id<DKDInstantMessage> res in responses) {
        msg = [transceiver encryptMessage:res];
        if (msg) {
            [messages addObject:msg];
        }
    }
    return messages;
}

- (NSArray<id<DKDInstantMessage>> *)processInstant:(id<DKDInstantMessage>)iMsg
                                       withMessage:(id<DKDReliableMessage>)rMsg {
    DIMMessenger *transceiver = self.messenger;
    // 1. process content
    id<DKDContent> content = iMsg.content;
    NSArray<id<DKDContent>> * responses = [transceiver processContent:content withMessage:rMsg];
    if ([responses count] == 0) {
        // nothing to respond
        return nil;
    }
    
    // 2. select a local user to build message
    id<MKMID> sender = iMsg.sender;
    id<MKMID> receiver = iMsg.receiver;
    DIMUser *user = [self.facebook selectLocalUserWithID:receiver];
    NSAssert(user, @"receiver error: %@", receiver);
    
    // 3. pack messages
    NSMutableArray<id<DKDInstantMessage>> *messages = [[NSMutableArray alloc] initWithCapacity:[responses count]];
    id<DKDEnvelope> env;
    id<DKDInstantMessage> msg;
    for (id<DKDContent> res in responses) {
        if (!res) {
            // should not happen
            continue;
        }
        env = DKDEnvelopeCreate(user.ID, sender, nil);
        msg = DKDInstantMessageCreate(env, res);
        if (msg) {
            [messages addObject:msg];
        }
    }
    return messages;
}

- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                              withMessage:(id<DKDReliableMessage>)rMsg {
    // TODO: override to check group before calling this
    DIMContentProcessor *cpu = [self processorForContent:content];
    return [cpu processContent:content withMessage:rMsg];
    // TODO: override to filter the response after called this
}

@end

@implementation DIMMessageProcessor (CPU)

- (DIMContentProcessor *)processorForContent:(id<DKDContent>)content {
    return [_cpm processorForContent:content];
}

- (DIMContentProcessor *)processorForType:(DKDContentType)type {
    return [_cpm processorForType:type];
}

- (DIMCommandProcessor *)processorForName:(NSString *)command type:(DKDContentType)type {
    return [_cpm processorForName:command type:type];
}

@end

@implementation DIMMessageProcessor (Register)

+ (void)registerAllFactories {
    
    //
    //  Register core factories
    //
    DIMRegisterContentFactories();
    DIMRegisterCommandFactories();

    //
    //  Register command factories
    //
    DIMCommandFactoryRegisterClass(DIMCommand_Receipt, DIMReceiptCommand);
    DIMCommandFactoryRegisterClass(DIMCommand_Handshake, DIMHandshakeCommand);
    DIMCommandFactoryRegisterClass(DIMCommand_Login, DIMLoginCommand);
    
    DIMCommandFactoryRegisterClass(DIMCommand_Mute, DIMMuteCommand);
    DIMCommandFactoryRegisterClass(DIMCommand_Block, DIMBlockCommand);
    
    // storage (contacts, private_key)
    DIMCommandFactoryRegisterClass(DIMCommand_Storage, DIMStorageCommand);
    DIMCommandFactoryRegisterClass(DIMCommand_Contacts, DIMStorageCommand);
    DIMCommandFactoryRegisterClass(DIMCommand_PrivateKey, DIMStorageCommand);
}

@end
