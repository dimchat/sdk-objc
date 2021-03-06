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

- (nullable id<DKDContent>)temporarySave:(DIMGroupCommand *)cmd sender:(id<MKMID>)sender {
    DIMFacebook *facebook = self.facebook;
    id<MKMID> group = cmd.group;
    // check whether the owner contained in the new members
    NSArray<id<MKMID>> *newMembers = [self membersFromCommand:cmd];
    for (id<MKMID> ID in newMembers) {
        if ([facebook group:group isOwner:ID]) {
            // it's a full list, save it now
            if ([facebook saveMembers:newMembers group:group]) {
                id<MKMID> owner = [facebook ownerOfGroup:group];
                if (owner && ![owner isEqual:sender]) {
                    // NOTICE: to prevent counterfeit,
                    //         query the owner for newest member-list
                    DIMQueryGroupCommand *query;
                    query = [[DIMQueryGroupCommand alloc] initWithGroup:group];
                    [self.messenger sendContent:query sender:nil receiver:owner callback:NULL priority:1];
                }
            }
            // response (no need to respond this group command
            return nil;
        }
    }
    // NOTICE: this is a partial member-list
    //         query the sender for full-list
    return [[DIMQueryGroupCommand alloc] initWithGroup:group];
}

- (nullable id<DKDContent>)executeCommand:(DIMCommand *)cmd
                              withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([cmd isKindOfClass:[DIMResetGroupCommand class]] ||
             [cmd isKindOfClass:[DIMInviteCommand class]], @"invite command error: %@", cmd);
    DIMFacebook *facebook = self.facebook;
    DIMGroupCommand *gmd = (DIMGroupCommand *)cmd;

    // 0. check group
    id<MKMID> group = cmd.group;
    id<MKMID> owner = [facebook ownerOfGroup:group];
    NSArray<id<MKMID>> *members = [facebook membersOfGroup:group];
    if (!owner || members.count == 0) {
        // FIXME: group info lost?
        // FIXME: how to avoid strangers impersonating group member?
        return [self temporarySave:gmd sender:rMsg.sender];
    }
    
    // 1. check permission
    id<MKMID> sender = rMsg.sender;
    if (![owner isEqual:sender]) {
        // not the owner? check assistants
        NSArray<id<MKMID>> *assistants = [facebook assistantsOfGroup:group];
        if (![assistants containsObject:sender]) {
            NSAssert(false, @"%@ is not the owner/assistant of group %@, cannot reset.", sender, group);
            return nil;
        }
    }
    
    // 2. resetting members
    NSArray<id<MKMID>> *newMembers = [self membersFromCommand:gmd];
    if ([newMembers count] == 0) {
        NSAssert(false, @"group command error: %@", cmd);
        return nil;
    }
    // 2.1. check owner
    if (![newMembers containsObject:owner]) {
        NSAssert(false, @"cannot expel owner(%@) of group: %@", owner, group);
        return nil;
    }
    // 2.2. build expelled-list
    NSMutableArray<id<MKMID>> *removedList = [[NSMutableArray alloc] init];
    for (id<MKMID> item in members) {
        if ([newMembers containsObject:item]) {
            continue;
        }
        // removing member found
        [removedList addObject:item];
    }
    // 2.3. build invited-list
    NSMutableArray<id<MKMID>> *addedList = [[NSMutableArray alloc] init];
    for (id<MKMID> item in newMembers) {
        if ([members containsObject:item]) {
            continue;
        }
        // adding member found
        [addedList addObject:item];
    }
    // 2.4. do reset
    if ([addedList count] > 0 || [removedList count] > 0) {
        if ([self.facebook saveMembers:newMembers group:group]) {
            if ([addedList count] > 0) {
                [cmd setObject:[MKMID revert:addedList] forKey:@"added"];
            }
            if ([removedList count] > 0) {
                [cmd setObject:[MKMID revert:removedList] forKey:@"removed"];
            }
        }
    }

    // 3. respond nothing
    return nil;
}

@end
