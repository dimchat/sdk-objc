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
//  DIMMetaCommandProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 Albert Moky. All rights reserved.
//

#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMMetaCommandProcessor.h"

@implementation DIMMetaCommandProcessor

- (NSArray<id<DKDContent>> *)getMetaForID:(id<MKMID>)ID {
    id<MKMMeta> meta = [self.facebook metaForID:ID];
    if (meta) {
        DIMCommand *command = [[DIMMetaCommand alloc] initWithID:ID meta:meta];
        return [self respondContent:command];
    } else {
        NSString *text = [NSString stringWithFormat:@"Sorry, meta not found for ID: %@", ID];
        return [self respondText:text withGroup:nil];
    }
}

- (NSArray<id<DKDContent>> *)putMeta:(id<MKMMeta>)meta forID:(id<MKMID>)ID {
    NSString *text;
    if ([self.facebook saveMeta:meta forID:ID]) {
        text = [NSString stringWithFormat:@"Meta received %@", ID];
        return [self respondText:text withGroup:nil];
    } else {
        text = [NSString stringWithFormat:@"Meta not accepted: %@", ID];
        return [self respondText:text withGroup:nil];
    }
}

- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content conformsToProtocol:@protocol(DIMMetaCommand)],
             @"meta command error: %@", content);
    id<DIMMetaCommand> command = (id<DIMMetaCommand>)content;
    id<MKMID> ID = command.ID;
    id<MKMMeta> meta = command.meta;
    if (!ID) {
        // error
        return [self respondText:@"Meta command error." withGroup:nil];
    } else if (meta) {
        // received a meta for ID
        return [self putMeta:meta forID:ID];
    } else {
        // query meta for ID
        return [self getMetaForID:ID];
    }
}

@end
