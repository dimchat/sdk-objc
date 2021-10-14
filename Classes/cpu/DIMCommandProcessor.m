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
//  DIMCommandProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 Albert Moky. All rights reserved.
//

#import "DIMMessenger.h"

#import "DIMMetaCommandProcessor.h"
#import "DIMDocumentCommandProcessor.h"
#import "DIMGroupCommandProcessor.h"
#import "DIMInviteCommandProcessor.h"
#import "DIMExpelCommandProcessor.h"
#import "DIMQuitCommandProcessor.h"
#import "DIMQueryCommandProcessor.h"
#import "DIMResetCommandProcessor.h"

#import "DIMCommandProcessor.h"

@implementation DIMCommandProcessor

- (NSArray<id<DKDContent>> *)executeCommand:(DIMCommand *)cmd
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSString *text = [NSString stringWithFormat:@"Command (name: %@) not support yet!", cmd.command];
    return [self respondText:text withGroup:cmd.group];
}

//
//  Main
//
- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content isKindOfClass:[DIMCommand class]], @"command error: %@", content);
    DIMCommand *cmd = (DIMCommand *)content;
    DIMCommandProcessor *cpu = [self getProcessorForCommand:cmd];
    if (!cpu) {
        if ([cmd isKindOfClass:[DIMGroupCommand class]]) {
            cpu = [self getProcessorForName:@"group"];
        }
    }
    if (cpu) {
        cpu.messenger = self.messenger;
    } else {
        cpu = self;
    }
    return [cpu executeCommand:cmd withMessage:rMsg];
}

@end

@implementation DIMCommandProcessor (CPU)

static NSMutableDictionary<NSString *, DIMCommandProcessor *> *s_processors = nil;

+ (void)registerProcessor:(DIMCommandProcessor *)processor
               forCommand:(NSString *)name {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!s_processors) {
            s_processors = [[NSMutableDictionary alloc] init];
        }
    });
    [s_processors setObject:processor forKey:name];
}

- (nullable __kindof DIMCommandProcessor *)getProcessorForCommand:(DIMCommand *)cmd {
    return [self getProcessorForName:cmd.command];
}

- (nullable __kindof DIMCommandProcessor *)getProcessorForName:(NSString *)name {
    return [s_processors objectForKey:name];
}

@end

@implementation DIMCommandProcessor (Register)

+ (void)registerCommandProcessors {
    // meta
    DIMCommandProcessorRegisterClass(DIMCommand_Meta, DIMMetaCommandProcessor);
    // document
    DIMDocumentCommandProcessor *docProcessor = [[DIMDocumentCommandProcessor alloc] init];
    DIMCommandProcessorRegister(DIMCommand_Document, docProcessor);
    DIMCommandProcessorRegister(@"profile", docProcessor);
    DIMCommandProcessorRegister(@"visa", docProcessor);
    DIMCommandProcessorRegister(@"bulletin", docProcessor);
    // group
    DIMCommandProcessorRegisterClass(@"group", DIMGroupCommandProcessor);
    DIMCommandProcessorRegisterClass(DIMGroupCommand_Invite, DIMInviteCommandProcessor);
    DIMCommandProcessorRegisterClass(DIMGroupCommand_Expel, DIMExpelCommandProcessor);
    DIMCommandProcessorRegisterClass(DIMGroupCommand_Quit, DIMQuitCommandProcessor);
    DIMCommandProcessorRegisterClass(DIMGroupCommand_Query, DIMQueryGroupCommandProcessor);
    DIMCommandProcessorRegisterClass(DIMGroupCommand_Reset, DIMResetGroupCommandProcessor);
}

@end
