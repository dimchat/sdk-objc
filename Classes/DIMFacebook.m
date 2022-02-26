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

#import "DIMPolylogue.h"
#import "DIMChatroom.h"

#import "DIMFacebook.h"

@implementation DIMFacebook

- (nullable DIMUser *)currentUser {
    NSArray<DIMUser *> *users = self.localUsers;
    if ([users count] == 0) {
        return nil;
    }
    return [users firstObject];
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
            if (ID.type == MKMNetwork_Polylogue) {
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

#pragma mark DIMBarrack

- (nullable DIMUser *)createUser:(id<MKMID>)ID {
    if (MKMIDIsBroadcast(ID)) {
        // create user 'anyone@anywhere'
        return [[DIMUser alloc] initWithID:ID];
    }
    NSAssert([self metaForID:ID], @"meta not found for user: %@", ID);
    // NOTICE: make sure visa key exists before calling this
    UInt8 type = ID.type;
    if (type == MKMNetwork_Main || type == MKMNetwork_BTCMain) {
        return [[DIMUser alloc] initWithID:ID];
    }
    if (type == MKMNetwork_Robot) {
        return [[DIMRobot alloc] initWithID:ID];
    }
    if (type == MKMNetwork_Station) {
        return [[DIMStation alloc] initWithID:ID];
    }
    NSAssert(false, @"Unsupported user type: %d", type);
    return nil;
}

- (nullable DIMGroup *)createGroup:(id<MKMID>)ID {
    if (MKMIDIsBroadcast(ID)) {
        // create group 'everyone@everywhere'
        return [[DIMGroup alloc] initWithID:ID];
    }
    NSAssert([self metaForID:ID], @"failed to get meta for group: %@", ID);
    UInt8 type = ID.type;
    if (type == MKMNetwork_Polylogue) {
        return [[DIMPolylogue alloc] initWithID:ID];
    }
    if (type == MKMNetwork_Chatroom) {
        return [[DIMChatroom alloc] initWithID:ID];
    }
    if (type == MKMNetwork_Provider) {
        return [[DIMServiceProvider alloc] initWithID:ID];
    }
    NSAssert(false, @"Unsupported group type: %d", type);
    return nil;
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
    if (group.type == MKMNetwork_Polylogue) {
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
        [MKMPlugins registerAddressFactory];
        [MKMPlugins registerMetaFactory];
        [MKMPlugins registerDocumentFactory];
        
        [MKMPlugins registerKeyFactories];
        [MKMPlugins registerDataCoders];
        [MKMPlugins registerDigesters];
    });
}

@end
