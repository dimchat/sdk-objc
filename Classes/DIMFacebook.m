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
    // not me?
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
    // get from user cache
    id<MKMUser> user = [barrack userForID:uid];
    if (!user) {
        // create user and cache it
        user = [barrack createUserForID:uid];
        if (user) {
            [barrack cacheUser:user];
        }
    }
    return user;
}

// Override
- (nullable id<MKMGroup>)groupForID:(id<MKMID>)gid {
    NSAssert([gid isGroup], @"user ID error: %@", gid);
    id<DIMBarrack> barrack = [self barrack];
    NSAssert(barrack, @"barrack not ready");
    // get from group cache
    id<MKMGroup> group = [barrack groupForID:gid];
    if (!group) {
        // create group and cache it
        group = [barrack createGroupForID:gid];
        if (group) {
            [barrack cacheGroup:group];
        }
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
