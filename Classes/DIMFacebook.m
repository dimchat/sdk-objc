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
#import "DIMArchivist.h"

#import "DIMFacebook.h"

@implementation DIMFacebook

- (nullable NSArray<id<MKMUser>> *)localUsers {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable id<MKMUser>)selectLocalUserWithID:(id<MKMID>)receiver {
    NSArray<id<MKMUser>> *users = self.localUsers;
    if ([users count] == 0) {
        NSAssert(false, @"local users should not be empty");
        return nil;
    } else if ([receiver isBroadcast]) {
        // broadcast message can decrypt by anyone, so just return current user
        return [users firstObject];
    } else if ([receiver isUser]) {
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
    NSAssert([receiver isGroup], @"receiver error: %@", receiver);
    // the messenger will check group info before decrypting message,
    // so we can trust that the group's meta & members MUST exist here.
    NSArray<id<MKMID>> *members = [self membersOfGroup:receiver];
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

- (BOOL)saveMeta:(id<MKMMeta>)meta forID:(id<MKMID>)ID {
    if ([meta isValid] && [meta matchIdentifier:ID]) {
        // meta OK
    } else {
        NSAssert(false, @"meta not valid: %@", ID);
        return NO;
    }
    // check old meta
    id<MKMMeta> old = [self metaForID:ID];
    if (old) {
        //NSAssert([meta isEqual:old], @"meta should not changed");
        return YES;
    }
    // meta not exists yet, save it
    return [self.archivist saveMeta:meta forID:ID];
}

- (BOOL)saveDocument:(id<MKMDocument>)document {
    id<MKMID> ID = [document ID];
    if (![document isValid]) {
        // try to verify
        id<MKMMeta> meta = [self metaForID:ID];
        if (!meta) {
            NSAssert(false, @"meta not found: %@", ID);
            return NO;
        } else if (![document verify:meta.publicKey]) {
            NSAssert(false, @"failed to verify document: %@", ID);
            return NO;
        }
    }
    NSString *type = [document type];
    // check old documents with type
    NSArray<id<MKMDocument>> *docs = [self documentsForID:ID];
    id<MKMDocument> old = [DIMDocumentHelper lastDocument:docs forType:type];
    if (old && [DIMDocumentHelper isExpired:document compareTo:old]) {
        NSAssert(false, @"drop expired document: %@", ID);
        return NO;
    }
    return [self.archivist saveDocument:document];
}

- (nullable id<MKMMeta>)metaForID:(id<MKMID>)ID {
    //if ([ID isBroadcast]) {
    //    // broadcast ID has no meta
    //    return nil;
    //}
    id<MKMMeta> meta = [self.archivist metaForID:ID];
    [self.archivist checkMeta:meta forID:ID];
    return meta;
}

- (NSArray<id<MKMDocument>> *)documentsForID:(id<MKMID>)ID {
    //if ([ID isBroadcast]) {
    //    // broadcast ID has no documents
    //    return nil;
    //}
    NSArray<id<MKMDocument>> *docs = [self.archivist documentsForID:ID];
    [self.archivist checkDocuments:docs forID:ID];
    return docs;
}

- (nullable id<MKMUser>)createUser:(id<MKMID>)ID {
    NSAssert([ID isUser], @"user ID error: %@", ID);
    // check visa key
    if (![ID isBroadcast]) {
        if (![self publicKeyForEncryption:ID]) {
            NSAssert(false, @"visa.key not found: %@", ID);
            return nil;
        }
        // NOTICE: if visa.key exists, then visa & meta must exist too.
    }
    UInt8 network = [ID type];
    // check user type
    if (network == MKMEntityType_Station) {
        return [[DIMStation alloc] initWithID:ID];
    } else if (network == MKMEntityType_Bot) {
        return [[DIMBot alloc] initWithID:ID];
    }
    // general user, or 'anyone@anywhere'
    return [[DIMUser alloc] initWithID:ID];
}

- (nullable id<MKMGroup>)createGroup:(id<MKMID>)ID {
    NSAssert([ID isGroup], @"group ID error: %@", ID);
    // check members
    if (![ID isBroadcast]) {
        NSArray<id<MKMID>> *members = [self membersOfGroup:ID];
        if ([members count] == 0) {
            NSAssert(false, @"group members not found: %@", ID);
            return nil;
        }
        // NOTICE: if members exist, then owner (founder) must exist,
        //         and bulletin & meta must exist too.
    }
    UInt8 network = [ID type];
    // check group type
    if (network == MKMEntityType_ISP) {
        return [[DIMServiceProvider alloc] initWithID:ID];
    }
    // general group, or 'everyone@everywhere'
    return [[DIMGroup alloc] initWithID:ID];
}

@end
