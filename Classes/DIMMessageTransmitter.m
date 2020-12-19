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
//  DIMMessageTransmitter.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/19.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "DKDInstantMessage+Extension.h"

#import "DIMFacebook.h"

#import "DIMMessageTransmitter.h"

@interface DIMMessageTransmitter ()

@property (weak, nonatomic) DIMFacebook *facebook;
@property (weak, nonatomic) DIMMessenger *messenger;
@property (weak, nonatomic) DIMPacker *packer;

@end

@implementation DIMMessageTransmitter

- (instancetype)initWithFacebook:(DIMFacebook *)barrack
                       messenger:(DIMMessenger *)transceiver
                          packer:(DIMPacker *)messagePacker {
    if (self = [super init]) {
        self.facebook = barrack;
        self.messenger = transceiver;
        self.packer = messagePacker;
    }
    return self;
}

- (BOOL)sendContent:(id<DKDContent>)content receiver:(id<MKMID>)receiver callback:(nullable DIMMessengerCallback)callback priority:(NSInteger)prior {
    
    // Application Layer should make sure user is already login before it send message to server.
    // Application layer should put message into queue so that it will send automatically after user login
    MKMUser *user = [self.facebook currentUser];
    NSAssert(user, @"current user not found");
    /*
    if ([receiver isGroup]) {
        if (content.group) {
            NSAssert([receiver isEqual:content.group], @"group ID not match: %@, %@", receiver, content);
        } else {
            content.group = receiver;
        }
    }
     */
    id<DKDEnvelope> env = DKDEnvelopeCreate(user.ID, receiver, nil);
    id<DKDInstantMessage> iMsg = DKDInstantMessageCreate(env, content);
    return [self sendInstantMessage:iMsg callback:callback priority:prior];
}

- (BOOL)sendInstantMessage:(id<DKDInstantMessage>)iMsg callback:(nullable DIMMessengerCallback)callback priority:(NSInteger)prior {
    
    // Send message (secured + certified) to target station
    id<DKDSecureMessage> sMsg = [self.packer encryptMessage:iMsg];
    if (!sMsg) {
        // public key not found?
        NSAssert(false, @"failed to encrypt message: %@", iMsg);
        return NO;
    }
    id<DKDReliableMessage> rMsg = [self.packer signMessage:sMsg];
    if (!rMsg) {
        NSAssert(false, @"failed to sign message: %@", sMsg);
        DKDContent *content = iMsg.content;
        content.state = DIMMessageState_Error;
        content.error = @"Encryption failed.";
        return NO;
    }
    
    BOOL OK = [self sendReliableMessage:rMsg callback:callback priority:prior];
    // sending status
    if (OK) {
        DKDContent *content = iMsg.content;
        content.state = DIMMessageState_Sending;
    } else {
        NSLog(@"cannot send message now, put in waiting queue: %@", iMsg);
        DKDContent *content = iMsg.content;
        content.state = DIMMessageState_Waiting;
    }
    
    if (![self.messenger saveMessage:iMsg]) {
        return NO;
    }
    return OK;
}

- (BOOL)sendReliableMessage:(id<DKDReliableMessage>)rMsg callback:(nullable DIMMessengerCallback)callback priority:(NSInteger)prior {
    
    DIMMessengerCompletionHandler handler = ^(NSError * _Nullable error) {
        !callback ?: callback(rMsg, error);
    };
    NSData *data = [self.messenger serializeMessage:rMsg];
    return [self.messenger sendPackageData:data completionHandler:handler priority:prior];
}

@end
