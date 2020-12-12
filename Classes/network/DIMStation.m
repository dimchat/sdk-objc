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

#import "NSObject+Compare.h"

#import "DIMServiceProvider.h"

#import "DIMStation.h"

@interface DIMStation ()

@property (strong, nonatomic) NSString *host;
@property (nonatomic) UInt32 port;

@end

@implementation DIMStation

/* designated initializer */
- (instancetype)initWithID:(id<MKMID>)ID
                      host:(NSString *)IP
                      port:(UInt32)port {
    if (self = [super initWithID:ID]) {
        _host = IP;
        _port = port;
        _delegate = nil;
    }
    return self;
}

- (instancetype)initWithID:(id<MKMID>)ID {
    return [self initWithID:ID host:@"127.0.0.1" port:9394];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    DIMStation *server = [super copyWithZone:zone];
    if (server) {
        server.host = _host;
        server.port = _port;
        server.delegate = _delegate;
    }
    return server;
}

- (NSString *)debugDescription {
    NSString *desc = [super debugDescription];
    NSDictionary *dict = MKMJSONDecode(MKMUTF8Encode(desc));
    NSMutableDictionary *info;
    if ([dict isKindOfClass:[NSMutableDictionary class]]) {
        info = (NSMutableDictionary *)dict;
    } else {
        info = [dict mutableCopy];
    }
    [info setObject:self.host forKey:@"host"];
    [info setObject:@(self.port) forKey:@"port"];
    return MKMUTF8Decode(MKMJSONEncode(info));
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

@end
