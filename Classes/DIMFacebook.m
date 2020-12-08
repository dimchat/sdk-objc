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
#import "MKMAESKey.h"
#import "MKMRSAPublicKey.h"
#import "MKMRSAPrivateKey.h"

#import "DIMServiceProvider.h"
#import "DIMStation.h"
#import "DIMRobot.h"

#import "DIMPolylogue.h"
#import "DIMChatroom.h"

#import "DIMFacebook.h"

static inline void load_plugins(void) {
//    // AES
//    [MKMSymmetricKey registerClass:[MKMAESKey class] forAlgorithm:SCAlgorithmAES];
//    [MKMSymmetricKey registerClass:[MKMAESKey class] forAlgorithm:@"AES/CBC/PKCS7Padding"];
//    
//    // RSA: PublicKey
//    [MKMPublicKey registerClass:[MKMRSAPublicKey class] forAlgorithm:ACAlgorithmRSA];
//    [MKMPublicKey registerClass:[MKMRSAPublicKey class] forAlgorithm:@"SHA256withRSA"];
//    [MKMPublicKey registerClass:[MKMRSAPublicKey class] forAlgorithm:@"RSA/ECB/PKCS1Padding"];
//    // RSA: PrivateKey
//    [MKMPrivateKey registerClass:[MKMRSAPrivateKey class] forAlgorithm:ACAlgorithmRSA];
//    [MKMPrivateKey registerClass:[MKMRSAPrivateKey class] forAlgorithm:@"SHA256withRSA"];
//    [MKMPrivateKey registerClass:[MKMRSAPrivateKey class] forAlgorithm:@"RSA/ECB/PKCS1Padding"];
}

@implementation DIMFacebook

- (instancetype)init {
    if (self = [super init]) {
        // load plugins
        SingletonDispatchOnce(^{
            load_plugins();
        });
    }
    return self;
}

- (nullable NSArray<MKMUser *> *)localUsers {
    NSAssert(false, @"override me!");
    return nil;
}

- (nullable MKMUser *)currentUser {
    NSArray<MKMUser *> *users = self.localUsers;
    if ([users count] == 0) {
        return nil;
    }
    return [users firstObject];
}

- (nullable id<MKMID>)IDWithAddress:(id<MKMAddress>)address {
    id<MKMID> ID = [[MKMID alloc] initWithAddress:address];
    id<MKMMeta> meta = [self metaForID:ID];
    if (!meta) {
        // failed to get meta for this ID
        return nil;
    }
    NSString *seed = [meta seed];
    if ([seed length] == 0) {
        return ID;
    }
    return [[MKMID alloc] initWithName:seed address:address];
}

- (nullable MKMUser *)selectUserWithID:(id<MKMID>)receiver {
    NSArray<MKMUser *> *users = self.localUsers;
    if ([users count] == 0) {
        NSAssert(false, @"local users should not be empty");
        return nil;
    } else if (MKMIDIsBroadcast(receiver)) {
        // broadcast message can decrypt by anyone, so just return current user
        return [users firstObject];
    }
    if (MKMIDIsGroup(receiver)) {
        // group message (recipient not designated)
        for (MKMUser *item in users) {
            if ([self group:receiver hasMember:item.ID]) {
                //self.currentUser = item;
                return item;
            }
        }
    } else {
        // 1. personal message
        // 2. split group message
        for (MKMUser *item in users) {
            if ([receiver isEqual:item.ID]) {
                //self.currentUser = item;
                return item;
            }
        }
    }
    NSAssert(false, @"receiver not in local users: %@, %@", receiver, users);
    return nil;
}

#pragma mark DIMBarrack

- (nullable id<MKMID>)createID:(NSString *)string {
    return MKMIDFromString(string);
}

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

#pragma mark - MKMEntityDataSource

- (nullable id<MKMMeta>)metaForID:(id<MKMID>)ID {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable __kindof id<MKMDocument>)profileForID:(id<MKMID>)ID {
    NSAssert(false, @"implement me!");
    return nil;
}

#pragma mark - MKMUserDataSource

- (nullable NSArray<id<MKMID>> *)contactsOfUser:(id<MKMID>)user {
    NSAssert(false, @"implement me!");
    return nil;
}

- (id<MKMPrivateKey>)privateKeyForSignature:(id<MKMID>)user {
    NSAssert(false, @"implement me!");
    return nil;
}

- (NSArray<id<MKMPrivateKey>> *)privateKeysForDecryption:(id<MKMID>)user {
    NSAssert(false, @"implement me!");
    return nil;
}

#pragma mark - MKMGroupDataSource

- (nullable id<MKMID>)founderOfGroup:(id<MKMID>)group {
    id<MKMID> founder = [super founderOfGroup:group];
    if (founder) {
        return founder;
    }
    // check each member's public key with group meta
    id<MKMMeta> gMeta = [self metaForID:group];
    if (!gMeta) {
        // FIXME: when group profile was arrived but the meta still on the way,
        //        here will cause founder not found.
        //NSAssert(false, @"failed to get group meta");
        return nil;
    }
    NSArray<id<MKMID>> *members = [self membersOfGroup:group];
    id<MKMMeta> mMeta;
    for (id<MKMID> item in members) {
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

- (nullable id<MKMID>)ownerOfGroup:(id<MKMID>)group {
    id<MKMID>owner = [super ownerOfGroup:group];
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

- (nullable NSArray<id<MKMID>> *)membersOfGroup:(id<MKMID>)group {
    NSAssert(false, @"implement me!");
    return nil;
}

@end

@implementation DIMFacebook (Storage)

#pragma mark Meta

- (BOOL)verifyMeta:(id<MKMMeta>)meta forID:(id<MKMID>)ID {
    NSAssert([meta isValid], @"meta error: %@", meta);
    return [meta matchID:ID];
}

- (BOOL)saveMeta:(id<MKMMeta>)meta forID:(id<MKMID>)ID {
    NSAssert(false, @"override me!");
    return NO;
}

#pragma mark Profile

- (BOOL)verifyProfile:(id<MKMDocument>)profile forID:(id<MKMID>)ID {
    if (![ID isEqual:profile.ID]) {
        // profile ID not match
        return NO;
    }
    return [self verifyProfile:profile];
}

- (BOOL)verifyProfile:(id<MKMDocument>)profile {
    id<MKMID> ID = profile.ID;
    if (!ID) {
        NSAssert(false, @"profile ID error: %@", profile);
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
            if ([profile verify:meta.key]) {
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
    return [profile verify:meta.key];
}

- (BOOL)saveProfile:(id<MKMDocument>)profile {
    NSAssert(false, @"override me!");
    return NO;
}

#pragma mark Group Members

- (BOOL)saveMembers:(NSArray<id<MKMID>> *)members group:(id<MKMID>)ID {
    NSAssert(false, @"override me!");
    return NO;
}

@end

@implementation DIMFacebook (Relationship)

- (BOOL)user:(id<MKMID>)user hasContact:(id<MKMID>)contact{
    NSArray<id<MKMID>> *contacts = [self contactsOfUser:user];
    return [contacts containsObject:contact];
}

#pragma mark -

- (BOOL)group:(id<MKMID>)group isFounder:(id<MKMID>)member {
    // check member's public key with group's meta.key
    id<MKMMeta> gMeta = [self metaForID:group];
    NSAssert(gMeta, @"failed to get meta for group: %@", group);
    id<MKMMeta> mMeta = [self metaForID:member];
    //NSAssert(mMeta, @"failed to get meta for member: %@", member);
    return [gMeta matchPublicKey:mMeta.key];
}

- (BOOL)group:(id<MKMID>)group isOwner:(id<MKMID>)member {
    if (group.type == MKMNetwork_Polylogue) {
        return [self group:group isFounder:member];
    }
    NSAssert(false, @"only Polylogue so far: %@", group);
    return NO;
}

- (BOOL)group:(id<MKMID>)group hasMember:(id<MKMID>)member {
    NSArray<id<MKMID>> *members = [self membersOfGroup:group];
    return [members containsObject:member];
}

#pragma mark Group Assistants

- (nullable NSArray<id<MKMID>> *)assistantsOfGroup:(id<MKMID>)group {
    NSAssert(false, @"implement me!");
    return nil;
}

- (BOOL)group:(id<MKMID>)group hasAssistant:(id<MKMID>)assistant {
    NSArray<id<MKMID>> *assistants = [self assistantsOfGroup:group];
    return [assistants containsObject:assistant];
}

@end
