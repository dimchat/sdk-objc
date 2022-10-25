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
//  DIMClient
//
//  Created by Albert Moky on 2019/6/26.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "MKMPlugins.h"

#import "DIMServiceProvider.h"
#import "DIMStation.h"
#import "DIMRobot.h"

#import "DIMFacebook.h"

/**
 *  Remove 1/2 objects from the dictionary
 *
 * @param mDict - mutable dictionary
 */
static inline NSInteger thanos(NSMutableDictionary *mDict, NSInteger finger) {
    NSArray *keys = [mDict allKeys];
    for (id addr in keys) {
        if ((++finger & 1) == 1) {
            // kill it
            [mDict removeObjectForKey:addr];
        }
        // let it go
    }
    return finger;
}

@interface DIMFacebook () {
    
    NSMutableDictionary<id<MKMID>, id<DIMUser>> *_userTable;
    NSMutableDictionary<id<MKMID>, id<DIMGroup>> *_groupTable;
}

@end

@implementation DIMFacebook

- (instancetype)init {
    if (self = [super init]) {
        _userTable = [[NSMutableDictionary alloc] init];
        _groupTable = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSInteger)reduceMemory {
    NSInteger finger = 0;
    finger = thanos(_userTable, finger);
    finger = thanos(_groupTable, finger);
    return finger >> 1;
}

- (void)cacheUser:(id<DIMUser>)user {
    if (user.dataSource == nil) {
        user.dataSource = self;
    }
    [_userTable setObject:user forKey:user.ID];
}

- (void)cacheGroup:(id<DIMGroup>)group {
    if (group.dataSource == nil) {
        group.dataSource = self;
    }
    [_groupTable setObject:group forKey:group.ID];
}

- (BOOL)saveMeta:(id<MKMMeta>)meta forID:(id<MKMID>)ID {
    NSAssert(false, @"implement me!");
    return NO;
}

- (BOOL)saveDocument:(id<MKMDocument>)doc {
    NSAssert(false, @"implement me!");
    return NO;
}

- (BOOL)saveMembers:(NSArray<id<MKMID>> *)members group:(id<MKMID>)ID {
    NSAssert(false, @"implement me!");
    return NO;
}

- (BOOL)checkDocument:(id<MKMDocument>)doc {
    id<MKMID> ID = doc.ID;
    if (!ID) {
        NSAssert(false, @"ID error: %@", doc);
        return NO;
    }
    // NOTICE: if this is a group profile,
    //             verify it with each member's meta.key
    //         else (this is a user profile)
    //             verify it with the user's meta.key
    id<MKMMeta> meta;
    if (MKMIDIsGroup(ID)) {
        // check by each member
        NSArray<id<MKMID>> *members = [self membersOfGroup:ID];
        for (id<MKMID> item in members) {
            meta = [self metaForID:item];
            if (!meta) {
                // FIXME: meta not found for this member
                continue;
            }
            if ([doc verify:meta.key]) {
                return YES;
            }
        }
        // DISCUSS: what to do about assistants?
        
        // check by owner
        id<MKMID> owner = [self ownerOfGroup:ID];
        if (!owner) {
            if (ID.type == MKMEntityType_Group) {
                // NOTICE: if this is a polylogue profile
                //             verify it with the founder's meta.key
                //             (which equals to the group's meta.key)
                meta = [self metaForID:ID];
            } else {
                // FIXME: owner not found for this group
                return NO;
            }
        } else if ([members containsObject:owner]) {
            // already checked
            return NO;
        } else {
            meta = [self metaForID:owner];
        }
    } else {
        NSAssert(MKMIDIsUser(ID), @"document ID error: %@", ID);
        meta = [self metaForID:ID];
    }
    return [doc verify:meta.key];
}

- (nullable id<DIMUser>)createUser:(id<MKMID>)ID {
    if (MKMIDIsBroadcast(ID)) {
        // create user 'anyone@anywhere'
        return [[DIMUser alloc] initWithID:ID];
    }
    // make sure meta exists
    NSAssert([self metaForID:ID], @"meta not found for user: %@", ID);
    // NOTICE: make sure visa key exists before calling this
    MKMEntityType type = ID.type;
    // check user type
    if (type == MKMEntityType_Station) {
        return [[DIMStation alloc] initWithID:ID];
    } else if (type == MKMEntityType_Bot) {
        return [[DIMBot alloc] initWithID:ID];
    }
    //NSAssert(type == MKMEntityType_User, @"Unsupported user type: %d", type);
    return [[DIMUser alloc] initWithID:ID];
}

- (nullable id<DIMGroup>)createGroup:(id<MKMID>)ID {
    if (MKMIDIsBroadcast(ID)) {
        // create group 'everyone@everywhere'
        return [[DIMGroup alloc] initWithID:ID];
    }
    // make user meta exists
    NSAssert([self metaForID:ID], @"failed to get meta for group: %@", ID);
    MKMEntityType type = ID.type;
    // check group type
    if (type == MKMEntityType_ISP) {
        return [[DIMServiceProvider alloc] initWithID:ID];
    }
    //NSAssert(type == MKMEntityType_Group, @"Unsupported group type: %d", type);
    return [[DIMGroup alloc] initWithID:ID];
}

- (nullable NSArray<id<DIMUser>> *)localUsers {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable id<DIMUser>)currentUser {
    NSArray<id<DIMUser>> *users = self.localUsers;
    if ([users count] == 0) {
        return nil;
    }
    return [users firstObject];
}

- (nullable id<DIMUser>)selectLocalUserWithID:(id<MKMID>)receiver {
    NSArray<id<DIMUser>> *users = self.localUsers;
    if ([users count] == 0) {
        NSAssert(false, @"local users should not be empty");
        return nil;
    } else if (MKMIDIsBroadcast(receiver)) {
        // broadcast message can decrypt by anyone, so just return current user
        return [users firstObject];
    }
    if (MKMIDIsGroup(receiver)) {
        // group message (recipient not designated)
        NSArray<id<MKMID>> *members = [self membersOfGroup:receiver];
        if (members.count == 0) {
            // TODO: group not ready, waiting for group info
            return nil;
        }
        for (id<DIMUser> item in users) {
            if ([members containsObject:item.ID]) {
                // DISCUSS: set this item to be current user?
                return item;
            }
        }
    } else {
        // 1. personal message
        // 2. split group message
        for (id<DIMUser> item in users) {
            if ([receiver isEqual:item.ID]) {
                // DISCUSS: set this item to be current user?
                return item;
            }
        }
    }
    NSAssert(false, @"receiver not in local users: %@, %@", receiver, users);
    return nil;
}

#pragma mark - DIMEntityDelegate

- (nullable id<DIMUser>)userWithID:(id<MKMID>)ID {
    // 1. get from user cache
    id<DIMUser> user = [_userTable objectForKey:ID];
    if (!user) {
        // 2. create user and cache it
        user = [self createUser:ID];
        if (user) {
            [self cacheUser:user];
        }
    }
    return user;
}

- (nullable id<DIMGroup>)groupWithID:(id<MKMID>)ID {
    // 1. get from group cache
    id<DIMGroup> group = [_groupTable objectForKey:ID];
    if (!group) {
        // 2. create group and cache it
        group = [self createGroup:ID];
        if (group) {
            [self cacheGroup:group];
        }
    }
    return group;
}

@end

@implementation DIMFacebook (MemberShip)

- (BOOL)group:(id<MKMID>)group isFounder:(id<MKMID>)member {
    // check member's public key with group's meta.key
    id<MKMMeta> gMeta = [self metaForID:group];
    NSAssert(gMeta, @"failed to get meta for group: %@", group);
    id<MKMMeta> mMeta = [self metaForID:member];
    //NSAssert(mMeta, @"failed to get meta for member: %@", member);
    return MKMMetaMatchKey(mMeta.key, gMeta);
}

- (BOOL)group:(id<MKMID>)group isOwner:(id<MKMID>)member {
    if (group.type == MKMEntityType_Group) {
        return [self group:group isFounder:member];
    }
    NSAssert(false, @"only Polylogue so far: %@", group);
    return NO;
}

@end

@implementation DIMFacebook (Plugins)

+ (void)loadPlugins {
    // load plugins
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [MKMPlugins registerIDFactory];
        [MKMPlugins registerAddressFactory];
        [MKMPlugins registerMetaFactory];
        [MKMPlugins registerDocumentFactory];
        
        [MKMPlugins registerKeyFactories];
        [MKMPlugins registerDataCoders];
        [MKMPlugins registerDigesters];
    });
}

@end
