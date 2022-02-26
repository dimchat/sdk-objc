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
//  DIMInviteCommandProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 Albert Moky. All rights reserved.
//

#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMInviteCommandProcessor.h"

@implementation DIMInviteCommandProcessor

- (NSArray<id<DKDContent>> *)executeCommand:(DIMCommand *)cmd
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([cmd isKindOfClass:[DIMInviteCommand class]], @"invite command error: %@", cmd);
    DIMFacebook *facebook = self.facebook;
    DIMGroupCommand *gmd = (DIMGroupCommand *)cmd;
    
    // 0. check group
    id<MKMID> group = cmd.group;
    id<MKMID> owner = [facebook ownerOfGroup:group];
    NSArray<id<MKMID>> *members = [facebook membersOfGroup:group];
    if (!owner || members.count == 0) {
        // NOTICE:
        //     group membership lost?
        //     reset group members
        return [self temporarySave:gmd sender:rMsg.sender];
    }
    
    // 1. check permission
    id<MKMID> sender = rMsg.sender;
    if (![members containsObject:sender]) {
        // not a member? check assistants
        NSArray<id<MKMID>> *assistants = [facebook assistantsOfGroup:group];
        if (![assistants containsObject:sender]) {
            return [self respondText:@"Sorry, you are not allowed to invite new members into this group."
                           withGroup:group];
        }
    }
    
    // 2. get inviting members
    NSArray<id<MKMID>> *inviteList = [self membersFromCommand:gmd];
    if ([inviteList count] == 0) {
        return [self respondText:@"Invite command error." withGroup:group];
    }
    // 2.1. check for reset
    if ([sender isEqual:owner] && [inviteList containsObject:owner]) {
        // NOTICE: owner invite owner?
        //         it means this should be a 'reset' command
        return [self temporarySave:gmd sender:rMsg.sender];
    }
    // 2.2. build invited-list
    NSMutableArray<id<MKMID>> *mArray = [members mutableCopy];
    NSMutableArray *addedList = [[NSMutableArray alloc] initWithCapacity:inviteList.count];
    for (id<MKMID> item in inviteList) {
        if ([members containsObject:item]) {
            continue;
        }
        // adding member found
        [addedList addObject:item];
        [mArray addObject:item];
    }
    // 2.3. do invite
    if ([addedList count] > 0) {
        if ([self.facebook saveMembers:mArray group:group]) {
            [cmd setObject:MKMIDRevert(addedList) forKey:@"added"];
        }
    }
    
    // 3. respond nothing (DON'T respond group command directly)
    return nil;
}

@end
