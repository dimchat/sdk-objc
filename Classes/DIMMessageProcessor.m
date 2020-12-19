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

#import "DIMMessenger.h"
#import "DIMFacebook.h"

#import "DIMMessageProcessor.h"

static inline void register_all_parsers() {
    //
    //  Register core parsers
    //
    [DIMContentFactory registerCoreFactories];
    
    //
    //  Register command parsers
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

static inline void register_all_processors() {
    [DIMContentProcessor registerAllProcessors];
    [DIMCommandProcessor registerAllProcessors];
}

@implementation DIMMessageProcessor

- (instancetype)initWithFacebook:(DIMFacebook *)barrack
                       messenger:(DIMMessenger *)transceiver
                          packer:(DIMPacker *)messagePacker {
    if (self = [super initWithEntityDelegate:barrack
                             messageDelegate:transceiver
                                      packer:messagePacker]) {
        // register
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            register_all_parsers();
            register_all_processors();
        });
    }
    return self;
}

- (DIMMessenger *)messenger {
    return (DIMMessenger *)[self transceiver];
}

- (DIMFacebook *)facebook {
    return [self.messenger facebook];
}

// [VISA Protocol]
- (BOOL)checkVisaForMessage:(id<DKDReliableMessage>)rMsg {
    // check message delegate
    if (!rMsg.delegate) {
        rMsg.delegate = self.transceiver;
    }
    DIMFacebook *facebook = self.facebook;
    id<MKMID> sender = rMsg.sender;
    // check meta
    id<MKMMeta> meta = rMsg.meta;
    if (meta) {
        // [Meta Protocol]
        // save meta for sender
        if (![facebook saveMeta:meta forID:sender]) {
            return NO;
        }
    }
    // check visa
    id<MKMVisa> visa = rMsg.visa;
    if (visa) {
        // [Visa Protocol]
        // save visa for sender
        return [facebook saveDocument:visa];
    }
    // check local storage
    id<MKMDocument> doc = [facebook documentForID:sender type:MKMDocument_Visa];
    if ([doc conformsToProtocol:@protocol(MKMVisa)]) {
        if ([(id<MKMVisa>)doc key]) {
            // visa.key exists
            return YES;
        }
    }
    if (!meta) {
        meta = [facebook metaForID:sender];
        if (!meta) {
            return NO;
        }
    }
    // if meta.key can be used to encrypt message,
    // then visa.key is not necessary
    return [meta.key conformsToProtocol:@protocol(MKMEncryptKey)];
}

- (nullable id<DKDSecureMessage>)trimMessage:(id<DKDSecureMessage>)sMsg {
    // check message delegate
    if (!sMsg.delegate) {
        sMsg.delegate = self.transceiver;
    }
    id<MKMID> receiver = sMsg.receiver;
    MKMUser *user = [[self facebook] selectLocalUserWithID:receiver];
    if (!user) {
        // local users not matched
        sMsg = nil;
    } else if (MKMIDIsGroup(receiver)) {
        // trim group message
        sMsg = [sMsg trimForMember:user.ID];
    }
    return sMsg;
}

- (nullable id<DKDReliableMessage>)processMessage:(id<DKDReliableMessage>)rMsg {
    if ([self checkVisaForMessage:rMsg]) {
        // visa key found
        return [super processMessage:rMsg];
    }
    // NOTICE: the application will query meta automatically
    // save this message in a queue waiting sender's meta response
    [self.messenger suspendMessage:rMsg];
    return nil;
}

- (nullable id<DKDSecureMessage>)processSecure:(id<DKDSecureMessage>)sMsg
                                   withMessage:(id<DKDReliableMessage>)rMsg {
    // try to trim message
    if (![self trimMessage:sMsg]) {
        // not for you?
        @throw [NSException exceptionWithName:@"ReceiverError" reason:@"not for you?" userInfo:sMsg.dictionary];
    }
    return [super processSecure:sMsg withMessage:rMsg];
}

- (nullable id<DKDInstantMessage>)processInstant:(id<DKDInstantMessage>)iMsg
                                     withMessage:(id<DKDReliableMessage>)rMsg {
    id<DKDInstantMessage> res = [super processInstant:iMsg withMessage:rMsg];
    if ([self.messenger saveMessage:iMsg]) {
        return res;
    }
    // error
    return nil;
}

- (nullable id<DKDContent>)processContent:(id<DKDContent>)content
                              withMessage:(id<DKDReliableMessage>)rMsg {
    // TODO: override to check group
    DIMContentProcessor *cpu = [DIMContentProcessor getProcessorForContent:content];
    if (!cpu) {
        cpu = [DIMContentProcessor getProcessorForType:0];  // unknown
        if (!cpu) {
            NSAssert(false, @"cannot process content: %@", content);
            return nil;
        }
    }
    cpu.messenger = self.messenger;
    return [cpu processContent:content withMessage:rMsg];
    // TODO: override to filter the response
}

@end
