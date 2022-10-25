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
//  MKMMetaETH.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/15.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "MKMAddressETH.h"

#import "MKMMetaETH.h"

@interface MKMMetaETH () {
    
    // cache
    MKMAddressETH *_cachedAddress;
}

@end

@implementation MKMMetaETH

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
        _cachedAddress = nil;
    }
    return self;
}

/* designated initializer */
- (instancetype)initWithType:(MKMMetaType)version
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
    if (!_cachedAddress) {
        // generate and cache it
        NSData *data = [self.key data];
        _cachedAddress = [MKMAddressETH generate:data];
    }
    return _cachedAddress;
}

- (nullable id<MKMAddress>)generateAddress:(MKMEntityType)network {
    NSAssert(network == MKMEntityType_User, @"ETH address type error: %d", network);
    NSAssert(self.type == MKMMetaVersion_ETH || self.type == MKMMetaVersion_ExETH,
             @"meta version error: %d", self.type);
    return [self generateAddress];
}

@end
