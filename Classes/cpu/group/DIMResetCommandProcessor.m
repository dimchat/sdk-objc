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
//  DIMResetCommandProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 Albert Moky. All rights reserved.
//

#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMResetCommandProcessor.h"

@implementation DIMResetGroupCommandProcessor

- (nullable id<DKDContent>)_tempSave:(NSArray<id<MKMID>> *)newMembers sender:(id<MKMID>)sender group:(id<MKMID>)group {
    if ([self containsOwnerInMembers:newMembers group:group]) {
        // it's a full list, save it now
        if ([self.facebook saveMembers:newMembers group:group]) {
            id<MKMID>owner = [self.facebook ownerOfGroup:group];
            if (owner && ![owner isEqual:sender]) {
                // NOTICE: to prevent counterfeit,
                //         query the owner for newest member-list
                DIMQueryGroupCommand *query;
                query = [[DIMQueryGroupCommand alloc] initWithGroup:group];
                [self.messenger sendContent:query receiver:owner callback:NULL];
            }
        }
        // response (no need to response this group command)
        return nil;
    } else {
        // NOTICE: this is a partial member-list
        //         query the sender for full-list
        return [[DIMQueryGroupCommand alloc] initWithGroup:group];
    }
}

- (NSDictionary *)_doReset:(NSArray<id<MKMID>> *)newMembers group:(id<MKMID>)group {
    // existed members
    NSArray<id<MKMID>> *members = [self.facebook membersOfGroup:group];
    // removed list
    NSMutableArray<id<MKMID>> *removedList = [[NSMutableArray alloc] init];
    for (id<MKMID>item in members) {
        if ([newMembers containsObject:item]) {
            continue;
        }
        // removing member found
        [removedList addObject:item];
    }
    // added list
    NSMutableArray<id<MKMID>> *addedList = [[NSMutableArray alloc] init];
    for (id<MKMID>item in newMembers) {
        if ([members containsObject:item]) {
            continue;
        }
        // adding member found
        [addedList addObject:item];
    }
    NSMutableDictionary *res = [[NSMutableDictionary alloc] initWithCapacity:2];
    if ([addedList count] > 0 || [removedList count] > 0) {
        if (![self.facebook saveMembers:newMembers group:group]) {
            // failed to update members
            return res;
        }
        if ([addedList count] > 0) {
            [res setObject:addedList forKey:@"added"];
        }
        if ([removedList count] > 0) {
            [res setObject:removedList forKey:@"removed"];
        }
    }
    return res;
}

//
//  Main
//
- (nullable id<DKDContent>)processContent:(id<DKDContent>)content
                                 sender:(id<MKMID>)sender
                                message:(id<DKDReliableMessage>)rMsg {
    NSAssert([content isKindOfClass:[DIMResetGroupCommand class]] ||
             [content isKindOfClass:[DIMInviteCommand class]], @"invite command error: %@", content);
    DIMGroupCommand *cmd = (DIMGroupCommand *)content;
    id<MKMID>group = content.group;
    // new members
    NSArray<id<MKMID>> *newMembers = [self membersFromCommand:cmd];
    if ([newMembers count] == 0) {
        NSAssert(false, @"invite/reset command error: %@", cmd);
        return nil;
    }
    // 0. check whether group info empty
    if ([self isEmpty:group]) {
        // FIXME: group info lost?
        // FIXME: how to avoid strangers impersonating group member?
        return [self _tempSave:newMembers sender:sender group:group];
    }
    // 1. check permission
    if (![self.facebook group:group isOwner:sender]) {
        if (![self.facebook group:group hasAssistant:sender]) {
            NSAssert(false, @"%@ is not the owner/assistant of group %@, cannot reset.", sender, group);
            return nil;
        }
    }
    // 2. reset group members
    NSDictionary *result = [self _doReset:newMembers group:group];
    NSArray *added = [result objectForKey:@"added"];
    if (added) {
        [content setObject:added forKey:@"added"];
    }
    NSArray *removed = [result objectForKey:@"removed"];
    if (removed) {
        [content setObject:removed forKey:@"removed"];
    }
    // 3. respond nothing
    return nil;
}

@end
