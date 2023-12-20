// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2018 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2018 Albert Moky
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

@interface DIMStation ()

@property (nonatomic, strong) id<MKMUser> user;

@property (strong, nonatomic) NSString *host;  // Domain/IP
@property (nonatomic) UInt16 port;             // default: 9394

@end

@implementation DIMStation

- (instancetype)init {
    NSAssert(false, @"DON'T call me");
    id<MKMID> ID = MKMAnyStation();
    return [self initWithID:ID];
}

/* designated initializer */
- (instancetype)initWithID:(id<MKMID>)ID
                      host:(NSString *)IP
                      port:(UInt16)port {
    NSAssert(ID.type == MKMEntityType_Station || ID.type == MKMEntityType_Any, @"station ID error: %@", ID);
    if (self = [super init]) {
        self.user = [[DIMUser alloc] initWithID:ID];
        self.host = IP;
        self.port = port;
    }
    return self;
}

- (instancetype)initWithID:(id<MKMID>)ID {
    NSString *ip = nil;
    return [self initWithID:ID host:ip port:0];
}

- (instancetype)initWithHost:(NSString *)IP port:(UInt16)port {
    return [self initWithID:MKMAnyStation() host:IP port:port];
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

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ ID=\"%@\" host=\"%@\" port=%u />", [self class], [self ID], [self host], [self port]];
}

- (NSString *)debugDescription {
    return [self description];
}

- (BOOL)isEqual:(id)other {
    if ([other conformsToProtocol:@protocol(MKMStation)]) {
        return DIMSameStation(other, self);;
    } else if ([other conformsToProtocol:@protocol(MKMUser)]) {
        return [_user isEqual:other];
    } else if ([other conformsToProtocol:@protocol(MKMID)]) {
        return [_user.ID isEqual:other];
    }
    return NO;
}

- (id<MKMDocument>)profile {
    NSArray<id<MKMDocument>> *docs = [self documents];
    return [DIMDocumentHelper lastDocument:docs forType:@"*"];
}

- (NSString *)host {
    NSString *IP = _host;
    if (!IP) {
        id<MKMDocument> doc = [self profile];
        id str = [doc propertyForKey:@"host"];
        _host = IP = MKMConverterGetString(str, nil);
    }
    return IP;
}

- (UInt16)port {
    UInt16 po = _port;
    if (po == 0) {
        id<MKMDocument> doc = [self profile];
        id num = [doc propertyForKey:@"port"];
        _port = po = MKMConverterGetUnsignedShort(num, 0);
    }
    return po;
}

- (id<MKMID>)provider {
    id<MKMDocument> doc = [self profile];
    if (doc) {
        id ISP = [doc propertyForKey:@"ISP"];
        return MKMIDParse(ISP);
    }
    return nil;
}

- (void)setID:(id<MKMID>)ID {
    id<MKMEntityDataSource> delegate = [self dataSource];
    id<MKMUser> inner = [[DIMUser alloc] initWithID:ID];
    [inner setDataSource:delegate];
    _user = inner;
}

#pragma mark Entity

- (id<MKMID>)ID {
    return _user.ID;
}

- (MKMEntityType)type {
    return _user.type;
}

- (id<MKMEntityDataSource>)dataSource {
    return _user.dataSource;
}

- (void)setDataSource:(id<MKMEntityDataSource>)dataSource {
    _user.dataSource = dataSource;
}

- (id<MKMMeta>)meta {
    return _user.meta;
}

- (NSArray<id<MKMDocument>> *)documents {
    return [_user documents];
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

#pragma mark - Broadcast IDs

static id<MKMID> s_any_station = nil;
static id<MKMID> s_every_stations = nil;

id<MKMID> MKMAnyStation(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_any_station = [[MKMID alloc] initWithString:@"station@anywhere"
                                                 name:@"station"
                                              address:MKMAnywhere()
                                             terminal:nil];
    });
    return s_any_station;
}

id<MKMID> MKMEveryStations(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_every_stations = [[MKMID alloc] initWithString:@"stations@everywhere"
                                                    name:@"stations"
                                                 address:MKMEverywhere()
                                                terminal:nil];
    });
    return s_every_stations;
}
