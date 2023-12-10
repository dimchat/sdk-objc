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
//  DIMReliableMessagePacker.h
//  DIMCore
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMReliableMessagePacker : NSObject

@property (readonly, weak, nonatomic) id<DKDReliableMessageDelegate> delegate;

- (instancetype)initWithDelegate:(id<DKDReliableMessageDelegate>)delegate
NS_DESIGNATED_INITIALIZER;

@end

/*
 *  Verify the Reliable Message to Secure Message
 *
 *    +----------+      +----------+
 *    | sender   |      | sender   |
 *    | receiver |      | receiver |
 *    | time     |  ->  | time     |
 *    |          |      |          |
 *    | data     |      | data     |  1. verify(data, signature, sender.PK)
 *    | key/keys |      | key/keys |
 *    | signature|      +----------+
 *    +----------+
 */
@interface DIMReliableMessagePacker (Verification)

/**
 *  Verify 'data' and 'signature' field with sender's public key
 *
 * @param rMsg - received message
 * @return SecureMessage object
 */
- (nullable id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg;

@end

#ifdef __cplusplus
extern "C" {
#endif

#pragma mark MessageHelper

/**
 *  Sender's Meta
 *  ~~~~~~~~~~~~~
 *  Extends for the first message package of 'Handshake' protocol.
 */
id<MKMMeta> DIMMessageGetMeta(id<DKDReliableMessage> rMsg);
void DIMMessageSetMeta(id<MKMMeta> meta, id<DKDReliableMessage> rMsg);

/**
 *  Sender's Visa
 *  ~~~~~~~~~~~~~
 *  Extends for the first message package of 'Handshake' protocol.
 */
id<MKMVisa> DIMMessageGetVisa(id<DKDReliableMessage> rMsg);
void DIMMessageSetVisa(id<MKMVisa> visa, id<DKDReliableMessage> rMsg);

#ifdef __cplusplus
} /* end of extern "C" */
#endif

NS_ASSUME_NONNULL_END
