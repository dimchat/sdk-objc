// license: https://mit-license.org
//
//  DIMP : Decentralized Instant Messaging Protocol
//
//                               Written in 2018 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2018 Albert Moky
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
//  DIMBarrack.m
//  DIMCore
//
//  Created by Albert Moky on 2018/10/12.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DIMUser.h"
#import "DIMGroup.h"
#import "DIMBot.h"
#import "DIMStation.h"
#import "DIMServiceProvider.h"

#import "DIMBarrack.h"

@implementation DIMBarrack

- (void)cacheUser:(id<MKMUser>)user {
    NSAssert(false, @"implement me!");
}

- (void)cacheGroup:(id<MKMGroup>)group {
    NSAssert(false, @"implement me!");
}

- (nullable id<MKMUser>)user:(id<MKMID>)uid {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable id<MKMGroup>)group:(id<MKMID>)gid {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (nullable id<MKMUser>)createUser:(nonnull id<MKMID>)uid {
    NSAssert([uid isUser], @"user ID error: %@", uid);
    MKMEntityType network = [uid type];
    // check user type
    if (network == MKMEntityType_Station) {
        return [[DIMStation alloc] initWithIdentifier:uid];
    } else if (network == MKMEntityType_Bot) {
        return [[DIMBot alloc] initWithIdentifier:uid];
    }
    // general user, or 'anyone@anywhere'
    return [[DIMUser alloc] initWithIdentifier:uid];
}

// Override
- (nullable id<MKMGroup>)createGroup:(nonnull id<MKMID>)gid {
    NSAssert([gid isGroup], @"group ID error: %@", gid);
    MKMEntityType network = [gid type];
    // check group type
    if (network == MKMEntityType_ISP) {
        return [[DIMServiceProvider alloc] initWithIdentifier:gid];
    }
    // general group, or 'everyone@everywhere'
    return [[DIMGroup alloc] initWithIdentifier:gid];
}

@end
