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

#import "NSObject+Singleton.h"

#import "MKMPlugins.h"

#import "DIMServiceProvider.h"
#import "DIMStation.h"
#import "DIMRobot.h"

#import "DIMPolylogue.h"
#import "DIMChatroom.h"

#import "DIMFacebook.h"

@implementation DIMFacebook

- (nullable MKMUser *)currentUser {
    NSArray<MKMUser *> *users = self.localUsers;
    if ([users count] == 0) {
        return nil;
    }
    return [users firstObject];
}

- (BOOL)isEmptyDocument:(id<MKMDocument>)doc {
    NSString *data = [doc objectForKey:@"data"];
    return data.length == 0;
}

- (BOOL)verifyDocument:(id<MKMDocument>)doc forID:(id<MKMID>)ID {
    if (![ID isEqual:doc.ID]) {
        // profile ID not match
        return NO;
    }
    return [self verifyDocument:doc];
}

- (BOOL)verifyDocument:(id<MKMDocument>)doc {
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
        for (id<MKMID>item in members) {
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
        NSAssert(MKMIDIsUser(ID), @"profile ID error: %@", ID);
        meta = [self metaForID:ID];
    }
    return [doc verify:meta.key];
}

#pragma mark DIMBarrack

- (nullable MKMUser *)createUser:(id<MKMID>)ID {
    if (MKMIDIsBroadcast(ID)) {
        // create user 'anyone@anywhere'
        return [[MKMUser alloc] initWithID:ID];
    }
    if (![self metaForID:ID]) {
        //NSAssert(false, @"failed to get meta for user: %@", ID);
        return nil;
    }
    MKMNetworkType type = ID.type;
    if (type == MKMNetwork_Main || type == MKMNetwork_BTCMain) {
        return [[MKMUser alloc] initWithID:ID];
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

- (nullable MKMGroup *)createGroup:(id<MKMID>)ID {
    if (MKMIDIsBroadcast(ID)) {
        // create group 'everyone@everywhere'
        return [[MKMGroup alloc] initWithID:ID];
    }
    if (![self metaForID:ID]) {
        //NSAssert(false, @"failed to get meta for group: %@", ID);
        return nil;
    }
    MKMNetworkType type = ID.type;
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

@implementation DIMFacebook (Storage)

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

@end

@implementation DIMFacebook (Plugins)

+ (void)loadPlugins {
    // load plugins
    SingletonDispatchOnce(^{
        
        [MKMPlugins registerAddressFactory];
        [MKMPlugins registerMetaFactory];
        [MKMPlugins registerDocumentFactory];
        
        [MKMPlugins registerKeyFactories];
        [MKMPlugins registerCoders];
        [MKMPlugins registerDigesters];
    });
}

@end
