// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2018 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2019 Albert Moky
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
//  DIMStation.m
//  DIMCore
//
//  Created by Albert Moky on 2018/10/13.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DIMServiceProvider.h"

#import "DIMStation.h"

@interface DIMStation () {
    
    id<DIMUser> _user;
}

@property (strong, nonatomic) id<DIMUser> user;

@property (strong, nonatomic) NSString *host;
@property (nonatomic) UInt32 port;

@end

@implementation DIMStation

- (instancetype)init {
    NSAssert(false, @"DON'T call me");
    id<MKMID> ID = nil;
    return [self initWithID:ID];
}

/* designated initializer */
- (instancetype)initWithID:(id<MKMID>)ID
                      host:(NSString *)IP
                      port:(UInt32)port {
    NSAssert(ID.type == MKMEntityType_Station, @"station ID error: %@", ID);
    if (self = [super init]) {
        _user = [[DIMUser alloc] initWithID:ID];
        _host = IP;
        _port = port;
    }
    return self;
}

- (instancetype)initWithID:(id<MKMID>)ID {
    NSString *ip = nil;
    return [self initWithID:ID host:ip port:0];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    DIMStation *server = [[self class] allocWithZone:zone];
    if (server) {
        server.user = _user;
        server.host = _host;
        server.port = _port;
    }
    return server;
}

- (NSString *)debugDescription {
    NSString *desc = [super debugDescription];
    NSDictionary *dict = MKMJSONDecode(desc);
    NSMutableDictionary *info;
    if ([dict isKindOfClass:[NSMutableDictionary class]]) {
        info = (NSMutableDictionary *)dict;
    } else {
        info = [dict mutableCopy];
    }
    [info setObject:self.host forKey:@"host"];
    [info setObject:@(self.port) forKey:@"port"];
    return MKMJSONEncode(info);
}

- (BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        YES;
    }
    NSAssert([object isKindOfClass:[DIMStation class]], @"error: %@", object);
    DIMStation *server = (DIMStation *)object;
    if (![server.host isEqualToString:_host]) {
        return NO;
    }
    if (server.port != _port) {
        return NO;
    }
    // others?
    return YES;
}

#pragma mark Entity

- (id<MKMID>)ID {
    return _user.ID;
}

- (MKMEntityType)type {
    return _user.type;
}

- (id<DIMEntityDataSource>)dataSource {
    return _user.dataSource;
}

- (void)setDataSource:(id<DIMEntityDataSource>)dataSource {
    _user.dataSource = dataSource;
}

- (id<MKMMeta>)meta {
    return _user.meta;
}

- (nullable id<MKMDocument>)documentWithType:(nullable NSString *)type {
    return [_user documentWithType:type];
}

#pragma mark User

- (nullable id<MKMVisa>)visa {
    return _user.visa;
}

- (BOOL)verifyVisa:(id<MKMVisa>)visa {
    return [_user verifyVisa:visa];
}

- (BOOL)verify:(NSData *)data withSignature:(NSData *)signature {
    return [_user verify:data withSignature:signature];
}

- (NSData *)encrypt:(NSData *)plaintext {
    return [_user encrypt:plaintext];
}

#pragma mark Local User

- (NSArray<id<MKMID>> *)contacts {
    return _user.contacts;
}

- (nullable id<MKMVisa>)signVisa:(id<MKMVisa>)visa {
    return [_user signVisa:visa];
}

- (NSData *)sign:(NSData *)data {
    return [_user sign:data];
}

- (nullable NSData *)decrypt:(NSData *)ciphertext {
    return [_user decrypt:ciphertext];
}

@end
