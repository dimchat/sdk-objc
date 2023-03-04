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

@interface AddressFactory : DIMAddressFactory

@end

@implementation AddressFactory

- (nullable id<MKMAddress>)createAddress:(NSString *)address {
    NSUInteger len = [address length];
    if (len == 8) {
        NSString *lower = [address lowercaseString];
        if ([MKMAnywhere() isEqual:lower]) {
            return MKMAnywhere();
        }
    } else if (len == 9) {
        NSString *lower = [address lowercaseString];
        if ([MKMEverywhere() isEqual:lower]) {
            return MKMEverywhere();
        }
    }
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

- (instancetype)initWithType:(MKMMetaType)version;

@end

@implementation MetaFactory

- (instancetype)initWithType:(MKMMetaType)version {
    if (self = [super init]) {
        _type = version;
    }
    return self;
}

- (id<MKMMeta>)createMetaWithKey:(id<MKMVerifyKey>)PK
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

- (id<MKMMeta>)generateMetaWithKey:(id<MKMSignKey>)SK
                              seed:(nullable NSString *)name {
    NSData *CT;
    if (name.length > 0) {
        CT = [SK sign:MKMUTF8Encode(name)];
    } else {
        CT = nil;
    }
    id<MKMPublicKey> PK = [(id<MKMPrivateKey>)SK publicKey];
    return [self createMetaWithKey:PK seed:name fingerprint:CT];
}

- (nullable id<MKMMeta>)parseMeta:(NSDictionary *)info {
    id<MKMMeta> meta = nil;
    MKMFactoryManager *man = [MKMFactoryManager sharedManager];
    MKMMetaType version = [man.generalFactory metaType:info];
    switch (version) {
        case MKMMetaVersion_MKM:
            meta = [[MKMMetaDefault alloc] initWithDictionary:info];
            break;
            
        case MKMMetaVersion_BTC:
        case MKMMetaVersion_ExBTC:
            meta = [[MKMMetaBTC alloc] initWithDictionary:info];
            break;
            
        case MKMMetaVersion_ETH:
        case MKMMetaVersion_ExETH:
            meta = [[MKMMetaETH alloc] initWithDictionary:info];
            break;
            
        default:
            NSAssert(false, @"meta type not supported: %d", version);
            break;
    }
    return MKMMetaCheck(meta) ? meta : nil;
}

@end

#pragma mark -

@implementation MKMPlugins

+ (void)registerAddressFactory {
    AddressFactory *factory = [[AddressFactory alloc] init];
    MKMAddressSetFactory(factory);
}

+ (void)registerMetaFactory {
    MKMMetaSetFactory(MKMMetaVersion_MKM,
                      [[MetaFactory alloc] initWithType:MKMMetaVersion_MKM]);
    MKMMetaSetFactory(MKMMetaVersion_BTC,
                      [[MetaFactory alloc] initWithType:MKMMetaVersion_BTC]);
    MKMMetaSetFactory(MKMMetaVersion_ExBTC,
                      [[MetaFactory alloc] initWithType:MKMMetaVersion_ExBTC]);
    MKMMetaSetFactory(MKMMetaVersion_ETH,
                      [[MetaFactory alloc] initWithType:MKMMetaVersion_ETH]);
    MKMMetaSetFactory(MKMMetaVersion_ExETH,
                      [[MetaFactory alloc] initWithType:MKMMetaVersion_ExETH]);
}

+ (void)registerDocumentFactory {
    MKMDocumentSetFactory(@"*",
                          [[DIMDocumentFactory alloc] initWithType:@"*"]);
    MKMDocumentSetFactory(MKMDocument_Visa,
                          [[DIMDocumentFactory alloc] initWithType:MKMDocument_Visa]);
    MKMDocumentSetFactory(MKMDocument_Profile,
                          [[DIMDocumentFactory alloc] initWithType:MKMDocument_Profile]);
    MKMDocumentSetFactory(MKMDocument_Bulletin,
                          [[DIMDocumentFactory alloc] initWithType:MKMDocument_Bulletin]);
}

@end
