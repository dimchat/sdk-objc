// license: https://mit-license.org
//
//  DIMP : Decentralized Instant Messaging Protocol
//
//                               Written in 2025 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2025 Albert Moky
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
//  DIMMessageCompressor.m
//  DIMSDK
//
//  Created by Albert Moky on 2025/10/12.
//  Copyright © 2025 Albert Moky. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "DIMMessageShortener.h"

#import "DIMMessageCompressor.h"

@interface DIMMessageCompressor ()

@property (strong, nonatomic) __kindof id<DIMShortener> shortener;

@end

@implementation DIMMessageCompressor

- (instancetype)init {
    NSAssert(false, @"DON'T call me");
    id<DIMShortener> shortener = nil;
    return [self initWithShortener:shortener];
}

- (instancetype)initWithShortener:(id<DIMShortener>)shortener {
    if (self = [super init]) {
        _shortener = shortener;
    }
    return self;
}

// Override
- (NSData *)compressContent:(NSMutableDictionary *)content withKey:(NSDictionary *)pwd {
    id<DIMShortener> shortener = [self shortener];
    NSAssert(shortener, @"message shortener not set");
    content = [shortener compressContent:content];
    NSString *json = MKJsonMapEncode(content);
    return MKUTF8Encode(json);
}

// Override
- (nullable NSDictionary *)extractContent:(NSData *)data withKey:(NSDictionary *)pwd {
    NSString *json = MKUTF8Decode(data);
    if ([json length] == 0) {
        NSAssert(false, @"content data error: %lu", [data length]);
        return nil;
    }
    NSDictionary *info = MKJsonMapDecode(json);
    if ([info count] > 0) {
        id<DIMShortener> shortener = [self shortener];
        NSAssert(shortener, @"message shortener not set");
        info = [shortener extractContent:info];
    }
    return info;
}

// Override
- (NSData *)compressSymmetricKey:(NSMutableDictionary *)key {
    id<DIMShortener> shortener = [self shortener];
    NSAssert(shortener, @"message shortener not set");
    key = [shortener compressSymmetricKey:key];
    NSString *json = MKJsonMapEncode(key);
    return MKUTF8Encode(json);
}

// Override
- (nullable NSDictionary *)extractSymmetricKey:(NSData *)data {
    NSString *json = MKUTF8Decode(data);
    if ([json length] == 0) {
        NSAssert(false, @"symmetric key error: %lu", [data length]);
        return nil;
    }
    NSDictionary *info = MKJsonMapDecode(json);
    if ([info count] > 0) {
        id<DIMShortener> shortener = [self shortener];
        NSAssert(shortener, @"message shortener not set");
        info = [shortener extractSymmetricKey:info];
    }
    return info;
}

// Override
- (NSData *)compressReliableMessage:(NSMutableDictionary *)msg {
    id<DIMShortener> shortener = [self shortener];
    NSAssert(shortener, @"message shortener not set");
    msg = [shortener compressReliableMessage:msg];
    NSString *json = MKJsonMapEncode(msg);
    return MKUTF8Encode(json);
}

// Override
- (nullable NSDictionary *)extractReliableMessage:(NSData *)data {
    NSString *json = MKUTF8Decode(data);
    if ([json length] == 0) {
        NSAssert(false, @"reliable message error: %lu", [data length]);
        return nil;
    }
    NSDictionary *info = MKJsonMapDecode(json);
    if ([info count] > 0) {
        id<DIMShortener> shortener = [self shortener];
        NSAssert(shortener, @"message shortener not set");
        info = [shortener extractReliableMessage:info];
    }
    return info;
}

@end
