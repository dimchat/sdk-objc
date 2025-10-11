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
//  DIMMessageShortener.m
//  DIMSDK
//
//  Created by Albert Moky on 2025/10/12.
//  Copyright © 2025 Albert Moky. All rights reserved.
//

#import "DIMMessageShortener.h"

static inline NSMutableDictionary *_mutable_dictionary(__kindof NSDictionary *dict) {
    if ([dict isKindOfClass:[NSMutableDictionary class]]) {
        return dict;
    } else {
        return [dict mutableCopy];
    }
}

@implementation DIMMessageShortener

- (instancetype)init {
    if (self = [super init]) {
        _contentShortKeys = @[
            @"T", @"type",
            @"N", @"sn",
            @"W", @"time",        // When
            @"G", @"group",
            @"C", @"command",     // Command name
        ];
        _cryptoShortKeys = @[
            @"A", @"algorithm",
            @"D", @"data",
            @"I", @"iv",          // Initial Vector
        ];
        _messageShortKeys = @[
            @"F", @"sender",      // From
            @"R", @"receiver",    // Rcpt to
            @"W", @"time",        // When
            @"T", @"type",
            @"G", @"group",
            //------------------
            @"K", @"key",         // or "keys"
            @"D", @"data",
            @"V", @"signature",   // Verification
            //------------------
            @"M", @"meta",
            @"P", @"visa",        // Profile
        ];
    }
    return self;
}

- (NSMutableDictionary *)compressContent:(NSDictionary *)content {
    NSMutableDictionary *mDict = _mutable_dictionary(content);
    NSArray *keys = [self contentShortKeys];
    [self dictionary:mDict shortenKeys:keys];
    return mDict;
}

- (NSMutableDictionary *)extractContent:(__kindof NSDictionary *)content {
    NSMutableDictionary *mDict = _mutable_dictionary(content);
    NSArray *keys = [self contentShortKeys];
    [self dictionary:mDict restoreKeys:keys];
    return mDict;
}

- (NSMutableDictionary *)compressSymmetricKey:(__kindof NSDictionary *)info {
    NSMutableDictionary *mDict = _mutable_dictionary(info);
    NSArray *keys = [self cryptoShortKeys];
    [self dictionary:mDict shortenKeys:keys];
    return mDict;
}

- (NSMutableDictionary *)extractSymmetricKey:(__kindof NSDictionary *)info {
    NSMutableDictionary *mDict = _mutable_dictionary(info);
    NSArray *keys = [self cryptoShortKeys];
    [self dictionary:mDict restoreKeys:keys];
    return mDict;
}

- (NSMutableDictionary *)compressReliableMessage:(__kindof NSDictionary *)msg {
    NSMutableDictionary *mDict = _mutable_dictionary(msg);
    NSArray *keys = [self messageShortKeys];
    [self dictionary:mDict shortenKeys:keys];
    return mDict;
}

- (NSMutableDictionary *)extractReliableMessage:(__kindof NSDictionary *)msg {
    NSMutableDictionary *mDict = _mutable_dictionary(msg);
    NSArray *keys = [self messageShortKeys];
    [self dictionary:mDict restoreKeys:keys];
    return mDict;
}

@end

@implementation DIMMessageShortener (Modification)

- (void)dictionary:(NSMutableDictionary *)dict
           moveKey:(NSString *)from
             toKey:(NSString *)to {
    id value = [dict objectForKey:from];
    if (value) {
        NSAssert([dict objectForKey:to] == nil, @"keys conflicted: %@ -> %@", from, to);
        [dict removeObjectForKey:from];
        [dict setObject:value forKey:to];
    }
}

- (void)dictionary:(NSMutableDictionary *)dict
       shortenKeys:(NSArray<NSString *> *)keys {
    NSUInteger cnt = [keys count];
    NSUInteger idx = 1;
    NSString *from;
    NSString *to;
    while (idx < cnt) {
        from = [keys objectAtIndex:idx];
        to = [keys objectAtIndex:(idx - 1)];
        [self dictionary:dict moveKey:from toKey:to];
        idx += 2;
    }
}

- (void)dictionary:(NSMutableDictionary *)dict
       restoreKeys:(NSArray<NSString *> *)keys {
    NSUInteger cnt = [keys count];
    NSUInteger idx = 1;
    NSString *from;
    NSString *to;
    while (idx < cnt) {
        from = [keys objectAtIndex:(idx - 1)];
        to = [keys objectAtIndex:idx];
        [self dictionary:dict moveKey:from toKey:to];
        idx += 2;
    }
}

@end
