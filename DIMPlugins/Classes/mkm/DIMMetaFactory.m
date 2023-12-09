// license: https://mit-license.org
//
//  Ming-Ke-Ming : Decentralized User Identity Authentication
//
//                               Written in 2023 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2023 Albert Moky
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
//  DIMMetaFactory.m
//  DIMPlugins
//
//  Created by Albert Moky on 2023/12/9.
//  Copyright © 2023 DIM Group. All rights reserved.
//

#import "MKMMetaDefault.h"
#import "MKMMetaBTC.h"
#import "MKMMetaETH.h"

#import "DIMMetaFactory.h"

@implementation DIMMetaFactory

- (instancetype)initWithType:(MKMMetaType)version {
    if (self = [super init]) {
        _type = version;
    }
    return self;
}

- (id<MKMMeta>)createMetaWithKey:(id<MKMVerifyKey>)PK
                            seed:(nullable NSString *)name
                     fingerprint:(nullable id<MKMTransportableData>)CT {
    id<MKMMeta> meta;
    switch (_type) {
        case MKMMetaType_MKM:
            meta = [[MKMMetaDefault alloc] initWithType:_type key:PK seed:name fingerprint:CT];
            break;
            
        case MKMMetaType_BTC:
        case MKMMetaType_ExBTC:
            meta = [[MKMMetaBTC alloc] initWithType:_type key:PK seed:name fingerprint:CT];
            break;
                
        case MKMMetaType_ETH:
        case MKMMetaType_ExETH:
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
    id<MKMTransportableData> CT;
    if (name.length > 0) {
        NSData *sig = [SK sign:MKMUTF8Encode(name)];
        CT = MKMTransportableDataCreate(sig, nil);
    } else {
        CT = nil;
    }
    id<MKMPublicKey> PK = [(id<MKMPrivateKey>)SK publicKey];
    return [self createMetaWithKey:PK seed:name fingerprint:CT];
}

- (nullable id<MKMMeta>)parseMeta:(NSDictionary *)info {
    id<MKMMeta> meta = nil;
    MKMFactoryManager *man = [MKMFactoryManager sharedManager];
    MKMMetaType version = [man.generalFactory metaType:info
                                          defaultValue:0];
    switch (version) {
        case MKMMetaType_MKM:
            meta = [[MKMMetaDefault alloc] initWithDictionary:info];
            break;
            
        case MKMMetaType_BTC:
        case MKMMetaType_ExBTC:
            meta = [[MKMMetaBTC alloc] initWithDictionary:info];
            break;
            
        case MKMMetaType_ETH:
        case MKMMetaType_ExETH:
            meta = [[MKMMetaETH alloc] initWithDictionary:info];
            break;
            
        default:
            NSAssert(false, @"meta type not supported: %d", version);
            break;
    }
    return [meta isValid] ? meta : nil;
}

@end

void DIMRegisterMetaFactory(void) {
    MKMMetaSetFactory(MKMMetaType_MKM,
                      [[DIMMetaFactory alloc] initWithType:MKMMetaType_MKM]);
    MKMMetaSetFactory(MKMMetaType_BTC,
                      [[DIMMetaFactory alloc] initWithType:MKMMetaType_BTC]);
    MKMMetaSetFactory(MKMMetaType_ExBTC,
                      [[DIMMetaFactory alloc] initWithType:MKMMetaType_ExBTC]);
    MKMMetaSetFactory(MKMMetaType_ETH,
                      [[DIMMetaFactory alloc] initWithType:MKMMetaType_ETH]);
    MKMMetaSetFactory(MKMMetaType_ExETH,
                      [[DIMMetaFactory alloc] initWithType:MKMMetaType_ExETH]);
}
