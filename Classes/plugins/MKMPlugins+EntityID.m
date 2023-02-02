// license: https://mit-license.org
//
//  Ming-Ke-Ming : Decentralized User Identity Authentication
//
//                               Written in 2022 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2022 Albert Moky
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
//  MKMPlugins+Crypto.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/12.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import <MingKeMing/MingKeMing.h>

#import "MKMAddressBTC.h"

#import "MKMPlugins.h"

@interface MKMEntityID : MKMString <MKMID>

@property (strong, nonatomic, nullable) NSString *name;
@property (strong, nonatomic) id<MKMAddress> address;
@property (strong, nonatomic, nullable) NSString *terminal;

/**
 *  Initialize an ID with string form "name@address[/terminal]"
 *
 * @param string - ID string
 * @param seed - username
 * @param address - hash(fingerprint)
 * @param location - login point (optional)
 * @return ID object
 */
- (instancetype)initWithString:(NSString *)string
                          name:(nullable NSString *)seed
                       address:(id<MKMAddress>)address
                      terminal:(nullable NSString *)location
NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithName:(NSString *)seed
                     address:(id<MKMAddress>)address
                    terminal:(NSString *)location;

/**
 *  Default ID form (name@address)
 */
- (instancetype)initWithName:(NSString *)seed
                     address:(id<MKMAddress>)address;

/**
 *  For ID without name(only contains address), likes BTC/ETH/...
 */
- (instancetype)initWithAddress:(id<MKMAddress>)addr;

@end

static inline NSString *concat(NSString *name, id<MKMAddress> address, NSString *terminal) {
    NSUInteger len1 = [name length];
    NSUInteger len2 = [terminal length];
    if (len1 > 0) {
        if (len2 > 0) {
            return [NSString stringWithFormat:@"%@@%@/%@", name, [address string], terminal];
        } else {
            return [NSString stringWithFormat:@"%@@%@", name, [address string]];
        }
    } else if (len2 > 0) {
        return [NSString stringWithFormat:@"%@/%@", [address string], terminal];
    } else {
        return [address string];
    }
}

static inline id<MKMID> parse(NSString *string) {
    NSString *name;
    id<MKMAddress> address;
    NSString *terminal;
    // split ID string
    NSArray<NSString *> *pair = [string componentsSeparatedByString:@"/"];
    // terminal
    if (pair.count == 1) {
        terminal = nil;
    } else {
        assert(pair.count == 2);
        assert(pair.lastObject.length > 0);
        terminal = pair.lastObject;
    }
    // name @ address
    pair = [pair.firstObject componentsSeparatedByString:@"@"];
    assert(pair.firstObject.length > 0);
    if (pair.count == 1) {
        // got address without name
        name = nil;
        address = MKMAddressParse(pair.firstObject);
    } else {
        // got name & address
        assert(pair.count == 2);
        assert(pair.lastObject.length > 0);
        name = pair.firstObject;
        address = MKMAddressParse(pair.lastObject);
    }
    if (address == nil) {
        return nil;
    }
    return [[MKMEntityID alloc] initWithString:string name:name address:address terminal:terminal];
}

@implementation MKMEntityID

- (instancetype)init {
    NSAssert(false, @"DON'T call me!");
    NSString *string = nil;
    id<MKMAddress> address = nil;
    return [self initWithString:string name:nil address:address terminal:nil];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSAssert(false, @"DON'T call me!");
    NSString *string = nil;
    id<MKMAddress> address = nil;
    return [self initWithString:string name:nil address:address terminal:nil];
}

- (instancetype)initWithString:(NSString *)aString {
    //NSAssert(false, @"DON'T call me!");
    id<MKMAddress> address = nil;
    return [self initWithString:aString name:nil address:address terminal:nil];
}

/* designated initializer */
- (instancetype)initWithString:(NSString *)string
                          name:(nullable NSString *)seed
                       address:(id<MKMAddress>)address
                      terminal:(nullable NSString *)location {
    if (self = [super initWithString:string]) {
        _name = seed;
        _address = address;
        _terminal = location;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)seed
                     address:(id<MKMAddress>)address
                    terminal:(NSString *)location {
    return [self initWithString:concat(seed, address, location)
                           name:seed
                        address:address
                       terminal:location];
}

- (instancetype)initWithName:(NSString *)seed
                     address:(id<MKMAddress>)address {
    return [self initWithString:concat(seed, address, nil)
                           name:seed
                        address:address
                       terminal:nil];
}

- (instancetype)initWithAddress:(id<MKMAddress>)address {
    return [self initWithString:concat(nil, address, nil)
                           name:nil
                        address:address
                       terminal:nil];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    MKMEntityID *identifier = [super copyWithZone:zone];
    if (identifier) {
        identifier.name = _name;
        identifier.address = _address;
        identifier.terminal = _terminal;
    }
    return identifier;
}

- (MKMEntityType)type {
    MKMNetworkID network = [_address type];
    // compatible with MKM 0.9.*
    return MKMEntityTypeFromNetworkID(network);
}

- (BOOL)isBroadcast {
    return [_address isBroadcast];
}

- (BOOL)isUser {
    return [_address isUser];
}

- (BOOL)isGroup {
    return [_address isGroup];
}

@end

#pragma mark - ID factory

@interface MKMEntityIDFactory : NSObject <MKMIDFactory> {
    
    NSMutableDictionary<NSString *, id<MKMID>> *_identifiers;
}

@end

@implementation MKMEntityIDFactory

- (instancetype)init {
    if (self = [super init]) {
        _identifiers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id<MKMID>)generateIDWithMeta:(id<MKMMeta>)meta
                           type:(MKMEntityType)network
                       terminal:(nullable NSString *)location {
    id<MKMAddress> address = MKMAddressGenerate(network, meta);
    NSAssert(address, @"failed to generate ID with meta: %@", meta);
    return MKMIDCreate(meta.seed, address, location);
}

- (id<MKMID>)createID:(nullable NSString *)name
              address:(id<MKMAddress>)address
             terminal:(nullable NSString *)location {
    NSString *string = concat(name, address, location);
    id<MKMID> ID = [_identifiers objectForKey:string];
    if (!ID) {
        ID = [[MKMEntityID alloc] initWithString:string name:name address:address terminal:location];
        [_identifiers setObject:ID forKey:string];
    }
    return ID;
}

- (nullable id<MKMID>)parseID:(NSString *)identifier {
    id<MKMID> ID = [_identifiers objectForKey:identifier];
    if (!ID) {
        ID = parse(identifier);
        if (ID) {
            [_identifiers setObject:ID forKey:identifier];
        }
    }
    return ID;
}

@end

@implementation MKMPlugins (EntityID)

+ (void)registerIDFactory {
    MKMEntityIDFactory *factory = [[MKMEntityIDFactory alloc] init];
    MKMIDSetFactory(factory);
}

@end
