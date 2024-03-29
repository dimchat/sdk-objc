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
//  DIMAddressFactory.m
//  DIMCore
//
//  Created by Albert Moky on 2020/12/12.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "MKMAddressBTC.h"
#import "MKMAddressETH.h"

#import "DIMAddressFactory.h"

@interface DIMAddressFactory () {
    
    NSMutableDictionary<NSString *, id<MKMAddress>> *_addresses;
}

@end

@implementation DIMAddressFactory

- (instancetype)init {
    if (self = [super init]) {
        _addresses = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id<MKMAddress>)generateAddressWithMeta:(id<MKMMeta>)meta
                                     type:(MKMEntityType)network {
    id<MKMAddress> address = [meta generateAddress:network];
    NSAssert(address, @"failed to generate address: %@", meta);
    [_addresses setObject:address forKey:address.string];
    return address;
}

- (nullable id<MKMAddress>)parseAddress:(NSString *)address {
    id<MKMAddress> addr = [_addresses objectForKey:address];
    if (!addr) {
        addr = MKMAddressCreate(address);
        if (addr) {
            [_addresses setObject:addr forKey:address];
        }
    }
    return addr;
}

- (nullable id<MKMAddress>)createAddress:(NSString *)address {
    NSAssert(false, @"implement me!");
    return nil;
}

@end

@implementation DIMAddressFactory (Thanos)

- (NSUInteger)reduceMemory {
    NSUInteger snap = 0;
    snap = DIMThanos(_addresses, snap);
    return snap;
}

@end

#pragma mark -

@interface AddressFactory : DIMAddressFactory

@end

@implementation AddressFactory

- (nullable id<MKMAddress>)createAddress:(NSString *)address {
    NSComparisonResult res;
    NSUInteger len = [address length];
    if (len == 8) {
        // "anywhere"
        res = [MKMAnywhere().string caseInsensitiveCompare:address];
        if (res == NSOrderedSame) {
            return MKMAnywhere();
        }
    } else if (len == 10) {
        // "everywhere"
        res = [MKMEverywhere().string caseInsensitiveCompare:address];
        if (res == NSOrderedSame) {
            return MKMEverywhere();
        }
    }
    id<MKMAddress> addr;
    if (len == 42) {
        // ETH address
        addr = [MKMAddressETH parse:address];
    } else if (26 <= len && len <= 35) {
        // try BTC address
        addr = [MKMAddressBTC parse:address];
    }
    NSAssert(addr, @"invalid address: %@", address);
    return addr;
}

@end

void DIMRegisterAddressFactory(void) {
    AddressFactory *factory = [[AddressFactory alloc] init];
    MKMAddressSetFactory(factory);
}
