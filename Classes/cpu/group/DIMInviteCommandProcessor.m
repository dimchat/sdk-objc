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

@interface DIMCommandProcessor (Hacking)

- (DIMCommandProcessor *)processorForCommand:(NSString *)name;

@end

@implementation DIMInviteCommandProcessor

// check whether this is a Reset command
- (BOOL)_isReset:(NSArray<id<MKMID>> *)inviteList sender:(id<MKMID>)sender group:(id<MKMID>)group {
    // NOTICE: owner invite owner?
    //         it's a Reset command!
    if ([self containsOwnerInMembers:inviteList group:group]) {
        return [self.facebook group:group isOwner:sender];
    }
    return NO;
}

- (nullable id<DKDContent>)_callReset:(DIMGroupCommand *)cmd sender:(id<MKMID>)sender message:(id<DKDReliableMessage>)rMsg {
    DIMCommandProcessor *cpu = [self processorForCommand:DIMGroupCommand_Reset];
    NSAssert(cpu, @"reset CPU not set yet");
    return [cpu processContent:cmd sender:sender message:rMsg];
}

- (nullable NSArray<id<MKMID>> *)_doInvite:(NSArray<id<MKMID>> *)inviteList group:(id<MKMID>)group {
    // existed members
    NSArray<id<MKMID>> *members = [self.facebook membersOfGroup:group];
    NSMutableArray<id<MKMID>> *mArray = [members mutableCopy];
    // added list
    NSMutableArray *addedList = [[NSMutableArray alloc] initWithCapacity:inviteList.count];
    for (id<MKMID>item in inviteList) {
        if ([members containsObject:item]) {
            continue;
        }
        // adding member found
        [addedList addObject:item];
        [mArray addObject:item];
    }
    if ([addedList count] > 0) {
        if ([self.facebook saveMembers:mArray group:group]) {
            return addedList;
        }
        NSAssert(false, @"failed to update members for group: %@", group);
    }
    return nil;
}

//
//  Main
//
- (nullable id<DKDContent>)processContent:(id<DKDContent>)content
                                 sender:(id<MKMID>)sender
                                message:(id<DKDReliableMessage>)rMsg {
    NSAssert([content isKindOfClass:[DIMInviteCommand class]], @"invite command error: %@", content);
    DIMInviteCommand *cmd = (DIMInviteCommand *)content;
    id<MKMID>group = content.group;
    // 0. check whether group info empty
    if ([self isEmpty:group]) {
        // NOTICE:
        //     group membership lost?
        //     reset group members
        return [self _callReset:cmd sender:sender message:rMsg];
    }
    // 1. check permission
    if (![self.facebook group:group hasMember:sender]) {
        if (![self.facebook group:group hasAssistant:sender]) {
            if (![self.facebook group:group isOwner:sender]) {
                //NSAssert(false, @"%@ is not a member/assistant of group %@, cannot invite.", sender, group);
                return nil;
            }
        }
    }
    // 2. get inviting members
    NSArray<id<MKMID>> *inviteList = [self membersFromCommand:cmd];
    if ([inviteList count] == 0) {
        NSAssert(false, @"invite command error: %@", cmd);
        return nil;
    }
    // 2.1. check for reset
    if ([self _isReset:inviteList sender:sender group:group]) {
        // NOTICE: owner invites owner?
        //         it means this should be a 'reset' command
        return [self _callReset:cmd sender:sender message:rMsg];
    }
    // 2.2. get added-list
    NSArray<id<MKMID>> *added = [self _doInvite:inviteList group:group];
    if (added) {
        [content setObject:added forKey:@"added"];
    }
    // 3. respond nothing (DON'T respond group command directly)
    return nil;
}

@end
