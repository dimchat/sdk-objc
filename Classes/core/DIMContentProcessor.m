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
//  DIMContentProcessor.h
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2022 Albert Moky. All rights reserved.
//

#import "DIMContentProcessor.h"

@interface DIMContentProcessorFactory () {
    
    id<DIMContentProcessorCreator> _creator;
    
    NSMutableDictionary<NSNumber *, id<DIMContentProcessor>> *_contentProcessors;
    NSMutableDictionary<NSString *, id<DIMContentProcessor>> *_commandProcessors;
}

@end

@implementation DIMContentProcessorFactory

- (instancetype)initWithFacebook:(DIMBarrack *)barrack
                       messenger:(DIMTransceiver *)transceiver {
    NSAssert(false, @"don't call me!");
    id<DIMContentProcessorCreator> cpc = nil;
    return [self initWithFacebook:barrack messenger:transceiver creator:cpc];
}

/* designated initializer */
- (instancetype)initWithFacebook:(DIMBarrack *)barrack
                       messenger:(DIMTransceiver *)transceiver
                         creator:(id<DIMContentProcessorCreator>)cpc {
    if (self = [super initWithFacebook:barrack messenger:transceiver]) {
        _creator = cpc;
        _contentProcessors = [[NSMutableDictionary alloc] init];
        _commandProcessors = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id<DIMContentProcessor>)getProcessor:(__kindof id<DKDContent>)content {
    id<DIMContentProcessor> cpu;
    DKDContentType msgType = content.type;
    if ([content conformsToProtocol:@protocol(DKDCommand)]) {
        NSString *cmd = [content cmd];
        //NSAssert([cmd length] > 0, @"command name error: %@", cmd);
        cpu = [self getCommandProcessor:cmd type:msgType];
        if (cpu) {
            return cpu;
        } else if ([content conformsToProtocol:@protocol(DKDGroupCommand)]
                   /*|| [content objectForKey:@"group"]*/) {
            //NSAssert(![cmd isEqualToString:@"group"], @"command name error: %@", content);
            cpu = [self getCommandProcessor:@"group" type:msgType];
            if (cpu) {
                return cpu;
            }
        }
    }
    // content processor
    return [self getContentProcessor:msgType];
}

- (id<DIMContentProcessor>)getContentProcessor:(DKDContentType)msgType {
    id<DIMContentProcessor> cpu = [_contentProcessors objectForKey:@(msgType)];
    if (!cpu) {
        cpu = [_creator createContentProcessor:msgType];
        if (cpu) {
            [_contentProcessors setObject:cpu forKey:@(msgType)];
        }
    }
    return cpu;
}

- (id<DIMContentProcessor>)getCommandProcessor:(NSString *)name
                                          type:(DKDContentType)msgType {
    id<DIMContentProcessor> cpu = [_commandProcessors objectForKey:name];
    if (!cpu) {
        cpu = [_creator createCommandProcessor:name type:msgType];
        if (cpu) {
            [_commandProcessors setObject:cpu forKey:name];
        }
    }
    return cpu;
}

@end
