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

#import "DIMFacebook.h"
#import "DIMReceiptCommand.h"

#import "DIMDocumentCommandProcessor.h"

@implementation DIMDocumentCommandProcessor

- (NSArray<id<DKDContent>> *)getDocumentForID:(id<MKMID>)ID withType:(NSString *)type {
    DIMFacebook *facebook = self.facebook;
    // query document for ID
    id<MKMDocument> doc = [facebook documentForID:ID type:type];
    if (doc) {
        DIMCommand *command = [[DIMDocumentCommand alloc] initWithID:ID document:doc];
        return [self respondContent:command];
    } else {
        NSString *text = [NSString stringWithFormat:@"Sorry, document not found for ID: %@", ID];
        return [self respondText:text withGroup:nil];
    }
}

- (NSArray<id<DKDContent>> *)putDocument:(id<MKMDocument>)doc meta:(nullable id<MKMMeta>)meta forID:(id<MKMID>)ID {
    DIMFacebook *facebook = self.facebook;
    NSString *text;
    if (meta) {
        // received a meta for ID
        if (![facebook saveMeta:meta forID:ID]) {
            text = [NSString stringWithFormat:@"Meta not accepted: %@", ID];
            return [self respondText:text withGroup:nil];
        }
    }
    // received a document for ID
    if ([facebook saveDocument:doc]) {
        text = [NSString stringWithFormat:@"Document received %@", ID];
        return [self respondReceipt:text];
    } else {
        text = [NSString stringWithFormat:@"Document not accepted: %@", ID];
        return [self respondText:text withGroup:nil];
    }
}

- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content isKindOfClass:[DIMDocumentCommand class]], @"document command error: %@", content);
    DIMDocumentCommand *command = (DIMDocumentCommand *)content;
    id<MKMID> ID = command.ID;
    if (ID) {
        id<MKMDocument> doc = command.document;
        if (!doc) {
            // query entity document for ID
            NSString *type = [command objectForKey:@"doc_type"];
            if ([type length] == 0) {
                type = @"*";  // ANY
            }
            return [self getDocumentForID:ID withType:type];
        } else if ([ID isEqual:doc.ID]) {
            // received a new document for ID
            return [self putDocument:doc meta:command.meta forID:ID];
        }
    }
    // error
    return [self respondText:@"Document command error." withGroup:nil];
}

@end
