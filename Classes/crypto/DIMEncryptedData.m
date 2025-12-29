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
//  DIMEncryptedData.m
//  DIMSDK
//
//  Created by Albert Moky on 2025/12/29.
//  Copyright © 2025 Albert Moky. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "DIMEncryptedData.h"

@interface DIMEncryptedData () {
    
    NSMutableDictionary<NSString *, NSData *> *_map;
}

@end

@implementation DIMEncryptedData

- (instancetype)init {
    if (self = [super init]) {
        _map = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *)description {
    NSMutableArray *lines = [[NSMutableArray alloc] init];
    [_map enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSData *data, BOOL *stop) {
        NSString *text = [NSString stringWithFormat:@"\"%@\": %lu byte(s)",
                          key, [data length]];
        [lines addObject:text];
    }];
    NSString *body = [lines componentsJoinedByString:@"\n\t"];
    Class clazz = [self class];
    return [NSString stringWithFormat:@"<%@ count=%lu>\n\t%@\n</%@>",
            clazz, [lines count], body, clazz];
}

- (NSString *)debugDescription {
    return [self description];
}

// Override
- (NSDictionary<NSString *, NSData *> *)dictionary {
    return _map;
}

// Override
- (BOOL)isEmpty {
    return [_map count] == 0;
}

// Override
- (void)setData:(NSData *)data forTerminal:(NSString *)terminal {
    if (!terminal) {
        NSAssert(false, @"should not happen");
        [_map removeObjectForKey:terminal];
        return;
    }
    [_map setObject:data forKey:terminal];
}

// Override
- (void)removeDataForTerminal:(NSString *)terminal {
    [_map removeObjectForKey:terminal];
}

// Override
- (NSData *)dataForTerminal:(NSString *)terminal {
    return [_map objectForKey:terminal];
}

// Override
- (NSSet<NSData *> *)values {
    NSArray *array = [_map allValues];
    if ([array count] == 0) {
        return nil;
    }
    return [NSSet setWithArray:array];
}

// Override
- (NSDictionary<NSString *, id> *)encodeForUserID:(id<MKMID>)did {
    NSAssert([did terminal] == nil, @"ID should not contain terminal here: %@", did);
    NSString *identifier = MKMIDConcat([did name], [did address], nil);
    NSMutableDictionary<NSString *, id> *results = [[NSMutableDictionary alloc] init];
    [_map enumerateKeysAndObjectsUsingBlock:^(NSString *target, NSData *data, BOOL *stop) {
        // encode data
        id base64 = MKTransportableDataEncode(data);
        NSAssert([base64 length] > 0, @"failed to encode data: %lu byte(s)", [data length]);
        if ([target length] == 0 || [target isEqualToString:@"*"]) {
            target = identifier;
        } else {
            target = [NSString stringWithFormat:@"%@/%@", identifier, target];
        }
        // insert to 'message.keys' with ID + terminal
        [results setObject:base64 forKey:target];
    }];
    return results;
}

@end

@implementation DIMEncryptedData (DataCreation)

+ (id<DIMEncryptedData>)decodeMap:(NSDictionary<NSString *,id> *)keys
                        forUserID:(id<MKMID>)did
                        terminals:(NSSet<NSString *> *)devices {
    id<DIMEncryptedData> result = [[DIMEncryptedData alloc] init];
    //
    //  0. ID string without terminal
    //
    NSString *identifier = MKMIDConcat([did name], [did address], nil);
    NSString *target;
    NSString *full;
    id base64;
    id<MKTransportableData> ted;
    NSData *data;
    for (NSString *item in devices) {
        target = [item length] == 0 ? @"*" : item;
        //
        //  1. get encoded data with target (ID + terminal)
        //
        if ([target isEqualToString:@"*"]) {
            base64 = [keys objectForKey:identifier];
        } else {
            full = [NSString stringWithFormat:@"%@/%@", identifier, target];
            base64 = [keys objectForKey:full];
        }
        if (!base64) {
            // key data not found
            continue;
        }
        //
        //  2. decode data
        //
        ted = MKTransportableDataParse(base64);
        data = [ted data];
        if (!data) {
            NSAssert(false, @"key data error: %@ -> %@", item, base64);
            continue;
        }
        //
        //  3. got data with target (ID + terminal)
        //
        [result setData:data forTerminal:target];
    }
    // OK
    return result;
}

@end
