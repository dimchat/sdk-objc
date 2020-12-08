// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2020 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2020 Albert Moky
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
//  DIMMessageProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/8.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "DIMMessenger.h"
#import "DIMFacebook.h"

#import "DIMMessageProcessor.h"

@implementation DIMMessageProcessor

- (DIMMessenger *)messenger {
    return self.delegate;
}

- (DIMFacebook *)facebook {
    return [[self messenger] facebook];
}

- (nullable id<DKDSecureMessage>)trimMessage:(id<DKDSecureMessage>)sMsg {
    // check message delegate
    if (!sMsg.delegate) {
        sMsg.delegate = self.delegate;
    }
    id<MKMID>receiver = sMsg.envelope.receiver;
    MKMUser *user = [[self facebook] selectUserWithID:receiver];
    if (!user) {
        // local users not matched
        sMsg = nil;
    } else if (MKMIDIsGroup(receiver)) {
        // trim group message
        sMsg = [sMsg trimForMember:user.ID];
    }
    return sMsg;
}

- (nullable id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg {
    // check message delegate
    if (!rMsg.delegate) {
        rMsg.delegate = self.delegate;
    }
    // Notice: check meta before calling me
    id<MKMID> sender = rMsg.envelope.sender;
    id<MKMMeta> meta = rMsg.meta;
    if (meta) {
        // [Meta Protocol]
        // save meta for sender
        if (![[self facebook] saveMeta:meta forID:sender]) {
            NSAssert(false, @"save meta error: %@, %@", sender, meta);
            return nil;
        }
    } else {
        meta = [[self facebook] metaForID:sender];
        if (!meta) {
            // NOTICE: the application will query meta automatically
            // save this message in a queue waiting sender's meta response
            [[self messenger] suspendMessage:rMsg];
            //NSAssert(false, @"failed to get meta for sender: %@", sender);
            return nil;
        }
    }
    return [super verifyMessage:rMsg];
}

- (nullable id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg {
    // trim message
    id<DKDSecureMessage> msg = [self trimMessage:sMsg];
    if (!msg) {
        // not for you?
        @throw [NSException exceptionWithName:@"ReceiverError" reason:@"not for you?" userInfo:sMsg.dictionary];
    }
    // decrypt message
    return [super decryptMessage:msg];
}

@end
