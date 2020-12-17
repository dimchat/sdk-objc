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
//  MKMPlugins.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/12.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "MKMAddressBTC.h"
#import "MKMAddressETH.h"
#import "MKMMetaDefault.h"
#import "MKMMetaBTC.h"
#import "MKMMetaETH.h"

#import "MKMPlugins.h"

@interface AddressFactory : MKMAddressFactory

@end

@implementation AddressFactory

- (nullable __kindof id<MKMAddress>)createAddress:(NSString *)address {
    NSUInteger len = [address length];
    if (len == 42) {
        // ETH address
        return [MKMAddressETH parse:address];
    }
    // try BTC address
    return [MKMAddressBTC parse:address];
}

@end

#pragma mark -

@interface MetaFactory : NSObject <MKMMetaFactory>

@property (readonly, nonatomic) MKMMetaType type;

- (instancetype)initWithType:(MKMMetaType)type;

@end

@implementation MetaFactory

- (instancetype)initWithType:(MKMMetaType)type {
    if (self = [super init]) {
        _type = type;
    }
    return self;
}

- (id<MKMMeta>)createMetaWithPublicKey:(id<MKMPublicKey>)PK
                                  seed:(nullable NSString *)name
                           fingerprint:(nullable NSData *)CT {
    id<MKMMeta> meta;
    switch (_type) {
        case MKMMetaVersion_MKM:
            meta = [[MKMMetaDefault alloc] initWithType:_type key:PK seed:name fingerprint:CT];
            break;
            
        case MKMMetaVersion_BTC:
        case MKMMetaVersion_ExBTC:
            meta = [[MKMMetaBTC alloc] initWithType:_type key:PK seed:name fingerprint:CT];
            break;
                
        case MKMMetaVersion_ETH:
        case MKMMetaVersion_ExETH:
            meta = [[MKMMetaETH alloc] initWithType:_type key:PK seed:name fingerprint:CT];
            break;

        default:
            NSAssert(false, @"meta type not supported: %d", _type);
            meta = nil;
            break;
    }
    return meta;
}

- (id<MKMMeta>)generateMetaWithPrivateKey:(id<MKMPrivateKey>)SK
                                     seed:(nullable NSString *)name {
    NSData *CT;
    if (name.length > 0) {
        CT = [SK sign:MKMUTF8Encode(name)];
    } else {
        CT = nil;
    }
    id<MKMPublicKey> PK = [SK publicKey];
    return [self createMetaWithPublicKey:PK seed:name fingerprint:CT];
}

- (nullable __kindof id<MKMMeta>)parseMeta:(NSDictionary *)info {
    MKMNetworkType version = [MKMMeta type:info];
    switch (version) {
        case MKMMetaVersion_MKM:
            return [[MKMMetaDefault alloc] initWithDictionary:info];
            break;
            
        case MKMMetaVersion_BTC:
        case MKMMetaVersion_ExBTC:
            return [[MKMMetaBTC alloc] initWithDictionary:info];
            break;
            
        case MKMMetaVersion_ETH:
        case MKMMetaVersion_ExETH:
            return [[MKMMetaETH alloc] initWithDictionary:info];
            break;
            
        default:
            NSAssert(false, @"meta type not supported: %d", version);
            break;
    }
    return nil;
}

@end

#pragma mark -

@interface DocumentFactory : NSObject <MKMDocumentFactory>

@property (readonly, strong, nonatomic) NSString *type;

- (instancetype)initWithType:(NSString *)type;

@end

@implementation DocumentFactory

- (instancetype)initWithType:(NSString *)type {
    if (self = [super init]) {
        _type = type;
    }
    return self;
}

- (NSString *)typeForID:(id<MKMID>)ID {
    if ([_type isEqualToString:@"*"]) {
        if (MKMIDIsGroup(ID)) {
            return MKMDocument_Bulletin;
        } else if (MKMIDIsUser(ID)) {
            return MKMDocument_Visa;
        }
        return MKMDocument_Profile;
    }
    return _type;
}

- (__kindof id<MKMDocument>)createDocument:(id<MKMID>)ID
                                      data:(NSData *)data
                                 signature:(NSData *)CT {
    NSString *type = [self typeForID:ID];
    if ([type isEqualToString:MKMDocument_Visa]) {
        return [[MKMVisa alloc] initWithID:ID data:data signature:CT];
    }
    if ([type isEqualToString:MKMDocument_Bulletin]) {
        return [[MKMBulletin alloc] initWithID:ID data:data signature:CT];
    }
    return [[MKMDocument alloc] initWithID:ID data:data signature:CT];
}

// create a new empty profile with entity ID
- (__kindof id<MKMDocument>)createDocument:(id<MKMID>)ID {
    NSString *type = [self typeForID:ID];
    if ([type isEqualToString:MKMDocument_Visa]) {
        return [[MKMVisa alloc] initWithID:ID];
    }
    if ([type isEqualToString:MKMDocument_Bulletin]) {
        return [[MKMBulletin alloc] initWithID:ID];
    }
    return [[MKMDocument alloc] initWithID:ID type:type];
}

- (nullable __kindof id<MKMDocument>)parseDocument:(NSDictionary *)doc {
    id<MKMID> ID = MKMIDFromString([doc objectForKey:@"ID"]);
    if (!ID) {
        return nil;
    }
    NSString *type = [doc objectForKey:@"type"];
    if (type.length == 0) {
        if (MKMIDIsGroup(ID)) {
            type = MKMDocument_Bulletin;
        } else {
            type = MKMDocument_Visa;
        }
    }
    if ([type isEqualToString:MKMDocument_Visa]) {
        return [[MKMVisa alloc] initWithDictionary:doc];
    }
    if ([type isEqualToString:MKMDocument_Bulletin]) {
        return [[MKMBulletin alloc] initWithDictionary:doc];
    }
    return [[MKMDocument alloc] initWithDictionary:doc];
}

@end

@implementation MKMPlugins

+ (void)registerAddressFactory {
    AddressFactory *factory = [[AddressFactory alloc] init];
    [MKMAddress setFactory:factory];
}

+ (void)registerMetaFactory {
    [MKMMeta setFactory:[[MetaFactory alloc] initWithType:MKMMetaVersion_MKM] forType:MKMMetaVersion_MKM];
    [MKMMeta setFactory:[[MetaFactory alloc] initWithType:MKMMetaVersion_BTC] forType:MKMMetaVersion_BTC];
    [MKMMeta setFactory:[[MetaFactory alloc] initWithType:MKMMetaVersion_ExBTC] forType:MKMMetaVersion_ExBTC];
    [MKMMeta setFactory:[[MetaFactory alloc] initWithType:MKMMetaVersion_ETH] forType:MKMMetaVersion_ETH];
    [MKMMeta setFactory:[[MetaFactory alloc] initWithType:MKMMetaVersion_ExETH] forType:MKMMetaVersion_ExETH];
}

+ (void)registerDocumentFactory {
    [MKMDocument setFactory:[[DocumentFactory alloc] initWithType:@"*"] forType:@"*"];
    [MKMDocument setFactory:[[DocumentFactory alloc] initWithType:MKMDocument_Visa] forType:MKMDocument_Visa];
    [MKMDocument setFactory:[[DocumentFactory alloc] initWithType:MKMDocument_Profile] forType:MKMDocument_Profile];
    [MKMDocument setFactory:[[DocumentFactory alloc] initWithType:MKMDocument_Bulletin] forType:MKMDocument_Bulletin];
}

@end
