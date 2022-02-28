// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2021 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2021 Albert Moky
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
//  DIMProcessorFactory.m
//  DIMSDK
//
//  Created by Albert Moky on 2021/11/22.
//  Copyright © 2021 Albert Moky. All rights reserved.
//

#import "DIMForwardContentProcessor.h"

#import "DIMMetaCommandProcessor.h"
#import "DIMDocumentCommandProcessor.h"

#import "DIMGroupCommandProcessor.h"
#import "DIMInviteCommandProcessor.h"
#import "DIMExpelCommandProcessor.h"
#import "DIMQuitCommandProcessor.h"
#import "DIMQueryCommandProcessor.h"
#import "DIMResetCommandProcessor.h"

#import "DIMProcessorFactory.h"

#define CREATE_CPU(clazz)                                                      \
            [[clazz alloc] initWithFacebook:self.facebook                      \
                                  messenger:self.messenger]                    \
                                                   /* EOF 'CREATE_CPU(clazz)' */

@interface DIMProcessorFactory () {
    
    NSMutableDictionary<NSNumber *, DIMContentProcessor *> *_contentProcessors;
    NSMutableDictionary<NSString *, DIMCommandProcessor *> *_commandProcessors;
}

@property (weak, nonatomic) DIMFacebook *facebook;
@property (weak, nonatomic) DIMMessenger *messenger;

@end

@implementation DIMProcessorFactory

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
        _contentProcessors = [[NSMutableDictionary alloc] init];
        _commandProcessors = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (nullable DIMContentProcessor *)processorForContent:(id<DKDContent>)content {
    DKDContentType type = content.type;
    if ([content conformsToProtocol:@protocol(DIMCommand)]) {
        id<DIMCommand> cmd = (id<DIMCommand>)content;
        NSString *name = cmd.command;
        return [self processorForType:type command:name];
    } else {
        return [self processorForType:type];
    }
}

- (nullable DIMContentProcessor *)processorForType:(DKDContentType)type {
    DIMContentProcessor *cpu = [_contentProcessors objectForKey:@(type)];
    if (!cpu) {
        cpu = [self createProcessorWithType:type];
        if (cpu) {
            [_contentProcessors setObject:cpu forKey:@(type)];
        }
    }
    return cpu;
}

- (nullable DIMCommandProcessor *)processorForType:(DKDContentType)type command:(NSString *)name {
    DIMCommandProcessor *cpu = [_commandProcessors objectForKey:name];
    if (!cpu) {
        cpu = [self createProcessorWithType:type command:name];
        if (cpu) {
            [_commandProcessors setObject:cpu forKey:name];
        }
    }
    return cpu;
}

- (DIMContentProcessor *)createProcessorWithType:(DKDContentType)type {
    // core contents
    if (type == DKDContentType_Forward) {
        return CREATE_CPU(DIMForwardContentProcessor);
    }
    // unknown
    return nil;
}

- (DIMCommandProcessor *)createProcessorWithType:(DKDContentType)type command:(NSString *)name {
    // meta
    if ([name isEqualToString:DIMCommand_Meta]) {
        return CREATE_CPU(DIMMetaCommandProcessor);
    }
    // document
    if ([name isEqualToString:DIMCommand_Document]) {
        return CREATE_CPU(DIMDocumentCommandProcessor);
    } else if ([name isEqualToString:@"profile"] || [name isEqualToString:@"visa"] || [name isEqualToString:@"bulletin"]) {
        DIMCommandProcessor *cpu = [_commandProcessors objectForKey:DIMCommand_Document];
        if (!cpu) {
            cpu = CREATE_CPU(DIMDocumentCommandProcessor);
            [_commandProcessors setObject:cpu forKey:DIMCommand_Document];
        }
        return cpu;
    }
    // group
    if ([name isEqualToString:@"group"]) {
        return CREATE_CPU(DIMGroupCommandProcessor);
    } else if ([name isEqualToString:DIMGroupCommand_Invite]) {
        return CREATE_CPU(DIMInviteCommandProcessor);
    } else if ([name isEqualToString:DIMGroupCommand_Expel]) {
        return CREATE_CPU(DIMExpelCommandProcessor);
    } else if ([name isEqualToString:DIMGroupCommand_Quit]) {
        return CREATE_CPU(DIMQuitCommandProcessor);
    } else if ([name isEqualToString:DIMGroupCommand_Query]) {
        return CREATE_CPU(DIMQueryGroupCommandProcessor);
    } else if ([name isEqualToString:DIMGroupCommand_Reset]) {
        return CREATE_CPU(DIMResetGroupCommandProcessor);
    }
    // others
    if (type == DKDContentType_Command) {
        return CREATE_CPU(DIMCommandProcessor);
    }
    if (type == DKDContentType_History) {
        return CREATE_CPU(DIMHistoryCommandProcessor);
    }
    // unknown
    return nil;
}

@end
