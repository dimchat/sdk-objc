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
//  DIMGroupCommandProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 Albert Moky. All rights reserved.
//

#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMGroupCommandProcessor.h"

@interface DIMCommandProcessor (Hacking)

- (DIMCommandProcessor *)processorForCommand:(NSString *)name;

@end

@implementation DIMGroupCommandProcessor

- (instancetype)initWithMessenger:(DIMMessenger *)messenger {
    if (self = [super initWithMessenger:messenger]) {
    }
    return self;
}

- (nullable NSArray<id<MKMID>> *)membersFromCommand:(DIMGroupCommand *)cmd {
    NSArray<id<MKMID>> *members = [cmd members];
    if (members.count > 0) {
        return members;
    }
    id<MKMID> member = [cmd member];
    if (member) {
        return @[member];
    }
    return nil;
}

- (BOOL)containsOwnerInMembers:(NSArray<id<MKMID>> *)members group:(id<MKMID>)group {
    for (id<MKMID>item in members) {
        if ([self.facebook group:group isOwner:item]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isEmpty:(id<MKMID>)group {
    NSArray *members = [self.facebook membersOfGroup:group];
    if ([members count] == 0) {
        return YES;
    }
    id<MKMID>owner = [self.facebook ownerOfGroup:group];
    return !owner;
}


//
//  Main
//
- (nullable id<DKDContent>)processContent:(id<DKDContent>)content
                              withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content isKindOfClass:[DIMGroupCommand class]], @"group command error: %@", content);
    DIMGroupCommand *cmd = (DIMGroupCommand *)content;
    DIMCommandProcessor *cpu = [self getProcessorForCommand:cmd];
    if (!cpu) {
        cpu = [self getProcessorForName:DIMCommand_Unknown];
    }
    if (!cpu || cpu == self) {
        return [self processUnknownCommand:cmd withMessage:rMsg];
    }
    return [cpu processContent:content withMessage:rMsg];
}

- (id<DKDContent>)processUnknownCommand:(DIMCommand *)cmd
                            withMessage:(id<DKDReliableMessage>)rMsg {
    NSString *text = [NSString stringWithFormat:@"Group command (%@) not support yet!", cmd.command];
    id<DKDContent>res = [[DIMTextContent alloc] initWithText:text];
    res.group = cmd.group;
    return res;
}

@end
