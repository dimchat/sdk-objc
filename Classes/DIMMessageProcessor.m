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
#import "DIMMessagePacker.h"

#import "DIMMessageProcessor.h"

@implementation DIMMessageProcessor

- (instancetype)initWithTransceiver:(DIMTransceiver *)transceiver {
    NSAssert(false, @"don't call me!");
    DIMMessenger *messenger = (DIMMessenger *)transceiver;
    return [self initWithMessenger:messenger];
}

/* designated initializer */
- (instancetype)initWithMessenger:(DIMMessenger *)messenger {
    if (self = [super initWithTransceiver:messenger]) {
        //
    }
    return self;
}

- (DIMMessenger *)messenger {
    return (DIMMessenger *)[self transceiver];
}

- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                              withMessage:(id<DKDReliableMessage>)rMsg {
    // NOTICE: override to check group before calling this
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
    // NOTICE: override to filter the response after called this
}

@end

@implementation DIMMessageProcessor (Register)

+ (void)registerAllFactories {
    //
    //  Register core parsers
    //
    [self registerCoreFactories];
    
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

+ (void)registerAllProcessors {
    //
    //  Register processors
    //
    [DIMContentProcessor registerAllProcessors];
    [DIMCommandProcessor registerAllProcessors];
}

@end
