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

- (nullable id<MKMID>)overtGroupForContent:(id<DKDContent>)content {
    id<MKMID> group = content.group;
    if (!group) {
        return nil;
    }
    if (MKMIDIsBroadcast(group)) {
        // broadcast message is always overt
        return group;
    }
    if ([content conformsToProtocol:@protocol(DIMCommand)]) {
        // group command should be sent to each member directly, so
        // don't expose group ID
        return nil;
    }
    return group;
}

- (nullable id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg {
    DIMMessenger *transceiver = self.messenger;
    // check message delegate
    if (!iMsg.delegate) {
        iMsg.delegate = transceiver;
    }
    id<MKMID> sender = iMsg.sender;
    id<MKMID> receiver = iMsg.receiver;
    // if 'group' exists and the 'receiver' is a group ID,
    // they must be equal
    
    // NOTICE: while sending group message, don't split it before encrypting.
    //         this means you could set group ID into message content, but
    //         keep the "receiver" to be the group ID;
    //         after encrypted (and signed), you could split the message
    //         with group members before sending out, or just send it directly
    //         to the group assistant to let it split messages for you!
    //    BUT,
    //         if you don't want to share the symmetric key with other members,
    //         you could split it (set group ID into message content and
    //         set contact ID to the "receiver") before encrypting, this usually
    //         for sending group command to assistant bot, which should not
    //         share the symmetric key (group msg key) with other members.

    // 1. get symmetric key
    id<MKMID> group = [transceiver overtGroupForContent:iMsg.content];
    id<MKMSymmetricKey> password;
    if (group) {
        // group message (excludes group command)
        password = [transceiver cipherKeyFrom:sender to:group generate:YES];
        NSAssert(password, @"failed to get msg key: %@ -> %@", sender, group);
    } else {
        // personal message or (group) command
        password = [transceiver cipherKeyFrom:sender to:receiver generate:YES];
        NSAssert(password, @"failed to get msg key: %@ -> %@", sender, receiver);
    }

    NSAssert(iMsg.content, @"content cannot be empty");
    
    // 2. encrypt 'content' to 'data' for receiver/group members
    id<DKDSecureMessage> sMsg = nil;
    if (MKMIDIsGroup(receiver)) {
        // group message
        id<DIMGroup> grp = [self.facebook groupWithID:receiver];
        NSArray<id<MKMID>> *members = [grp members];
        if (members.count == 0) {
            // group not ready
            // TODO: suspend this message for waiting group info
            return nil;
        }
        sMsg = [iMsg encryptWithKey:password forMembers:members];
    } else {
        // personal message (or split group message)
        sMsg = [iMsg encryptWithKey:password];
    }
    
    // overt group ID
    if (group && ![receiver isEqual:group]) {
        // NOTICE: this help the receiver knows the group ID
        //         when the group message separated to multi-messages,
        //         if don't want the others know you are the group members,
        //         remove it.
        sMsg.envelope.group = group;
    }
    
    // NOTICE: copy content type to envelope
    //         this help the intermediate nodes to recognize message type
    sMsg.envelope.type = iMsg.content.type;

    // OK
    return sMsg;
}

- (nullable id<DKDReliableMessage>)signMessage:(id<DKDSecureMessage>)sMsg {
    // check message delegate
    if (sMsg.delegate == nil) {
        sMsg.delegate = self.messenger;
    }
    NSAssert(sMsg.data, @"message data cannot be empty");
    // sign 'data' by sender
    return [sMsg sign];
}

- (nullable NSData *)serializeMessage:(id<DKDReliableMessage>)rMsg {
    return MKMUTF8Encode(MKMJSONEncode(rMsg));
}

- (nullable id<DKDReliableMessage>)deserializeMessage:(NSData *)data {
    NSAssert([data length] > 0, @"message data should not be empty");
    id dict = MKMJSONDecode(MKMUTF8Decode(data));
    // TODO: translate short keys
    //       'S' -> 'sender'
    //       'R' -> 'receiver'
    //       'W' -> 'time'
    //       'T' -> 'type'
    //       'G' -> 'group'
    //       ------------------
    //       'D' -> 'data'
    //       'V' -> 'signature'
    //       'K' -> 'key', 'keys'
    //       ------------------
    //       'M' -> 'meta'
    //       'P' -> 'visa'
    return DKDReliableMessageFromDictionary(dict);
}

// TODO: make sure meta exists before verifying message
- (id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg {
    DIMFacebook *facebook = self.facebook;
    id<MKMID> sender = rMsg.sender;
    // [Meta Protocol]
    id<MKMMeta> meta = rMsg.meta;
    if (meta) {
        [facebook saveMeta:meta forID:sender];
    }
    // [Visa Protocol]
    id<MKMVisa> visa = rMsg.visa;
    if (visa) {
        [facebook saveDocument:visa];
    }
    
    // check message delegate
    if (rMsg.delegate == nil) {
        rMsg.delegate = self.messenger;
    }
    //
    //  NOTICE: check [Visa Protocol] before calling this
    //        make sure the sender's meta(visa) exists
    //        (do in by application)
    //
    
    NSAssert(rMsg.signature, @"message signature cannot be empty");
    // verify 'data' with 'signature'
    return [rMsg verify];
}

// TODO: make sure private key (decrypt key) exists before decrypting message
- (id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg {
    id<MKMID> receiver = sMsg.receiver;
    id<DIMUser> user = [self.facebook selectLocalUserWithID:receiver];
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
    
    // check message delegate
    if (sMsg.delegate == nil) {
        sMsg.delegate = self.messenger;
    }
    //
    //  NOTICE: make sure the receiver is YOU!
    //          which means the receiver's private key exists;
    //          if the receiver is a group ID, split it first
    //
    
    NSAssert(sMsg.data, @"message data cannot be empty");
    // decrypt 'data' to 'content'
    return [sMsg decrypt];
    
    // NOTICE: check: top-secret message after called this
    //       (do it by application)
}

@end
