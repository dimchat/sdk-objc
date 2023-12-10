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
//  DIMInstantMessagePacker.h
//  DIMCore
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMInstantMessagePacker : NSObject

@property (readonly, weak, nonatomic) id<DKDInstantMessageDelegate> delegate;

- (instancetype)initWithDelegate:(id<DKDInstantMessageDelegate>)delegate
NS_DESIGNATED_INITIALIZER;

@end

/*
 *  Encrypt the Instant Message to Secure Message
 *
 *    +----------+      +----------+
 *    | sender   |      | sender   |
 *    | receiver |      | receiver |
 *    | time     |  ->  | time     |
 *    |          |      |          |
 *    | content  |      | data     |  1. data = encrypt(content, PW)
 *    +----------+      | key/keys |  2. key  = encrypt(PW, receiver.PK)
 *                      +----------+
 */
@interface DIMInstantMessagePacker (Encryption)

/**
 *  1. Encrypt personal message, replace 'content' field with encrypted 'data'
 *
 * @param iMsg     - plain message
 * @param password - symmetric key
 * @return SecureMessage object, null on visa not found
 */
- (nullable id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg
                                        withKey:(id<MKMSymmetricKey>)password;

/**
 *  2. Encrypt group message, replace 'content' field with encrypted 'data'
 *
 * @param iMsg     - plain message
 * @param password - symmetric key
 * @param members  - group members for group message
 * @return SecureMessage object, null on visa not found
 */
- (nullable id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg
                                        withKey:(id<MKMSymmetricKey>)password
                                     forMembers:(NSArray<id<MKMID>> *)members;

@end

NS_ASSUME_NONNULL_END
