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

- (nullable id<DIMArchivist>)archivist {
    DIMFacebook *facebook = [self facebook];
    return [facebook archivist];
}

// Override
- (NSArray<id<DKDContent>> *)processContent:(__kindof id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content conformsToProtocol:@protocol(DKDMetaCommand)],
             @"meta command error: %@", content);
    id<DKDEnvelope> envelope = [rMsg envelope];
    id<DKDMetaCommand> command = content;
    id<MKMMeta> meta = [command meta];
    id<MKMID> did = [command identifier];
    if (!did) {
        NSAssert(false, @"meta ID cannot be empty: %@", command);
        return [self respondReceipt:@"Meta command error."
                           envelope:envelope
                            content:content
                              extra:nil];
    } else if (!meta) {
        // query meta for ID
        return [self respondMeta:did content:command envelope:envelope];
    }
    // received a meta for ID
    return [self putMeta:meta forID:did content:command envelope:envelope];
}

// private
- (NSArray<id<DKDContent>> *)respondMeta:(id<MKMID>)did
                                 content:(id<DKDMetaCommand>)command
                                envelope:(id<DKDEnvelope>)head {
    DIMFacebook *facebook = [self facebook];
    id<MKMMeta> meta = [facebook metaForID:did];
    if (!meta) {
        // extra info for receipt
        NSDictionary *info = @{
            @"template": @"Meta not found: ${did}.",
            @"replacements": @{
                @"did": did.string,
            },
        };
        return [self respondReceipt:@"Meta not found."
                           envelope:head
                            content:command
                              extra:info];
    }
    // meta got
    return @[
        DIMMetaCommandResponse(did, meta)
    ];
}

- (NSArray<id<DKDContent>> *)putMeta:(id<MKMMeta>)meta
                               forID:(id<MKMID>)did
                             content:(id<DKDMetaCommand>)command
                            envelope:(id<DKDEnvelope>)head {
    NSArray<id<DKDContent>> *errors;
    // 1. try to save meta
    errors = [self saveMeta:meta forID:did content:command envelope:head];
    if (errors) {
        // failed
        return errors;
    }
    // 2. success
    NSDictionary *info = @{
        @"template": @"Meta received: ${did}.",
        @"replacements": @{
            @"did": did.string,
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
                                         forID:(id<MKMID>)did
                                       content:(id<DKDMetaCommand>)command
                                      envelope:(id<DKDEnvelope>)head {
    id<DIMArchivist> archivist = [self archivist];
    NSAssert(archivist, @"archivist not ready");
    BOOL ok;
    // check meta
    ok = [self checkMeta:meta forID:did];
    if (!ok) {
        // extra info for receipt
        NSDictionary *info = @{
            @"template": @"Meta not valid: ${did}.",
            @"replacements": @{
                @"did": did.string,
            },
        };
        return [self respondReceipt:@"Meta not valid."
                           envelope:head
                            content:command
                              extra:info];
    }
    ok = [archivist saveMeta:meta forID:did];
    if (!ok) {
        // DB error?
        NSDictionary *info = @{
            @"template": @"Meta not accepted: ${did}.",
            @"replacements": @{
                @"did": did.string,
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

- (BOOL)checkMeta:(id<MKMMeta>)meta forID:(id<MKMID>)did {
    if (![meta isValid]) {
        return NO;
    }
    id<MKMAddress> old = [did address];
    id<MKMAddress> gen = MKMAddressGenerate(meta, [old network]);
    return [old isEqual:gen];
}

@end
