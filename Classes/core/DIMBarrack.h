// license: https://mit-license.org
//
//  DIMP : Decentralized Instant Messaging Protocol
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
//  DIMBarrack.h
//  DIMCore
//
//  Created by Albert Moky on 2018/10/12.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Entity Factory
 *  ~~~~~~~~~~~~~~
 *  Entity pool to manage User/Group instances
 *
 *      1st, get instance here to avoid create same instance,
 *      2nd, if they were updated, we can refresh them immediately here
 */
@interface DIMBarrack : NSObject

- (void)cacheUser:(id<MKMUser>)user;
- (void)cacheGroup:(id<MKMGroup>)group;

- (nullable __kindof id<MKMUser>)getUser:(id<MKMID>)ID;
- (nullable __kindof id<MKMGroup>)getGroup:(id<MKMID>)ID;

/**
 *  Create user when visa.key exists
 *
 * @param ID - user ID
 * @return user, null on not ready
 */
- (nullable __kindof id<MKMUser>)createUser:(id<MKMID>)ID;

/**
 *  Create group when members exist
 *
 * @param ID - group ID
 * @return group, null on not ready
 */
- (nullable __kindof id<MKMGroup>)createGroup:(id<MKMID>)ID;

@end

@protocol DIMArchivist <NSObject>

/**
 *  Save meta for entity ID (must verify first)
 *
 * @param meta - entity meta
 * @param ID - entity ID
 * @return YES on success
 */
- (BOOL)saveMeta:(id<MKMMeta>)meta withIdentifier:(id<MKMID>)ID;

/**
 *  Save entity document with ID (must verify first)
 *
 * @param doc - entity document
 * @return YES on success
 */
- (BOOL)saveDocument:(id<MKMDocument>)doc;

//
//  Public Keys
//

/**
 *  Get meta.key
 *
 * @param ID - entity ID
 * @return nil on not found
 */
- (nullable __kindof id<MKVerifyKey>)getMetaKey:(id<MKMID>)ID;

/**
 *  Get visa.key
 *
 * @param ID - entity ID
 * @return nil on not found
 */
- (nullable __kindof id<MKEncryptKey>)getVisaKey:(id<MKMID>)ID;

//
//  Local Users
//

/**
 *  Get all local users (for decrypting received message)
 *
 * @return users with private key
 */
- (NSArray<id<MKMID>> *)localUsers;

@end

NS_ASSUME_NONNULL_END
