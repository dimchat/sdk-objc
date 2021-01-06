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

- (instancetype)initWithTransceiver:(DIMTransceiver *)transceiver {
    NSAssert(false, @"don't call me!");
    DIMMessenger *messenger = (DIMMessenger *)transceiver;
    return [self initWithMessenger:messenger];
}

/* designated initializer */
- (instancetype)initWithMessenger:(DIMMessenger *)messenger {
    if (self = [super initWithTransceiver:messenger]) {
        //
    }
    return self;
}

- (DIMMessenger *)messenger {
    return (DIMMessenger *) self.transceiver;
}

- (DIMFacebook *)facebook {
    return [self.messenger facebook];
}

- (BOOL)isWaiting:(id<MKMID>)ID {
    if (MKMIDIsBroadcast(ID)) {
        // broadcast ID doesn't contain meta or visa
        return NO;
    }
    if (MKMIDIsGroup(ID)) {
        // if group is not broadcast ID, its meta should be exists
        return [self.facebook metaForID:ID] == nil;
    }
    // if receiver is not broadcast ID, its visa key should be exists
    return [self.facebook publicKeyForEncryption:ID] == nil;
}

- (id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg {
    id<MKMID> receiver = iMsg.receiver;
    id<MKMID> group = iMsg.group;
    if ([self isWaiting:receiver] || (group && [self isWaiting:group])) {
        // NOTICE: the application will query visa automatically
        // save this message in a queue waiting sender's visa response
        [self.messenger suspendMessage:iMsg];
        return nil;
    }
    
    // make sure visa.key exists before encrypting message
    return [super encryptMessage:iMsg];
}

- (id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg {
    id<MKMID> sender = rMsg.sender;
    // [Meta Protocol]
    id<MKMMeta> meta = rMsg.meta;
    if (!meta) {
        // get from local storage
        meta = [self.facebook metaForID:sender];
    } else if (![self.facebook saveMeta:meta forID:sender]) {
        // failed to save meta attached to message
        meta = nil;
    }
    if (!meta) {
        // NOTICE: the application will query meta automatically
        // save this message in a queue waiting sender's meta response
        [self.messenger suspendMessage:rMsg];
        return nil;
    }
    // [Visa Protocol]
    id<MKMVisa> visa = rMsg.visa;
    if (visa) {
        [self.facebook saveDocument:visa];
    }
    
    // make sure meta exists before verifying message
    return [super verifyMessage:rMsg];
}

- (id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg {
    // check message delegate
    if (!sMsg.delegate) {
        sMsg.delegate = self.transceiver;
    }
    id<MKMID> receiver = sMsg.receiver;
    DIMUser *user = [self.facebook selectLocalUserWithID:receiver];
    id<DKDSecureMessage> trimmed;
    if (!user) {
        // local users not matched
        trimmed = nil;
    } else if (MKMIDIsGroup(receiver)) {
        // trim group message
        trimmed = [sMsg trimForMember:user.ID];
    } else {
        trimmed = sMsg;
    }
    if (!trimmed) {
        // not for you?
        @throw [NSException exceptionWithName:@"ReceiverError" reason:@"not for you?" userInfo:sMsg.dictionary];
    }
    
    // make sure private key (decrypt key) exists before decrypting message
    return [super decryptMessage:sMsg];
}

@end
