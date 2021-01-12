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

- (nullable id<DKDContent>)_getDocumentForID:(id<MKMID>)ID {
    // query document for ID
    id<MKMDocument> doc = [self.facebook documentForID:ID type:@"*"];
    if (doc) {
        return [[DIMDocumentCommand alloc] initWithID:ID document:doc];
    }
    // document not found
    NSString *text = [NSString stringWithFormat:@"Sorry, document not found for ID: %@", ID];
    return [[DIMTextContent alloc] initWithText:text];
}

- (nullable id<DKDContent>)_putDocument:(id<MKMDocument>)doc
                                   meta:(nullable id<MKMMeta>)meta
                                  forID:(id<MKMID>)ID {
    NSString *text;
    if (meta) {
        // received a meta for ID
        if (![meta matchID:ID]) {
            // meta not match
            text = [NSString stringWithFormat:@"Meta not match ID: %@", ID];
            return [[DIMTextContent alloc] initWithText:text];
        }
        if (![self.facebook saveMeta:meta forID:ID]) {
            // save failed
            NSAssert(false, @"failed to save meta for ID: %@, %@", ID, meta);
            return nil;
        }
    }
    // received a document for ID
    if (![self.facebook isValidDocument:doc]) {
        // document sitnature not match
        text = [NSString stringWithFormat:@"Document not match ID: %@", ID];
        return [[DIMTextContent alloc] initWithText:text];
    }
    if (![self.facebook saveDocument:doc]) {
        // save failed
        NSAssert(false, @"failed to save document for ID: %@, %@", ID, doc);
        return nil;
    }
    text = [NSString stringWithFormat:@"Document updated for ID: %@", ID];
    return [[DIMReceiptCommand alloc] initWithMessage:text];
}

- (nullable id<DKDContent>)executeCommand:(DIMCommand *)content
                              withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content isKindOfClass:[DIMDocumentCommand class]], @"document command error: %@", content);
    DIMDocumentCommand *cmd = (DIMDocumentCommand *)content;
    id<MKMID> ID = cmd.ID;
    id<MKMDocument> doc = cmd.document;
    if (doc) {
        // check meta
        id<MKMMeta> meta = cmd.meta;
        return [self _putDocument:doc meta:meta forID:ID];
    } else {
        return [self _getDocumentForID:ID];
    }
}

@end
