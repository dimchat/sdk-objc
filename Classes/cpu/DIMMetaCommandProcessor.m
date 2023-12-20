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

#import "DIMMetaCommandProcessor.h"

@implementation DIMMetaCommandProcessor

//
//  Main
//
- (NSArray<id<DKDContent>> *)processContent:(__kindof id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content conformsToProtocol:@protocol(DKDMetaCommand)],
             @"meta command error: %@", content);
    id<DKDMetaCommand> command = content;
    id<MKMID> ID = command.ID;
    id<MKMMeta> meta = command.meta;
    if (!ID) {
        NSAssert(false, @"meta ID cannot be empty: %@", command);
        return [self respondReceipt:@"Meta command error."
                           envelope:rMsg.envelope
                            content:content
                              extra:nil];
    } else if (meta) {
        // received a meta for ID
        return [self putMeta:meta
                       forID:ID
                 withContent:command
                 andEnvelope:rMsg.envelope];
    } else {
        // query meta for ID
        return [self getMetaForID:ID
                      withContent:command
                      andEnvelope:rMsg.envelope];
    }
}

// private
- (NSArray<id<DKDContent>> *)getMetaForID:(id<MKMID>)ID
                              withContent:(id<DKDMetaCommand>)command
                              andEnvelope:(id<DKDEnvelope>)head {
    id<MKMMeta> meta = [self.facebook metaForID:ID];
    if (!meta) {
        // extra info for receipt
        NSDictionary *info = @{
            @"template": @"Meta not found: ${ID}.",
            @"replacements": @{
                @"ID": ID.string,
            },
        };
        return [self respondReceipt:@"Meta not found."
                           envelope:head
                            content:command
                              extra:info];
    }
    // meta got
    return @[
        DIMMetaCommandResponse(ID, meta)
    ];
}

- (NSArray<id<DKDContent>> *)putMeta:(id<MKMMeta>)meta
                               forID:(id<MKMID>)ID
                         withContent:(id<DKDMetaCommand>)command
                         andEnvelope:(id<DKDEnvelope>)head {
    NSArray<id<DKDContent>> *errors;
    // 1. try to save meta
    errors = [self saveMeta:meta
                      forID:ID
                    content:command
                   envelope:head];
    if (errors) {
        // failed
        return errors;
    }
    // 2. success
    NSDictionary *info = @{
        @"template": @"Meta received: ${ID}.",
        @"replacements": @{
            @"ID": ID.string,
        },
    };
    return [self respondReceipt:@"Meta received."
                       envelope:head
                        content:command
                          extra:info];
}

@end

@implementation DIMMetaCommandProcessor (Storage)

- (nullable NSArray<id<DKDContent>> *)saveMeta:(id<MKMMeta>)meta
                                         forID:(id<MKMID>)ID
                                       content:(id<DKDMetaCommand>)command
                                      envelope:(id<DKDEnvelope>)head {
    DIMFacebook *facebook = [self facebook];
    // check meta
    if (![self checkMeta:meta forID:ID]) {
        // extra info for receipt
        NSDictionary *info = @{
            @"template": @"Meta not valid: ${ID}.",
            @"replacements": @{
                @"ID": ID.string,
            },
        };
        return [self respondReceipt:@"Meta not valid."
                           envelope:head
                            content:command
                              extra:info];
    } else if (![facebook saveMeta:meta forID:ID]) {
        // DB error?
        NSDictionary *info = @{
            @"template": @"Meta not accepted: ${ID}.",
            @"replacements": @{
                @"ID": ID.string,
            },
        };
        return [self respondReceipt:@"Meta not accepted."
                           envelope:head
                            content:command
                              extra:info];
    }
    // meta saved, return no error
    return nil;
}

- (BOOL)checkMeta:(id<MKMMeta>)meta forID:(id<MKMID>)ID {
    return [meta isValid] && [meta matchIdentifier:ID];
}

@end
