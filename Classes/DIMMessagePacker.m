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

#import "DIMMessageUtils.h"
#import "DIMMessageHelpers.h"

#import "DIMInstantMessagePacker.h"
#import "DIMSecureMessagePacker.h"
#import "DIMReliableMessagePacker.h"

#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMMessagePacker.h"

@interface DIMMessagePacker ()

@property (strong, nonatomic) DIMInstantMessagePacker *instantPacker;
@property (strong, nonatomic) DIMSecureMessagePacker *securePacker;
@property (strong, nonatomic) DIMReliableMessagePacker *reliablePacker;

@end

@implementation DIMMessagePacker

- (instancetype)initWithFacebook:(DIMFacebook *)facebook
                       messenger:(DIMMessenger *)transceiver {
    if (self = [super initWithFacebook:facebook messenger:transceiver]) {
        self.instantPacker  = [self createInstantMessagePacker:transceiver];
        self.securePacker   = [self createSecureMessagePacker:transceiver];
        self.reliablePacker = [self createReliableMessagePacker:transceiver];
    }
    return self;
}

- (DIMInstantMessagePacker *)createInstantMessagePacker:(id<DKDInstantMessageDelegate>)delegate {
    return [[DIMInstantMessagePacker alloc] initWithDelegate:delegate];
}

- (DIMSecureMessagePacker *)createSecureMessagePacker:(id<DKDSecureMessageDelegate>)delegate {
    return [[DIMSecureMessagePacker alloc] initWithDelegate:delegate];
}

- (DIMReliableMessagePacker *)createReliableMessagePacker:(id<DKDReliableMessageDelegate>)delegate {
    return [[DIMReliableMessagePacker alloc] initWithDelegate:delegate];
}

- (nullable id<DIMArchivist>)archivist {
    DIMFacebook *facebook = [self facebook];
    return [facebook archivist];
}

//
//  InstantMessage -> SecureMessage -> ReliableMessage -> Data
//

// Override
- (nullable id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg {
    // TODO: check receiver before calling this, make sure the visa.key exists;
    //       otherwise, suspend this message for waiting receiver's visa/meta;
    //       if receiver is a group, query all members' visa too!
    DIMFacebook *facebook = [self facebook];
    DIMMessenger *messenger = [self messenger];
    NSAssert(facebook && messenger, @"twins not ready");

    id<DKDSecureMessage> sMsg;
    // NOTICE: before sending group message, you can decide whether expose the group ID
    //      (A) if you don't want to expose the group ID,
    //          you can split it to multi-messages before encrypting,
    //          replace the 'receiver' to each member and keep the group hidden in the content;
    //          in this situation, the packer will use the personal message key (user to user);
    //      (B) if the group ID is overt, no need to worry about the exposing,
    //          you can keep the 'receiver' being the group ID, or set the group ID as 'group'
    //          when splitting to multi-messages to let the remote packer knows it;
    //          in these situations, the local packer will use the group msg key (user to group)
    //          to encrypt the message, and the remote packer can get the overt group ID before
    //          decrypting to take the right message key.
    id<MKMID> receiver = [iMsg receiver];
    
    //
    //  1. get message key with direction (sender -> receiver) or (sender -> group)
    //
    id<MKSymmetricKey> password = [messenger encryptKeyForMessage:iMsg];
    NSAssert(password, @"failed to get msg key: %@ => %@, %@", iMsg.sender, receiver, [iMsg objectForKey:@"group"]);
    
    //
    //  2. encrypt 'content' to 'data' for receiver/group members
    //
    if ([receiver isGroup]) {
        // group message
        NSArray<id<MKMID>> *members = [facebook getMembers:receiver];
        NSAssert([members count] > 0, @"group not ready: %@", receiver);
        // a station will never send group message, so here must be a client;
        // the client messenger should check the group's meta & members before encrypting,
        // so we can trust that the group members MUST exist here.
        sMsg = [_instantPacker encryptMessage:iMsg withKey:password forMembers:members];
    } else {
        // personal message (or split group message)
        sMsg = [_instantPacker encryptMessage:iMsg withKey:password];
    }
    if (!sMsg) {
        // public key for encryption not found
        NSAssert(false, @"failed to encrypt message: %@ => %@, %@", iMsg.sender, receiver, [iMsg objectForKey:@"group"]);
        // TODO: suspend this message for waiting receiver's meta
        return nil;
    }
    
    // NOTICE: copy content type to envelope
    //         this help the intermediate nodes to recognize message type
    sMsg.envelope.type = iMsg.content.type;
    
    // OK
    return sMsg;
}

// Override
- (nullable id<DKDReliableMessage>)signMessage:(id<DKDSecureMessage>)sMsg {
    NSAssert([sMsg.data length] > 0, @"message data cannot be empty: %@ => %@, %@", sMsg.sender, sMsg.receiver, [sMsg objectForKey:@"group"]);
    // sign 'data' by sender
    return [_securePacker signMessage:sMsg];
}

//// Override
//- (nullable NSData *)serializeMessage:(id<DKDReliableMessage>)rMsg {
//    NSDictionary *info = [rMsg dictionary];
//    id<DIMCompressor> compressor = [self compressor];
//    return [compressor compressReliableMessage:info];
//}

//
//  Data -> ReliableMessage -> SecureMessage -> InstantMessage
//

//// Override
//- (nullable id<DKDReliableMessage>)deserializeMessage:(NSData *)data {
//    id<DIMCompressor> compressor = [self compressor];
//    NSDictionary *dict = [compressor extractReliableMessage:data];
//    return DKDReliableMessageParse(dict);
//}

// Override
- (id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg {
    // make sure sender's meta exists before verifying message
    if ([self checkAttachments:rMsg]) {
        // meta/visa ok
    } else {
        return nil;
    }
    
    NSAssert([rMsg.signature length] > 0, @"message signature cannot be empty: %@ => %@, %@", rMsg.sender, rMsg.receiver, [rMsg objectForKey:@"group"]);
    // verify 'data' with 'signature'
    return [_reliablePacker verifyMessage:rMsg];
}

// Override
- (id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg {
    // TODO: check receiver before calling this, make sure you are the receiver,
    //       or you are a member of the group when this is a group message,
    //       so that you will have a private key (decrypt key) to decrypt it.
    id<MKMID> receiver = [sMsg receiver];
    id<MKMID> me = [self.facebook selectLocalUser:receiver];
    if (!me) {
        // not for you?
        NSAssert(false, @"receiver error: %@", receiver);
        return nil;
    }
    NSAssert(sMsg.data, @"message data cannot be empty: %@ => %@, %@", sMsg.sender, sMsg.receiver, [sMsg objectForKey:@"group"]);
    // decrypt 'data' to 'content'
    return [_securePacker decryptMessage:sMsg forReceiver:me];
    
    // TODO: check top-secret message
    //       (do it by application)
}

@end

@implementation DIMMessagePacker (Attachments)

- (BOOL)checkAttachments:(id<DKDReliableMessage>)rMsg {
    id<DIMArchivist> archivist = [self archivist];
    NSAssert(archivist, @"archivist not ready");
    id<MKMID> sender = [rMsg sender];
    // [Meta Protocol]
    id<MKMMeta> meta = DIMMessageGetMeta(rMsg);
    if (meta) {
        [archivist saveMeta:meta withIdentifier:sender];
    }
    // [Visa Protocol]
    id<MKMVisa> visa = DIMMessageGetVisa(rMsg);
    if (visa) {
        [archivist saveDocument:visa];
    }
    //
    //  TODO: check [Visa Protocol] before calling this
    //        make sure the sender's meta(visa) exists
    //        (do it by application)
    //
    return YES;
}

@end
