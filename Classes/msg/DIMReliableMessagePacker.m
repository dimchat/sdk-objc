// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2018 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2018 Albert Moky
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
//  DIMReliableMessagePacker.m
//  DIMCore
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DKDMessageDelegates.h"

#import "DIMReliableMessagePacker.h"

@interface DIMReliableMessagePacker ()

@property (weak, nonatomic) id<DKDReliableMessageDelegate> delegate;

@end

@implementation DIMReliableMessagePacker

- (instancetype)init {
    NSAssert(false, @"DON'T call me!");
    id<DKDReliableMessageDelegate> delegate = nil;
    return [self initWithDelegate:delegate];
}

/* designated initializer */
- (instancetype)initWithDelegate:(id<DKDReliableMessageDelegate>)messenger {
    if (self = [super init]) {
        self.delegate = messenger;
    }
    return self;
}

@end

@implementation DIMReliableMessagePacker (Verification)

- (nullable id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg {
    id<DKDReliableMessageDelegate> transceiver = [self delegate];
    if (!transceiver) {
        NSAssert(false, @"reliable message delegate not found");
        return nil;
    }
    
    //
    //  0. Decode 'message.data' to encrypted content data
    //
    NSData *ciphertext = [rMsg data];
    if ([ciphertext length] == 0) {
        NSAssert(false, @"failed to decode message data: %@ => %@, %@", rMsg.sender, rMsg.receiver, rMsg.group);
        return nil;
    }
    
    //
    //  1. Decode 'message.signature' from String (Base64)
    //
    NSData *signature = [rMsg signature];
    if ([signature length] == 0) {
        NSAssert(false, @"failed to decode message signature: %@ => %@, %@", rMsg.sender, rMsg.receiver, rMsg.group);
        return nil;
    }
    
    //
    //  2. Verify the message data and signature with sender's public key
    //
    BOOL ok = [transceiver message:rMsg
                        verifyData:ciphertext
                     withSignature:signature];
    if (!ok) {
        NSAssert(false, @"message signature not match: %@ => %@, %@", rMsg.sender, rMsg.receiver, rMsg.group);
        return nil;
    }
    
    // OK, pack message
    NSMutableDictionary *info = [rMsg copyDictionary:NO];
    [info removeObjectForKey:@"signature"];
    return DKDSecureMessageParse(info);
}

@end
