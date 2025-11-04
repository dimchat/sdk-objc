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
//  DIMDocumentCommandProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 Albert Moky. All rights reserved.
//

#import "DIMAccountUtils.h"
#import "DIMFacebook.h"

#import "DIMDocumentCommandProcessor.h"

@implementation DIMDocumentCommandProcessor

//
//  Main
//
- (NSArray<id<DKDContent>> *)processContent:(__kindof id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content conformsToProtocol:@protocol(DKDDocumentCommand)],
             @"document command error: %@", content);
    id<DKDEnvelope> envelope = [rMsg envelope];
    id<DKDDocumentCommand> command = content;
    id<MKMID> ID = [command identifier];
    NSArray<id<MKMDocument>> *documents = [command documents];
    if (!ID) {
        NSAssert(false, @"document ID cannot be empty: %@", command);
        return [self respondReceipt:@"Document command error."
                           envelope:envelope
                            content:content
                              extra:nil];
    } else if ([documents count] == 0) {
        // query documents for ID
        return [self documentsForID:ID withContent:command andEnvelope:envelope];
    }
    // check document ID
    BOOL ok;
    for (id<MKMDocument> doc in documents) {
        ok = [doc.identifier isEqual:ID];
        if (!ok) {
            // error
            NSAssert(false, @"document ID not match: %@", command);
            // extra info for receipt
            NSDictionary *info = @{
                @"template": @"Document ID not match: ${did}.",
                @"replacements": @{
                    @"did": ID.string,
                },
            };
            return [self respondReceipt:@"Document ID not match."
                               envelope:envelope
                                content:content
                                  extra:info];
        }
    }
    // reveived a document for ID
    return [self putDocuments:documents
                        forID:ID
                  withContent:command
                  andEnvelope:envelope];
}

// protected
- (NSArray<id<DKDContent>> *)documentsForID:(id<MKMID>)ID
                                withContent:(id<DKDDocumentCommand>)command
                                andEnvelope:(id<DKDEnvelope>)head {
    DIMFacebook *facebook = [self facebook];
    NSArray<id<MKMDocument>> *docs = [facebook documents:ID];
    if ([docs count] == 0) {
        // extra info for receipt
        NSDictionary *info = @{
            @"template": @"Document not found: ${did}.",
            @"replacements": @{
                @"did": ID.string,
            },
        };
        return [self respondReceipt:@"Document not found."
                           envelope:head
                            content:command
                              extra:info];
    }
    // documents got
    NSDate *queryTime = [command lastTime];
    if (queryTime) {
        // check last document time
        id<MKMDocument> last = DIMDocumentGetLast(docs, @"*");
        NSAssert(last, @"should not happen");
        NSDate *lastTime = [last time];
        NSTimeInterval lt = [lastTime timeIntervalSince1970];
        if (lt < 1) {
            NSAssert(false, @"document error: %@", last);
        } else if (lt <= [queryTime timeIntervalSince1970]) {
            // document not updated
            NSDictionary *info = @{
                @"template": @"Document not updated: ${did}, last time: ${time}.",
                @"replacements": @{
                    @"did": ID.string,
                    @"time": @(lt),
                },
            };
            return [self respondReceipt:@"Document not updated."
                               envelope:head
                                content:command
                                  extra:info];
        }
    }
    id<MKMMeta> meta = [facebook meta:ID];
    return @[
        DIMDocumentCommandResponse(ID, meta, docs)
    ];
}

- (NSArray<id<DKDContent>> *)putDocuments:(NSArray<id<MKMDocument>> *)documents
                                    forID:(id<MKMID>)ID
                              withContent:(id<DKDDocumentCommand>)command
                              andEnvelope:(id<DKDEnvelope>)head  {
    NSArray<id<DKDContent>> *errors;
    id<MKMMeta> meta = [command meta];
    // 0. check meta
    if (!meta) {
        DIMFacebook *facebook = [self facebook];
        meta = [facebook meta:ID];
        if (!meta) {
            // extra info for receipt
            NSDictionary *info = @{
                @"template": @"Meta not found: ${did}.",
                @"replacements": @{
                    @"did": ID.string,
                },
            };
            return [self respondReceipt:@"Meta not found."
                               envelope:head
                                content:command
                                  extra:info];
        }
    } else {
        // 1. try to save meta
        errors = [self saveMeta:meta forID:ID content:command envelope:head];
        if (errors) {
            // failed
            return errors;
        }
    }
    // 2. try to save document
    NSMutableArray *mArray = [[NSMutableArray alloc] init];
    for (id<MKMDocument> doc in documents) {
        errors = [self saveDocument:doc
                              forID:ID
                           withMeta:meta
                            content:command
                           envelope:head];
        if ([errors count] > 0) {
            [mArray addObjectsFromArray:errors];
        }
    }
    if ([mArray count] > 0) {
        // failed
        return mArray;
    }
    // 3. success
    NSDictionary *info = @{
        @"template": @"Document received: ${did}.",
        @"replacements": @{
            @"did": ID.string,
        },
    };
    return [self respondReceipt:@"Document received."
                       envelope:head
                        content:command
                          extra:info];
}

@end

@implementation DIMDocumentCommandProcessor (Storage)

- (nullable NSArray<id<DKDContent>> *)saveDocument:(id<MKMDocument>)doc
                                             forID:(id<MKMID>)ID
                                          withMeta:(id<MKMMeta>)meta
                                           content:(id<DKDMetaCommand>)command
                                          envelope:(id<DKDEnvelope>)head {
    id<DIMArchivist> archivist = [self archivist];
    BOOL ok;
    // check document
    ok = [self checkDocument:doc withMeta:meta];
    if (!ok) {
        // document error
        NSDictionary *info = @{
            @"template": @"Document not accepted: ${did}.",
            @"replacements": @{
                @"did": ID.string,
            },
        };
        return [self respondReceipt:@"Document not accepted."
                           envelope:head
                            content:command
                              extra:info];
    }
    ok = [archivist saveDocument:doc];
    if (!ok) {
        // document expired
        NSDictionary *info = @{
            @"template": @"Document not changed: ${did}.",
            @"replacements": @{
                @"did": ID.string,
            },
        };
        return [self respondReceipt:@"Document not changed."
                           envelope:head
                            content:command
                              extra:info];
    }
    // document saved, return no error
    return nil;
}

- (BOOL)checkDocument:(id<MKMDocument>)doc withMeta:(id<MKMMeta>)meta {
    if ([doc isValid]) {
        return YES;
    }
    // NOTICE: if this is a bulletin document for group,
    //             verify it with the group owner's meta.key
    //         else (this is a visa document for user)
    //             verify it with the user's meta.key
    return [doc verify:meta.publicKey];
    // TODO: check for group document
}

@end
