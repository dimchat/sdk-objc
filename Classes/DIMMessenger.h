// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2019 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2019 Albert Moky
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
//  DIMMessenger.h
//  DIMSDK
//
//  Created by Albert Moky on 2019/8/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DIMCipherKeyDelegate <NSObject>

/**
 *  Get cipher key for encrypt message from 'sender' to 'receiver'
 *
 * @param from   - from where (user or contact ID)
 * @param to     - to where (contact or user/group ID)
 * @param create - generate when key not exists
 * @return cipher key
 */
- (nullable id<MKMSymmetricKey>)cipherKeyWithSender:(id<MKMID>)from
                                           receiver:(id<MKMID>)to
                                           generate:(BOOL)create;

/**
 *  Cache cipher key for reusing, with the direction (from 'sender' to 'receiver')
 *
 * @param from - from where (user or contact ID)
 * @param to   - to where (contact or user/group ID)
 * @param key  - cipher key
 */
- (void)cacheCipherKey:(id<MKMSymmetricKey>)key
            withSender:(id<MKMID>)from
              receiver:(id<MKMID>)to;

@end

@interface DIMCipherKeyDelegate : NSObject <DIMCipherKeyDelegate>

/*  Situations:
                  +-------------+-------------+-------------+-------------+
                  |  receiver   |  receiver   |  receiver   |  receiver   |
                  |     is      |     is      |     is      |     is      |
                  |             |             |  broadcast  |  broadcast  |
                  |    user     |    group    |    user     |    group    |
    +-------------+-------------+-------------+-------------+-------------+
    |             |      A      |             |             |             |
    |             +-------------+-------------+-------------+-------------+
    |    group    |             |      B      |             |             |
    |     is      |-------------+-------------+-------------+-------------+
    |    null     |             |             |      C      |             |
    |             +-------------+-------------+-------------+-------------+
    |             |             |             |             |      D      |
    +-------------+-------------+-------------+-------------+-------------+
    |             |      E      |             |             |             |
    |             +-------------+-------------+-------------+-------------+
    |    group    |             |             |             |             |
    |     is      |-------------+-------------+-------------+-------------+
    |  broadcast  |             |             |      F      |             |
    |             +-------------+-------------+-------------+-------------+
    |             |             |             |             |      G      |
    +-------------+-------------+-------------+-------------+-------------+
    |             |      H      |             |             |             |
    |             +-------------+-------------+-------------+-------------+
    |    group    |             |      J      |             |             |
    |     is      |-------------+-------------+-------------+-------------+
    |    normal   |             |             |      K      |             |
    |             +-------------+-------------+-------------+-------------+
    |             |             |             |             |             |
    +-------------+-------------+-------------+-------------+-------------+
 */

/**
 *  get destination for cipher key vector: (sender, dest)
 */
+ (id<MKMID>)destinationOfMessage:(id<DKDMessage>)msg;

+ (id<MKMID>)destinationToReceiver:(id<MKMID>)receiver orGroup:(nullable id<MKMID>)group;

@end

#pragma mark -

@interface DIMMessenger : DIMTransceiver <DIMPacker, DIMProcessor>

/**
 *  Delegate for getting message key
 */
@property(nonatomic, readonly) __kindof id<DIMCipherKeyDelegate> keyCache;

/**
 *  Delegate for parsing message
 */
@property(nonatomic, readonly) __kindof id<DIMPacker> packer;

/**
 *  Delegate for processing message
 */
@property(nonatomic, readonly) __kindof id<DIMProcessor> processor;

@end

@interface DIMMessenger (CipherKey)

- (nullable id<MKMSymmetricKey>)encryptKeyForMessage:(id<DKDInstantMessage>)iMsg;

- (nullable id<MKMSymmetricKey>)decryptKeyForMessage:(id<DKDSecureMessage>)sMsg;

- (void)cacheDecryptKey:(id<MKMSymmetricKey>)password forMessage:(id<DKDSecureMessage>)sMsg;

@end

NS_ASSUME_NONNULL_END
