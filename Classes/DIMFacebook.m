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
#import "DIMRobot.h"

#import "DIMFacebook.h"

@interface DIMFacebook ()

@end

@implementation DIMFacebook

- (BOOL)saveMeta:(id<MKMMeta>)meta forID:(id<MKMID>)ID {
    NSAssert(false, @"implement me!");
    return NO;
}

- (BOOL)saveDocument:(id<MKMDocument>)doc {
    NSAssert(false, @"implement me!");
    return NO;
}

- (BOOL)checkDocument:(id<MKMDocument>)doc {
    id<MKMID> ID = doc.ID;
    NSAssert(ID, @"ID error: %@", doc);
    // NOTICE: if this is a bulletin document for group,
    //             verify it with the group owner's meta.key
    //         else (this is a visa document for user)
    //             verify it with the user's meta.key
    id<MKMMeta> meta;
    if (MKMIDIsGroup(ID)) {
        id<MKMID> owner = [self ownerOfGroup:ID];
        if (owner) {
            // check by owner's meta.key
            meta = [self metaForID:owner];
        } else if (ID.type == MKMEntityType_Group) {
            // NOTICE: if this is a polylogue document
            //             verify it with the founder's meta.key
            //             (which equals to the group's meta.key)
            meta = [self metaForID:ID];
        } else {
            // FIXME: owner not found for this group
            return NO;
        }
    } else {
        NSAssert(MKMIDIsUser(ID), @"document ID error: %@", ID);
        meta = [self metaForID:ID];
    }
    return meta && [doc verify:meta.key];
}

- (nullable id<MKMUser>)createUser:(id<MKMID>)ID {
    // TODO: make sure visa key exists before calling this
    NSAssert(MKMIDIsBroadcast(ID) || [self publicKeyForEncryption:ID],
             @"visa key not found for user: %@", ID);
    MKMEntityType type = ID.type;
    // check user type
    if (type == MKMEntityType_Station) {
        return [[DIMStation alloc] initWithID:ID];
    } else if (type == MKMEntityType_Bot) {
        return [[DIMBot alloc] initWithID:ID];
    }
    // general user, or 'anyone@anywhere'
    return [[DIMUser alloc] initWithID:ID];
}

- (nullable id<MKMGroup>)createGroup:(id<MKMID>)ID {
    // TODO: make group meta exists before calling this
    NSAssert(MKMIDIsBroadcast(ID) || [self metaForID:ID],
             @"failed to get meta for group: %@", ID);
    MKMEntityType type = ID.type;
    // check group type
    if (type == MKMEntityType_ISP) {
        return [[DIMServiceProvider alloc] initWithID:ID];
    }
    // general group, or 'everyone@everywhere'
    return [[DIMGroup alloc] initWithID:ID];
}

- (nullable NSArray<id<MKMUser>> *)localUsers {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable id<MKMUser>)selectLocalUserWithID:(id<MKMID>)receiver {
    NSArray<id<MKMUser>> *users = self.localUsers;
    if ([users count] == 0) {
        NSAssert(false, @"local users should not be empty");
        return nil;
    } else if (MKMIDIsBroadcast(receiver)) {
        // broadcast message can decrypt by anyone, so just return current user
        return [users firstObject];
    } else if (MKMIDIsUser(receiver)) {
        // 1. personal message
        // 2. split group message
        for (id<MKMUser> item in users) {
            if ([receiver isEqual:item.ID]) {
                // DISCUSS: set this item to be current user?
                return item;
            }
        }
        //NSAssert(false, @"receiver not in local users: %@, %@", receiver, users);
        return nil;
    }
    // group message (recipient not designated)
    NSAssert(MKMIDIsGroup(receiver), @"receiver error: %@", receiver);
    // the messenger will check group info before decrypting message,
    // so we can trust that the group's meta & members MUST exist here.
    id<MKMGroup> grp = [self groupWithID:receiver];
    NSAssert(grp, @"group not ready: %@", receiver);
    NSArray<id<MKMID>> *members = [grp members];
    NSAssert([members count] > 0, @"members not found: %@", receiver);
    for (id<MKMUser> item in users) {
        if ([members containsObject:item.ID]) {
            // DISCUSS: set this item to be current user?
            return item;
        }
    }
    //NSAssert(false, @"receiver not in local users: %@, %@", receiver, users);
    return nil;
}

@end

@implementation DIMFacebook (Thanos)

@end
