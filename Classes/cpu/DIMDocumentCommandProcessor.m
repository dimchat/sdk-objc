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

- (nullable id<DKDContent>)_getProfileForID:(id<MKMID>)ID {
    // query profile for ID
    id<MKMDocument>profile = [self.facebook documentForID:ID type:MKMDocument_Any];
    if (profile) {
        return [[DIMDocumentCommand alloc] initWithID:ID profile:profile];
    }
    // profile not found
    NSString *text = [NSString stringWithFormat:@"Sorry, profile not found for ID: %@", ID];
    return [[DIMTextContent alloc] initWithText:text];
}

- (nullable id<DKDContent>)_putProfile:(id<MKMDocument>)profile
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
    // received a profile for ID
    if (![self.facebook verifyDocument:profile forID:ID]) {
        // profile sitnature not match
        text = [NSString stringWithFormat:@"Profile not match ID: %@", ID];
        return [[DIMTextContent alloc] initWithText:text];
    }
    if (![self.facebook saveDocument:profile]) {
        // save failed
        NSAssert(false, @"failed to save profile for ID: %@, %@", ID, profile);
        return nil;
    }
    text = [NSString stringWithFormat:@"Profile updated for ID: %@", ID];
    return [[DIMReceiptCommand alloc] initWithMessage:text];
}

//
//  Main
//
- (nullable id<DKDContent>)processContent:(id<DKDContent>)content
                              withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content isKindOfClass:[DIMDocumentCommand class]], @"document command error: %@", content);
    DIMDocumentCommand *cmd = (DIMDocumentCommand *)content;
    id<MKMID> ID = cmd.ID;
    id<MKMDocument> profile = cmd.document;
    if (profile) {
        // check meta
        id<MKMMeta> meta = cmd.meta;
        return [self _putProfile:profile meta:meta forID:ID];
    } else {
        return [self _getProfileForID:ID];
    }
}

@end
