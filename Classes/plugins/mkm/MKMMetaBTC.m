// license: https://mit-license.org
//
//  Ming-Ke-Ming : Decentralized User Identity Authentication
//
//                               Written in 2020 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2020 Albert Moky
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
//  MKMMetaBTC.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/12.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "MKMAddressBTC.h"

#import "MKMMetaBTC.h"

@interface MKMMetaBTC () {
    
    // cache
    MKMAddressBTC *_cachedAddress;
}

@end

@implementation MKMMetaBTC

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
        _cachedAddress = nil;
    }
    return self;
}

/* designated initializer */
- (instancetype)initWithType:(UInt8)version
                         key:(id<MKMVerifyKey>)publicKey
                        seed:(NSString *)seed
                 fingerprint:(NSData *)fingerprint {
    if (self = [super initWithType:version
                               key:publicKey
                              seed:seed
                       fingerprint:fingerprint]) {
        _cachedAddress = nil;
    }
    return self;
}

- (nullable id<MKMAddress>)generateAddress {
    if (!_cachedAddress && [self isValid]) {
        // generate and cache it
        NSData *data = [self.key data];
        _cachedAddress = [MKMAddressBTC generate:data network:MKMNetwork_BTCMain];
    }
    return _cachedAddress;
}

- (nullable id<MKMAddress>)generateAddress:(UInt8)type {
    NSAssert(type == MKMNetwork_BTCMain, @"BTC address type error: %d", type);
    NSAssert(self.type == MKMMetaVersion_BTC || self.type == MKMMetaVersion_ExBTC,
             @"meta version error: %d", self.type);
    return [self generateAddress];
}

- (BOOL)matchID:(id<MKMID>)ID {
    if ([ID.address isKindOfClass:[MKMAddressBTC class]]) {
        return [super matchID:ID];
    }
    return NO;
}

@end
