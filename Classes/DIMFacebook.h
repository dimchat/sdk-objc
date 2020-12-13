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
//  DIMFacebook.h
//  DIMClient
//
//  Created by Albert Moky on 2019/6/26.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

// Network ID
#define MKMNetwork_IsPerson(network)   (((network) == MKMNetwork_Main) ||      \
                                       ((network) == MKMNetwork_BTCMain))

#define MKMNetwork_IsStation(network)  ((network) == MKMNetwork_Station)
#define MKMNetwork_IsProvider(network) ((network) == MKMNetwork_Provider)

#define MKMNetwork_IsThing(network)    ((network) & MKMNetwork_Thing)
#define MKMNetwork_IsRobot(network)    ((network) == MKMNetwork_Robot)

@interface DIMFacebook : DIMBarrack

/**
 *  Get current user
 *
 * @return first local user
 */
@property (readonly, strong, nonatomic, nullable) MKMUser *currentUser;

- (BOOL)isEmptyDocument:(id<MKMDocument>)doc;
- (BOOL)verifyDocument:(id<MKMDocument>)doc forID:(id<MKMID>)ID;
- (BOOL)verifyDocument:(id<MKMDocument>)doc;

@end

@interface DIMFacebook (Storage)

/**
 *  Save meta for entity ID (must verify first)
 *
 * @param meta - entity meta
 * @param ID - entity ID
 * @return true on success
 */
- (BOOL)saveMeta:(id<MKMMeta>)meta forID:(id<MKMID>)ID;

/**
 *  Save profile with entity ID (must verify first)
 *
 * @param doc - entity profile
 * @return true on success
 */
- (BOOL)saveDocument:(id<MKMDocument>)doc;

/**
 *  Save members of group
 *
 * @param members - member ID list
 * @param ID - group ID
 * @return true on success
 */
- (BOOL)saveMembers:(NSArray<id<MKMID>> *)members group:(id<MKMID>)ID;

@end

@interface DIMFacebook (Plugins)

+ (void)loadPlugins;

@end

NS_ASSUME_NONNULL_END
