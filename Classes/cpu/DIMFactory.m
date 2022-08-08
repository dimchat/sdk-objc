// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2022 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2022 Albert Moky
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
//  DIMContentProcessor.h
//  DIMSDK
//
//  Created by Albert Moky on 2022/04/10.
//  Copyright © 2022 Albert Moky. All rights reserved.
//

#import "DIMForwardContentProcessor.h"
#import "DIMArrayContentProcessor.h"
//#import "DIMCustomizedContentProcessor.h"

#import "DIMMetaCommandProcessor.h"
#import "DIMDocumentCommandProcessor.h"

#import "DIMGroupCommandProcessor.h"
#import "DIMInviteCommandProcessor.h"
#import "DIMExpelCommandProcessor.h"
#import "DIMQuitCommandProcessor.h"
#import "DIMQueryCommandProcessor.h"
#import "DIMResetCommandProcessor.h"

#import "DIMFactory.h"

#define CREATE_CPU(clazz)                                                      \
            [[clazz alloc] initWithFacebook:self.facebook                      \
                                  messenger:self.messenger]                    \
                                                   /* EOF 'CREATE_CPU(clazz)' */

@implementation DIMContentProcessorCreator

- (nonnull id<DIMContentProcessor>)createContentProcessor:(DKDContentType)type {
    // forward content
    if (type == DKDContentType_Forward) {
        return CREATE_CPU(DIMForwardContentProcessor);
    }
    // array content
    if (type == DKDContentType_Array) {
        return CREATE_CPU(DIMArrayContentProcessor);
    }
    /*
    // application customized
    if (type == DKDContentType_Application) {
        return CREATE_CPU(DIMCustomizedContentProcessor);
    } else if (type == DKDContentType_Customized) {
        return CREATE_CPU(DIMCustomizedContentProcessor);
    }
     */
    // default commands
    if (type == DKDContentType_Command) {
        return CREATE_CPU(DIMCommandProcessor);
    } else if (type == DKDContentType_History) {
        return CREATE_CPU(DIMHistoryCommandProcessor);
    }
    /*
    // default contents
    if (type == 0) {
        // must return a default processor for type==0
        return CREATE_CPU(DIMContentProcessor);
    }
     */
    // unknown
    return nil;
}

- (nonnull id<DIMContentProcessor>)createCommandProcessor:(nonnull NSString *)name type:(DKDContentType)msgType { 
    // meta command
    if ([name isEqualToString:DIMCommand_Meta]) {
        return CREATE_CPU(DIMMetaCommandProcessor);
    }
    // document command
    if ([name isEqualToString:DIMCommand_Document]) {
        return CREATE_CPU(DIMDocumentCommandProcessor);
    }
    // group commands
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
    // unknown
    return nil;
}

@end

#pragma mark -

@interface DIMContentProcessorFactory () {
    
    NSMutableDictionary<NSNumber *, id<DIMContentProcessor>> *_contentProcessors;
    NSMutableDictionary<NSString *, id<DIMContentProcessor>> *_commandProcessors;
}

@end

@implementation DIMContentProcessorFactory

- (instancetype)initWithFacebook:(DIMFacebook *)barrack
                       messenger:(DIMMessenger *)transceiver {
    if (self = [super initWithFacebook:barrack messenger:transceiver]) {
        _contentProcessors = [[NSMutableDictionary alloc] init];
        _commandProcessors = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id<DIMContentProcessor>)getProcessor:(id<DKDContent>)content {
    id<DIMContentProcessor> cpu;
    DKDContentType msgType = content.type;
    if ([content conformsToProtocol:@protocol(DIMCommand)]) {
        id<DIMCommand> command = (id<DIMCommand>)content;
        NSString *cmd = command.cmd;
        // command processor
        cpu = [self getCommandProcessor:cmd type:msgType];
        if (cpu) {
            return cpu;
        } else if ([content isKindOfClass:[DIMGroupCommand class]]) {
            // group command processor
            cpu = [self getCommandProcessor:@"group" type:msgType];
            if (cpu) {
                return cpu;
            }
        }
    }
    // content processor
    cpu = [self getContentProcessor:msgType];
    if (!cpu) {
        // default content processor
        cpu = [self getContentProcessor:0];
    }
    return cpu;
}

- (id<DIMContentProcessor>)getContentProcessor:(DKDContentType)msgType {
    id<DIMContentProcessor> cpu = [_contentProcessors objectForKey:@(msgType)];
    if (!cpu) {
        cpu = [self.creator createContentProcessor:msgType];
        if (cpu) {
            [_contentProcessors setObject:cpu forKey:@(msgType)];
        }
    }
    return cpu;
}

- (id<DIMContentProcessor>)getCommandProcessor:(NSString *)name type:(DKDContentType)msgType {
    id<DIMContentProcessor> cpu = [_commandProcessors objectForKey:name];
    if (!cpu) {
        cpu = [self.creator createCommandProcessor:name type:msgType];
        if (cpu) {
            [_commandProcessors setObject:cpu forKey:name];
        }
    }
    return cpu;
}

@end
