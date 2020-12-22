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
//  DIMMessagePacker.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/22.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMMessagePacker.h"

@implementation DIMMessagePacker

- (instancetype)initWithMessenger:(DIMMessenger *)messenger {
    if (self = [super initWithEntityDelegate:messenger.barrack
                           cipherKeyDelegate:messenger.keyCache
                             messageDelegate:messenger]) {
        //
    }
    return self;
}

- (DIMFacebook *)facebook {
    return [self.messenger facebook];
}

- (DIMMessenger *)messenger {
    return (DIMMessenger *) self.transceiver;
}

// [Meta Protocol]
- (BOOL)checkMetaWithMessage:(id<DKDReliableMessage>)rMsg {
    // check message delegate
    if (!rMsg.delegate) {
        rMsg.delegate = self.transceiver;
    }
    // check meta attached to message
    id<MKMMeta> meta = rMsg.meta;
    if (!meta) {
        return [self.facebook metaForID:rMsg.sender] != nil;
    }
    // [Meta Protocol]
    // save meta for sender
    return [self.facebook saveMeta:meta forID:rMsg.sender];
}

// [Visa Protocol]
- (void)checkVisaWithMessage:(id<DKDReliableMessage>)rMsg {
    // check visa attached to message
    id<MKMVisa> visa = rMsg.visa;
    if (visa) {
        // [Visa Protocol]
        // save visa for sender
        [self.facebook saveDocument:visa];
    }
}

- (BOOL)checkReceiver:(id<MKMID>)receiver {
    if (MKMIDIsGroup(receiver)) {
        // check group meta
        return [self.facebook metaForID:receiver] != nil;
    }
    // 1. check key from visa
    // 2. check key from meta
    return [self.facebook publicKeyForEncryption:receiver] != nil;
}

- (id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg {
    // make sure visa.key exists before encrypting message
    if ([self checkReceiver:iMsg.receiver]) {
        return [super encryptMessage:iMsg];
    }
    // NOTICE: the application will query visa automatically
    // save this message in a queue waiting sender's visa response
    [self.messenger suspendMessage:iMsg];
    return nil;
}

- (id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg {
    // make sure meta.key exists before verifying message
    if ([self checkMetaWithMessage:rMsg]) {
        [self checkVisaWithMessage:rMsg];  // check and save visa attached to message
        return [super verifyMessage:rMsg];
    }
    // NOTICE: the application will query meta & profile automatically
    // save this message in a queue waiting sender's meta response
    [self.messenger suspendMessage:rMsg];
    return nil;
}

- (id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg {
    // try to trim message
    id<DKDSecureMessage> tMsg = [self trimMessage:sMsg];
    if (!tMsg) {
        @throw [NSException exceptionWithName:@"ReceiverError" reason:@"not for you?" userInfo:sMsg.dictionary];
    }
    return [super decryptMessage:sMsg];
}

- (nullable id<DKDSecureMessage>)trimMessage:(id<DKDSecureMessage>)sMsg {
    // check message delegate
    if (!sMsg.delegate) {
        sMsg.delegate = self.transceiver;
    }
    id<MKMID> receiver = sMsg.receiver;
    MKMUser *user = [self.facebook selectLocalUserWithID:receiver];
    if (!user) {
        // local users not matched
        sMsg = nil;
    } else if (MKMIDIsGroup(receiver)) {
        // trim group message
        sMsg = [sMsg trimForMember:user.ID];
    }
    return sMsg;
}

@end
