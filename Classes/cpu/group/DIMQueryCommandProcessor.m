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
//  DIMQueryCommandProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 Albert Moky. All rights reserved.
//

#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMQueryCommandProcessor.h"

@implementation DIMQueryGroupCommandProcessor

- (nullable id<DKDContent>)executeCommand:(DIMCommand *)cmd
                              withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([cmd isKindOfClass:[DIMQueryGroupCommand class]], @"query group command error: %@", cmd);
    id<MKMID> sender = rMsg.sender;
    id<MKMID>group = cmd.group;
    // 1. check permission
    if (![self.facebook group:group containsMember:sender]) {
        if (![self.facebook group:group containsAssistant:sender]) {
            NSAssert(false, @"%@ is not a member/assistant of group %@, cannot query", sender, group);
            return nil;
        }
    }
    // 2. get members
    NSArray<id<MKMID>> *members = [self.facebook membersOfGroup:group];
    if ([members count] == 0) {
        NSString *text = [NSString stringWithFormat:@"Sorry, members not found in group: %@", group];
        id<DKDContent>res = [[DIMTextContent alloc] initWithText:text];
        res.group = group;
        return res;
    }
    // 3. respond
    MKMUser *user = [self.facebook currentUser];
    NSAssert(user, @"current user not set");
    if ([self.facebook group:group isOwner:user.ID]) {
        return [[DIMResetGroupCommand alloc] initWithGroup:group members:members];
    } else {
        return [[DIMInviteCommand alloc] initWithGroup:group members:members];
    }
}

@end
