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

#import "DIMServiceProvider.h"
#import "DIMStation.h"
#import "DIMBot.h"

#import "DIMFacebook.h"

@implementation DIMFacebook

- (nullable DIMBarrack *)barrack {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable id<DIMArchivist>)archivist {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable id<MKMID>)selectLocalUser:(id<MKMID>)receiver {
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
        NSArray<id<MKMID>> *members = [self getMembers:receiver];
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
- (nullable id<MKMUser>)getUser:(id<MKMID>)ID {
    NSAssert([ID isUser], @"user ID error: %@", ID);
    DIMBarrack *barrack = [self barrack];
    NSAssert(barrack, @"barrack not ready");
    //
    //  1. get from user cache
    //
    id<MKMUser> user = [barrack getUser:ID];
    if (user) {
        return user;
    }
    //
    //  2. check visa key
    //
    if ([ID isBroadcast]) {
        // no need to check visa key for broadcast user
    } else {
        id<MKEncryptKey> visaKey = [self getPublicKeyForEncryption:ID];
        if (!visaKey) {
            NSAssert(false, @"visa.key not found: %@", ID);
            return nil;
        }
        // NOTICE: if visa.key exists, then visa & meta must exist too.
    }
    //
    //  3. create user and cache it
    //
    user = [barrack createUser:ID];
    if (user) {
        [barrack cacheUser:user];
    }
    return user;
}

// Override
- (nullable id<MKMGroup>)getGroup:(id<MKMID>)ID {
    NSAssert([ID isGroup], @"user ID error: %@", ID);
    DIMBarrack *barrack = [self barrack];
    NSAssert(barrack, @"barrack not ready");
    //
    //  1. get from group cache
    //
    id<MKMGroup> group = [barrack getGroup:ID];
    if (group) {
        return group;
    }
    //
    //  2. check members
    //
    if ([ID isBroadcast]) {
        // no need to check members for broadcast group
    } else {
        NSArray<id<MKMID>> *members = [self getMembers:ID];
        if ([members count] == 0) {
            NSAssert(false, @"group members not found: %@", ID);
            return nil;
        }
        // NOTICE: if members exist, then owner (founder) must exist,
        //         and bulletin & meta must exist too.
    }
    //
    //  3. create group and cache it
    //
    group = [barrack createGroup:ID];
    if (group) {
        [barrack cacheGroup:group];
    }
    return group;
}

//
//  Entity DataSource
//

// Override
- (nullable id<MKMMeta>)getMeta:(id<MKMID>)ID {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (NSArray<id<MKMDocument>> *)getDocuments:(id<MKMID>)ID {
    NSAssert(false, @"implement me!");
    return nil;
}

//
//  User DataSource
//

// Override
- (NSArray<id<MKMID>> *)getContacts:(id<MKMID>)user {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (nullable id<MKEncryptKey>)getPublicKeyForEncryption:(id<MKMID>)user {
    NSAssert([user isUser], @"user ID error: %@", user);
    id<DIMArchivist> archivist = [self archivist];
    NSAssert(archivist, @"archivist not ready");
    //
    //  1. get public key from visa
    //
    id<MKEncryptKey> visaKey = [archivist getVisaKey:user];
    if (visaKey) {
        // if visa.key exists, use it for encryption
        return visaKey;
    }
    //
    //  2. get key from meta
    //
    __kindof id<MKVerifyKey> metaKey = [archivist getMetaKey:user];
    if ([metaKey conformsToProtocol:@protocol(MKEncryptKey)]) {
        // if visa.key not exists and meta.key is encrypt key,
        // use it for encryption
        return metaKey;
    }
    //NSAssert(false, @"failed to get encrypt key for user: %@", user);
    return nil;
}

// Override
- (NSArray<id<MKVerifyKey>> *)getPublicKeysForVerification:(id<MKMID>)user {
    NSAssert([user isUser], @"user ID error: %@", user);
    id<DIMArchivist> archivist = [self archivist];
    NSAssert(archivist, @"archivist not ready");
    NSMutableArray<id<MKVerifyKey>> *mKeys = [[NSMutableArray alloc] init];
    //
    //  1. get pubic key from visa
    //
    __kindof id<MKEncryptKey> visaKey = [archivist getVisaKey:user];
    if ([visaKey conformsToProtocol:@protocol(MKVerifyKey)]) {
        // the sender may use communication key to sign message.data,
        // so try to verify it with visa.key first
        [mKeys addObject:visaKey];
    }
    //
    //  2. get key from meta
    //
    id<MKVerifyKey> metaKey = [archivist getMetaKey:user];
    if (metaKey) {
        // the sender may use identity key to sign message.data,
        // try to verify it with meta.key too
        [mKeys addObject:metaKey];
    }
    NSAssert([mKeys count] > 0, @"failed to get verify key for user: %@", user);
    return mKeys;
}

// Override
- (NSArray<id<MKDecryptKey>> *)getPrivateKeysForDecryption:(id<MKMID>)user {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (nullable id<MKSignKey>)getPrivateKeyForSignature:(id<MKMID>)user {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (nullable id<MKSignKey>)getPrivateKeyForVisaSignature:(id<MKMID>)user {
    NSAssert(false, @"implement me!");
    return nil;
}

//
//  Group DataSource
//

// Override
- (nullable id<MKMID>)getFounder:(id<MKMID>)group {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (nullable id<MKMID>)getOwner:(id<MKMID>)group {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (NSArray<id<MKMID>> *)getMembers:(id<MKMID>)group {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (NSArray<id<MKMID>> *)getAssistants:(id<MKMID>)group {
    NSAssert(false, @"implement me!");
    return nil;
}

@end
