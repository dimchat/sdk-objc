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
//  DIMSecureMessagePacker.h
//  DIMCore
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMSecureMessagePacker : NSObject

@property (readonly, weak, nonatomic) id<DKDSecureMessageDelegate> delegate;

- (instancetype)initWithDelegate:(id<DKDSecureMessageDelegate>)delegate
NS_DESIGNATED_INITIALIZER;

@end

/*
 *  Decrypt the Secure Message to Instant Message
 *
 *    +----------+      +----------+
 *    | sender   |      | sender   |
 *    | receiver |      | receiver |
 *    | time     |  ->  | time     |
 *    |          |      |          |  1. PW      = decrypt(key, receiver.SK)
 *    | data     |      | content  |  2. content = decrypt(data, PW)
 *    | key/keys |      +----------+
 *    +----------+
 */
@interface DIMSecureMessagePacker (Decryption)

/**
 *  Decrypt message, replace encrypted 'data' with 'content' field
 *
 * @param sMsg     - encrypted message
 * @param receiver - actual receiver (local user)
 * @return InstantMessage object
 */
- (nullable id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg
                                     forReceiver:(id<MKMID>)receiver;

@end

/*
 *  Sign the Secure Message to Reliable Message
 *
 *    +----------+      +----------+
 *    | sender   |      | sender   |
 *    | receiver |      | receiver |
 *    | time     |  ->  | time     |
 *    |          |      |          |
 *    | data     |      | data     |
 *    | key/keys |      | key/keys |
 *    +----------+      | signature|  1. signature = sign(data, sender.SK)
 *                      +----------+
 */
@interface DIMSecureMessagePacker (Signature)

/**
 *  Sign message.data, add 'signature' field
 *
 * @param sMsg - encrypted message
 * @return ReliableMessage object
 */
- (id<DKDReliableMessage>)signMessage:(id<DKDSecureMessage>)sMsg;

@end

NS_ASSUME_NONNULL_END
