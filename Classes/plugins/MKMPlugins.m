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
#import "MKMMetaBTC.h"

#import "MKMPlugins.h"

@interface AddressFactory : MKMAddressFactory

@end

@implementation AddressFactory

- (nullable __kindof id<MKMAddress>)createAddress:(NSString *)address {
    NSUInteger len = [address length];
    if (len == 42) {
        // ETH address
    }
    // try BTC address
    return [MKMAddressBTC parse:address];
}

@end

@interface MetaFactory : NSObject <MKMMetaFactory>

@end

@implementation MetaFactory

- (__kindof id<MKMMeta>)createMetaWithType:(MKMMetaType)version
                                       key:(id<MKMPublicKey>)PK
                                      seed:(nullable NSString *)name
                               fingerprint:(nullable NSData *)CT {
    id<MKMMeta> meta;
    switch (version) {
        case MKMMetaVersion_MKM:
        case MKMMetaVersion_BTC:
        case MKMMetaVersion_ExBTC:
            meta = [[MKMMetaBTC alloc] initWithType:version key:PK seed:name fingerprint:CT];
            break;
            
        default:
            NSAssert(false, @"meta type not supported: %d", version);
            meta = nil;
            break;
    }
    return meta;
}

- (__kindof id<MKMMeta>)generateMetaWithType:(MKMMetaType)version
                                  privateKey:(id<MKMPrivateKey>)SK
                                        seed:(nullable NSString *)name {
    NSData *CT;
    if (name.length > 0) {
        CT = [SK sign:MKMUTF8Encode(name)];
    } else {
        CT = nil;
    }
    id<MKMPublicKey> PK = [SK publicKey];
    return [self createMetaWithType:version key:PK seed:name fingerprint:CT];
}

- (nullable __kindof id<MKMMeta>)parseMeta:(NSDictionary *)info {
    NSNumber *type = [info objectForKey:@"type"];
    if (!type) {
        type = [info objectForKey:@"version"];
    }
    id<MKMMeta> meta;
    MKMNetworkType version = [type unsignedCharValue];
    switch (version) {
        case MKMMetaVersion_MKM:
        case MKMMetaVersion_BTC:
        case MKMMetaVersion_ExBTC:
            meta = [[MKMMetaBTC alloc] initWithDictionary:info];
            break;
            
        default:
            NSAssert(false, @"meta type not supported: %d", version);
            meta = nil;
            break;
    }
    return meta;
}

@end

@interface DocumentFactory : NSObject <MKMDocumentFactory>

@end

@implementation DocumentFactory

- (__kindof id<MKMDocument>)createDocument:(id<MKMID>)ID
                                      type:(NSString *)type
                                      data:(NSData *)data
                                 signature:(NSData *)CT {
    if (MKMIDIsUser(ID)) {
        if (type.length == 0 || [type isEqualToString:MKMDocument_Visa]) {
            // UserProfile
            return [[MKMVisa alloc] initWithID:ID data:data signature:CT];
        }
    } else if (MKMIDIsGroup(ID)) {
        return [[MKMBulletin alloc] initWithID:ID data:data signature:CT];
    }
    return [[MKMDocument alloc] initWithID:ID data:data signature:CT];
}

// create a new empty profile with entity ID
- (__kindof id<MKMDocument>)createDocument:(id<MKMID>)ID
                                      type:(NSString *)type {
    if (MKMIDIsUser(ID)) {
        if (type.length == 0 || [type isEqualToString:MKMDocument_Visa]) {
            // UserProfile
            return [[MKMVisa alloc] initWithID:ID];
        }
    } else if (MKMIDIsGroup(ID)) {
        return [[MKMBulletin alloc] initWithID:ID];
    }
    return [[MKMDocument alloc] initWithID:ID type:type];
}

- (nullable __kindof id<MKMDocument>)parseDocument:(NSDictionary *)doc {
    id<MKMID> ID = MKMIDFromString([doc objectForKey:@"ID"]);
    if (!ID) {
        return nil;
    }
    if (MKMIDIsUser(ID)) {
        NSString *type = [doc objectForKey:@"type"];
        if (type.length == 0 || [type isEqualToString:MKMDocument_Visa]) {
            // UserProfile
            return [[MKMVisa alloc] initWithDictionary:doc];
        }
    } else if (MKMIDIsGroup(ID)) {
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
    MetaFactory *factory = [[MetaFactory alloc] init];
    [MKMMeta setFactory:factory];
}

+ (void)registerDocumentFactory {
    DocumentFactory *factory = [[DocumentFactory alloc] init];
    [MKMDocument setFactory:factory];
}

+ (void)registerAllFactories {
    [self registerAddressFactory];
    [self registerMetaFactory];
    [self registerDocumentFactory];
    
    [self registerKeyFactories];
    [self registerCoders];
    [self registerDigesters];
}

@end
