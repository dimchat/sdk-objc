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

#import "NSObject+Singleton.h"

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
    [DIMContentParser registerCoreParsers];
    
    //
    //  Register command parsers
    //
    DIMCommandParserRegisterClass(DIMCommand_Receipt, DIMReceiptCommand);
    DIMCommandParserRegisterClass(DIMCommand_Handshake, DIMHandshakeCommand);
    DIMCommandParserRegisterClass(DIMCommand_Login, DIMLoginCommand);
    
    DIMCommandParserRegisterClass(DIMCommand_Mute, DIMMuteCommand);
    DIMCommandParserRegisterClass(DIMCommand_Block, DIMBlockCommand);
    
    // storage (contacts, private_key)
    DIMCommandParserRegisterClass(DIMCommand_Storage, DIMStorageCommand);
    DIMCommandParserRegisterClass(DIMCommand_Contacts, DIMStorageCommand);
    DIMCommandParserRegisterClass(DIMCommand_PrivateKey, DIMStorageCommand);
}

static inline void register_all_processors() {
    [DIMContentProcessor registerAllProcessors];
    [DIMCommandProcessor registerAllProcessors];
}

@interface DIMMessageProcessor () {
    
    DIMContentProcessor *_cpu;
}

@end

@implementation DIMMessageProcessor

- (instancetype)initWithMessenger:(DIMMessenger *)messenger {
    if (self = [super initWithMessageDelegate:messenger
                               entityDelegate:messenger.barrack
                            cipherKeyDelegate:messenger.keyCache]) {
        _cpu = [self getContentProcessor];
        
        SingletonDispatchOnce(^{
            register_all_parsers();
            register_all_processors();
        });
    }
    return self;
}

- (DIMContentProcessor *)getContentProcessor {
    return [[DIMContentProcessor alloc] initWithMessenger:self.messenger];
}

- (DIMContentProcessor *)getContentProcessorForType:(DKDContentType)type {
    return [_cpu getProcessorForType:type];
}

- (DIMContentProcessor *)getContentProcessorForContent:(id<DKDContent>)content {
    return [_cpu getProcessorForContent:content];
}

- (DIMMessenger *)messenger {
    return self.transceiver;
}

- (DIMFacebook *)facebook {
    return [[self messenger] facebook];
}

@end

@implementation DIMMessageProcessor (Transform)

- (nullable id<DKDSecureMessage>)trimMessage:(id<DKDSecureMessage>)sMsg {
    // check message delegate
    if (!sMsg.delegate) {
        sMsg.delegate = self.transceiver;
    }
    id<MKMID>receiver = sMsg.receiver;
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
    id<MKMDocument> doc = [facebook documentForID:sender type:MKMDocument_Any];
    if ([doc conformsToProtocol:@protocol(MKMVisa)]) {
        return YES;
    }
    if (!meta) {
        meta = [facebook metaForID:sender];
        if (!meta) {
            return NO;
        }
    }
    // if meta.key can be used to encrypt message,
    // then visa is not necessary
    return [meta.key conformsToProtocol:@protocol(MKMEncryptKey)];
}

- (nullable id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg {
    // Notice: check meta before calling me
    if ([self checkVisaForMessage:rMsg]) {
        return [super verifyMessage:rMsg];
    }
    // NOTICE: the application will query meta automatically
    // save this message in a queue waiting sender's meta response
    [[self messenger] suspendMessage:rMsg];
    //NSAssert(false, @"failed to get meta for sender: %@", sender);
    return nil;
}

- (nullable id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg {
    // trim message
    id<DKDSecureMessage> msg = [self trimMessage:sMsg];
    if (!msg) {
        // not for you?
        @throw [NSException exceptionWithName:@"ReceiverError" reason:@"not for you?" userInfo:sMsg.dictionary];
    }
    // decrypt message
    return [super decryptMessage:msg];
}

@end

@implementation DIMMessageProcessor (Processing)

- (nullable id<DKDInstantMessage>)processInstant:(id<DKDInstantMessage>)iMsg
                                     withMessage:(id<DKDReliableMessage>)rMsg {
    id<DKDInstantMessage> res = [super processInstant:iMsg withMessage:rMsg];
    if ([self.messenger saveMessage:iMsg]) {
        // error
        return nil;
    }
    return res;
}

- (nullable id<DKDContent>)processContent:(id<DKDContent>)content
                              withMessage:(id<DKDReliableMessage>)rMsg {
    // TODO: override to check group
    DIMContentProcessor *cpu = [self getContentProcessorForContent:content];
    if (!cpu) {
        NSAssert(false, @"failed to get CPU for content: %@", content);
        return nil;
    }
    // TODO: override to filter the response
    return [cpu processContent:content withMessage:rMsg];
}

@end
