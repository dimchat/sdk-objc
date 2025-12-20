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
//  DIMFacebook.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/6/26.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMFacebook.h"

@implementation DIMFacebook

- (nullable id<DIMBarrack>)barrack {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable id<DIMArchivist>)archivist {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable id<MKMID>)selectLocalUserForID:(id<MKMID>)receiver {
    id<DIMArchivist> archivist = [self archivist];
    NSAssert(archivist, @"archivist not ready");
    NSArray<id<MKMID>> *localUsers = [archivist localUsers];
    //
    //  1.
    //
    if ([localUsers count] == 0) {
        NSAssert(false, @"local users should not be empty");
        return nil;
    } else if ([receiver isBroadcast]) {
        // broadcast message can decrypt by anyone,
        // so just return current user
        return [localUsers firstObject];
    }
    //
    //  2.
    //
    if ([receiver isUser]) {
        // personal message
        for (id<MKMID> item in localUsers) {
            if ([receiver isEqual:item]) {
                // DISCUSS: set this item to be current user?
                return item;
            }
        }
    } else if ([receiver isGroup]) {
        // group message (recipient not designated)
        //
        // the messenger will check group info before decrypting message,
        // so we can trust that the group's meta & members MUST exist here.
        NSArray<id<MKMID>> *members = [self membersOfGroup:receiver];
        if ([members count] == 0) {
            NSAssert(false, @"members not found: %@", receiver);
            return nil;
        }
        for (id<MKMID> item in localUsers) {
            if ([members containsObject:item]) {
                // DISCUSS: set this item to be current user?
                return item;
            }
        }
    } else {
        NSAssert(false, @"receiver error: %@", receiver);
    }
    //NSAssert(false, @"receiver not in local users: %@, %@", receiver, users);
    return nil;
}

//
//  Entity Delegate
//

// Override
- (nullable id<MKMUser>)userForID:(id<MKMID>)uid {
    NSAssert([uid isUser], @"user ID error: %@", uid);
    id<DIMBarrack> barrack = [self barrack];
    NSAssert(barrack, @"barrack not ready");
    //
    //  1. get from user cache
    //
    id<MKMUser> user = [barrack userForID:uid];
    if (user) {
        return user;
    }
    //
    //  2. check visa key
    //
    if ([uid isBroadcast]) {
        // no need to check visa key for broadcast user
    } else {
        id<MKEncryptKey> visaKey = [self publicKeyForEncryption:uid];
        if (!visaKey) {
            NSAssert(false, @"visa.key not found: %@", uid);
            return nil;
        }
        // NOTICE: if visa.key exists, then visa & meta must exist too.
    }
    //
    //  3. create user and cache it
    //
    user = [barrack createUserForID:uid];
    if (user) {
        [barrack cacheUser:user];
    }
    return user;
}

// Override
- (nullable id<MKMGroup>)groupForID:(id<MKMID>)gid {
    NSAssert([gid isGroup], @"user ID error: %@", gid);
    id<DIMBarrack> barrack = [self barrack];
    NSAssert(barrack, @"barrack not ready");
    //
    //  1. get from group cache
    //
    id<MKMGroup> group = [barrack groupForID:gid];
    if (group) {
        return group;
    }
    //
    //  2. check members
    //
    if ([gid isBroadcast]) {
        // no need to check members for broadcast group
    } else {
        NSArray<id<MKMID>> *members = [self membersOfGroup:gid];
        if ([members count] == 0) {
            NSAssert(false, @"group members not found: %@", gid);
            return nil;
        }
        // NOTICE: if members exist, then owner (founder) must exist,
        //         and bulletin & meta must exist too.
    }
    //
    //  3. create group and cache it
    //
    group = [barrack createGroupForID:gid];
    if (group) {
        [barrack cacheGroup:group];
    }
    return group;
}

//
//  Entity DataSource
//

// Override
- (nullable id<MKMMeta>)metaForID:(id<MKMID>)did {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (NSArray<id<MKMDocument>> *)documentsForID:(id<MKMID>)did {
    NSAssert(false, @"implement me!");
    return nil;
}

//
//  User DataSource
//

// Override
- (NSArray<id<MKMID>> *)contactsOfUser:(id<MKMID>)user {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (nullable id<MKEncryptKey>)publicKeyForEncryption:(id<MKMID>)user {
    NSAssert([user isUser], @"user ID error: %@", user);
    id<DIMArchivist> archivist = [self archivist];
    NSAssert(archivist, @"archivist not ready");
    //
    //  1. get public key from visa
    //
    id<MKEncryptKey> visaKey = [archivist visaKeyForID:user];
    if (visaKey) {
        // if visa.key exists, use it for encryption
        return visaKey;
    }
    //
    //  2. get key from meta
    //
    __kindof id<MKVerifyKey> metaKey = [archivist metaKeyForID:user];
    if ([metaKey conformsToProtocol:@protocol(MKEncryptKey)]) {
        // if visa.key not exists and meta.key is encrypt key,
        // use it for encryption
        return metaKey;
    }
    //NSAssert(false, @"failed to get encrypt key for user: %@", user);
    return nil;
}

// Override
- (NSArray<id<MKVerifyKey>> *)publicKeysForVerification:(id<MKMID>)user {
    NSAssert([user isUser], @"user ID error: %@", user);
    id<DIMArchivist> archivist = [self archivist];
    NSAssert(archivist, @"archivist not ready");
    NSMutableArray<id<MKVerifyKey>> *mKeys = [[NSMutableArray alloc] init];
    //
    //  1. get pubic key from visa
    //
    __kindof id<MKEncryptKey> visaKey = [archivist visaKeyForID:user];
    if ([visaKey conformsToProtocol:@protocol(MKVerifyKey)]) {
        // the sender may use communication key to sign message.data,
        // so try to verify it with visa.key first
        [mKeys addObject:visaKey];
    }
    //
    //  2. get key from meta
    //
    id<MKVerifyKey> metaKey = [archivist metaKeyForID:user];
    if (metaKey) {
        // the sender may use identity key to sign message.data,
        // try to verify it with meta.key too
        [mKeys addObject:metaKey];
    }
    NSAssert([mKeys count] > 0, @"failed to get verify key for user: %@", user);
    return mKeys;
}

// Override
- (NSArray<id<MKDecryptKey>> *)privateKeysForDecryption:(id<MKMID>)user {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (nullable id<MKSignKey>)privateKeyForSignature:(id<MKMID>)user {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (nullable id<MKSignKey>)privateKeyForVisaSignature:(id<MKMID>)user {
    NSAssert(false, @"implement me!");
    return nil;
}

//
//  Group DataSource
//

// Override
- (nullable id<MKMID>)founderOfGroup:(id<MKMID>)group {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (nullable id<MKMID>)ownerOfGroup:(id<MKMID>)group {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (NSArray<id<MKMID>> *)membersOfGroup:(id<MKMID>)group {
    NSAssert(false, @"implement me!");
    return nil;
}

@end
