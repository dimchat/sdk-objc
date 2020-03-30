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

#import "DIMServiceProvider.h"
#import "DIMStation.h"
#import "DIMRobot.h"

#import "DIMPolylogue.h"
#import "DIMChatroom.h"

#import "DIMAddressNameService.h"

#import "DIMFacebook.h"

@implementation DIMFacebook

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (nullable DIMID *)ansGet:(NSString *)name {
    return [_ans IDWithName:name];
}

- (nullable NSArray<DIMUser *> *)localUsers {
    NSAssert(false, @"override me!");
    return nil;
}

- (nullable DIMUser *)currentUser {
    NSArray<DIMUser *> *users = self.localUsers;
    if ([users count] == 0) {
        return nil;
    }
    return [users firstObject];
}

- (nullable DIMID *)IDWithAddress:(DIMAddress *)address {
    DIMID *ID = [[DIMID alloc] initWithAddress:address];
    DIMMeta *meta = [self metaForID:ID];
    if (!meta) {
        // failed to get meta for this ID
        return nil;
    }
    NSString *seed = [meta seed];
    if ([seed length] == 0) {
        return ID;
    }
    ID = [[DIMID alloc] initWithName:seed address:address];
    [self cacheID:ID];
    return ID;
}

#pragma mark DIMBarrack

- (nullable DIMID *)createID:(NSString *)string {
    // try ANS record
    DIMID *ID = [self ansGet:string];
    if (ID) {
        return ID;
    }
    return MKMIDFromString(string);
}

- (nullable DIMUser *)createUser:(DIMID *)ID {
    NSAssert([ID isUser], @"user ID error: %@", ID);
    if ([ID isBroadcast]) {
        // create user 'anyone@anywhere'
        return [[DIMUser alloc] initWithID:ID];
    }
    if (![self metaForID:ID]) {
        //NSAssert(false, @"failed to get meta for user: %@", ID);
        return nil;
    }
    MKMNetworkType type = ID.type;
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

- (nullable DIMGroup *)createGroup:(DIMID *)ID {
    NSAssert([ID isGroup], @"group ID error: %@", ID);
    if ([ID isBroadcast]) {
        // create group 'everyone@everywhere'
        return [[DIMGroup alloc] initWithID:ID];
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

#pragma mark - MKMEntityDataSource

- (nullable DIMMeta *)metaForID:(DIMID *)ID {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable __kindof DIMProfile *)profileForID:(MKMID *)ID {
    NSAssert(false, @"implement me!");
    return nil;
}

#pragma mark - MKMUserDataSource

- (nullable NSArray<DIMID *> *)contactsOfUser:(DIMID *)user {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable DIMPrivateKey *)privateKeyForSignature:(DIMID *)user {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable NSArray<DIMPrivateKey *> *)privateKeysForDecryption:(DIMID *)user {
    NSAssert(false, @"implement me!");
    return nil;
}

#pragma mark - MKMGroupDataSource

- (nullable DIMID *)founderOfGroup:(DIMID *)group {
    DIMID *founder = [super founderOfGroup:group];
    if (founder) {
        return founder;
    }
    // check each member's public key with group meta
    DIMMeta *gMeta = [self metaForID:group];
    if (!gMeta) {
        // FIXME: when group profile was arrived but the meta still on the way,
        //        here will cause founder not found.
        //NSAssert(false, @"failed to get group meta");
        return nil;
    }
    NSArray<DIMID *> *members = [self membersOfGroup:group];
    DIMMeta *mMeta;
    for (DIMID *item in members) {
        NSAssert([item isUser], @"member ID error: %@", item);
        mMeta = [self metaForID:item];
        if (!mMeta) {
            // failed to get member meta
            continue;
        }
        if ([mMeta matchPublicKey:gMeta.key]) {
            // got it!
            return item;
        }
    }
    // TODO: load founder from database
    return nil;
}

- (nullable DIMID *)ownerOfGroup:(DIMID *)group {
    DIMID *owner = [super ownerOfGroup:group];
    if (owner) {
        return owner;
    }
    // check group type
    if (group.type == MKMNetwork_Polylogue) {
        // Polylogue's owner is its founder
        return [self founderOfGroup:group];
    }
    // TODO: load owner from database
    return nil;
}

- (nullable NSArray<DIMID *> *)membersOfGroup:(DIMID *)group {
    NSAssert(false, @"implement me!");
    return nil;
}

@end

@implementation DIMFacebook (Storage)

#pragma mark Meta

- (BOOL)verifyMeta:(DIMMeta *)meta forID:(DIMID *)ID {
    NSAssert([meta isValid], @"meta error: %@", meta);
    return [meta matchID:ID];
}

- (BOOL)saveMeta:(DIMMeta *)meta forID:(DIMID *)ID {
    NSAssert(false, @"override me!");
    return NO;
}

#pragma mark Profile

- (BOOL)verifyProfile:(DIMProfile *)profile forID:(DIMID *)ID {
    if (![ID isEqual:profile.ID]) {
        // profile ID not match
        return NO;
    }
    return [self verifyProfile:profile];
}

- (BOOL)verifyProfile:(DIMProfile *)profile {
    DIMID *ID = [self IDWithString:profile.ID];
    if (![ID isValid]) {
        NSAssert(false, @"profile ID error: %@", profile);
        return NO;
    }
    // NOTICE: if this is a group profile,
    //             verify it with each member's meta.key
    //         else (this is a user profile)
    //             verify it with the user's meta.key
    DIMMeta *meta;
    if ([ID isGroup]) {
        // check by each member
        NSArray<DIMID *> *members = [self membersOfGroup:ID];
        for (DIMID *item in members) {
            meta = [self metaForID:item];
            if (!meta) {
                // FIXME: meta not found for this member
                continue;
            }
            if ([profile verify:meta.key]) {
                return YES;
            }
        }
        // DISCUSS: what to do about assistants?
        
        // check by owner
        DIMID *owner = [self ownerOfGroup:ID];
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
        NSAssert([ID isUser], @"profile ID error: %@", ID);
        meta = [self metaForID:ID];
    }
    return [profile verify:meta.key];
}

- (BOOL)saveProfile:(DIMProfile *)profile {
    NSAssert(false, @"override me!");
    return NO;
}

#pragma mark Group Members

- (BOOL)saveMembers:(NSArray<DIMID *> *)members group:(DIMID *)ID {
    NSAssert(false, @"override me!");
    return NO;
}

@end

@implementation DIMFacebook (Relationship)

- (BOOL)user:(DIMID *)user hasContact:(DIMID *)contact{
    NSArray<DIMID *> *contacts = [self contactsOfUser:user];
    return [contacts containsObject:contact];
}

#pragma mark -

- (BOOL)group:(DIMID *)group isFounder:(DIMID *)member {
    // check member's public key with group's meta.key
    DIMMeta *gMeta = [self metaForID:group];
    NSAssert(gMeta, @"failed to get meta for group: %@", group);
    DIMMeta *mMeta = [self metaForID:member];
    //NSAssert(mMeta, @"failed to get meta for member: %@", member);
    return [gMeta matchPublicKey:mMeta.key];
}

- (BOOL)group:(DIMID *)group isOwner:(DIMID *)member {
    if (group.type == MKMNetwork_Polylogue) {
        return [self group:group isFounder:member];
    }
    NSAssert(false, @"only Polylogue so far: %@", group);
    return NO;
}

- (BOOL)group:(DIMID *)group hasMember:(DIMID *)member {
    NSArray<DIMID *> *members = [self membersOfGroup:group];
    return [members containsObject:member];
}

#pragma mark Group Assistants

- (nullable NSArray<DIMID *> *)assistantsOfGroup:(DIMID *)group {
    NSAssert([group isGroup], @"group ID error: %@", group);
    DIMID *assistant = [self IDWithString:@"assistant"];
    if ([assistant isValid]) {
        return @[assistant];
    } else {
        return nil;
    }
}

- (BOOL)group:(DIMID *)group hasAssistant:(DIMID *)assistant {
    NSArray<DIMID *> *assistants = [self assistantsOfGroup:group];
    return [assistants containsObject:assistant];
}

@end
