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
//  DIMGroup.m
//  DIMCore
//
//  Created by Albert Moky on 2018/9/26.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DIMAccountUtils.h"

#import "DIMGroup.h"

@interface DIMGroup ()

// once the group founder is set, it will never change
@property (strong, nonatomic) id<MKMID> founder;

@end

@implementation DIMGroup

/* designated initializer */
- (instancetype)initWithIdentifier:(id<MKMID>)ID {
    if (self = [super initWithIdentifier:ID]) {
        _founder = nil;
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    DIMGroup *group = [super copyWithZone:zone];
    if (group) {
        group.founder = _founder;
    }
    return group;
}

- (NSString *)debugDescription {
    NSString *desc = [super debugDescription];
    NSDictionary *dict = MKJsonDecode(desc);
    NSMutableDictionary *info;
    if ([dict isKindOfClass:[NSMutableDictionary class]]) {
        info = (NSMutableDictionary *)dict;
    } else {
        info = [dict mutableCopy];
    }
    [info setObject:@(self.members.count) forKey:@"members"];
    return MKJsonEncode(info);
}

// Override
- (nullable id<MKMBulletin>)bulletin {
    NSArray<id<MKMDocument>> *docs = [self documents];
    return DIMDocumentGetBulletin(docs);
}

// Override
- (id<MKMID>)founder {
    if (!_founder) {
        id<MKMGroupDataSource> facebook = [self dataSource];
        NSAssert(facebook, @"group data source not set yet");
        id<MKMID> ID = [self identifier];
        _founder = [facebook founder:ID];
    }
    return _founder;
}

// Override
- (id<MKMID>)owner {
    id<MKMGroupDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"group data source not set yet");
    id<MKMID> ID = [self identifier];
    return [facebook owner:ID];
}

// Override
- (NSArray<id<MKMID>> *)members {
    id<MKMGroupDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"group data source not set yet");
    id<MKMID> ID = [self identifier];
    return [facebook members:ID];
}

// Override
- (NSArray<id<MKMID>> *)assistants {
    id<MKMGroupDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"group data source not set yet");
    id<MKMID> ID = [self identifier];
    return [facebook assistants:ID];
}

@end
