// license: https://mit-license.org
//
//  DIMP : Decentralized Instant Messaging Protocol
//
//                               Written in 2020 by Moky <albert.moky@gmail.com>
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
//  DIMLoginCommand.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/4/14.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "NSDate+Timestamp.h"

#import "DIMStation.h"
#import "DIMServiceProvider.h"

#import "DIMLoginCommand.h"

@interface DIMLoginCommand ()

@property (strong, nonatomic) NSDate *time;

@end

@implementation DIMLoginCommand

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
        // lazy
        _time = nil;
    }
    return self;
}

/* designated initializer */
- (instancetype)initWithType:(UInt8)type {
    if (self = [super initWithType:type]) {
        _time = nil;
    }
    return self;
}

- (instancetype)initWithID:(DIMID *)ID {
    if (self = [self initWithCommand:DIMCommand_Login]) {
        // ID
        if (ID) {
            [_storeDictionary setObject:ID forKey:@"ID"];
        }
        // time
        _time = [[NSDate alloc] init];
        NSNumber *timestemp = NSNumberFromDate(_time);
        [_storeDictionary setObject:timestemp forKey:@"time"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    DIMLoginCommand *cmd = [super copyWithZone:zone];
    if (cmd) {
        cmd.time = _time;
    }
    return cmd;
}

- (NSDate *)time {
    if (!_time) {
        NSNumber *timestamp = [_storeDictionary objectForKey:@"time"];
        NSAssert(timestamp != nil, @"time error: %@", _storeDictionary);
        _time = NSDateFromNumber(timestamp);
    }
    return _time;
}

#pragma mark Client Info

- (DIMID *)ID {
    id string = [_storeDictionary objectForKey:@"ID"];
    return [self.delegate parseID:string];
}

- (NSString *)device {
    return [_storeDictionary objectForKey:@"device"];
}
- (void)setDevice:(NSString *)device {
    if (device) {
        [_storeDictionary setObject:device forKey:@"device"];
    } else {
        [_storeDictionary removeObjectForKey:@"device"];
    }
}

- (NSString *)agent {
    return [_storeDictionary objectForKey:@"agent"];
}
- (void)setAgent:(NSString *)agent {
    if (agent) {
        [_storeDictionary setObject:agent forKey:@"agent"];
    } else {
        [_storeDictionary removeObjectForKey:@"agent"];
    }
}

#pragma mark Server Info

- (NSDictionary *)stationInfo {
    return [_storeDictionary objectForKey:@"station"];
}
- (void)setStationInfo:(NSDictionary *)stationInfo {
    if (stationInfo) {
        [_storeDictionary setObject:stationInfo forKey:@"station"];
    } else {
        [_storeDictionary removeObjectForKey:@"station"];
    }
}
- (void)copyStationInfo:(DIMStation *)station {
    DIMID *ID = station.ID;
    NSString *host = station.host;
    UInt32 port = station.port;
    if (![ID isValid] || [host length] == 0) {
        NSAssert(!station, @"station error: %@", station);
        return;
    }
    if (port == 0) {
        port = 9394;
    }
    [self setStationInfo:@{
        @"ID"  : ID,
        @"host": host,
        @"port": @(port),
    }];
}

- (NSDictionary *)providerInfo {
    return [_storeDictionary objectForKey:@"provider"];
}
- (void)setProviderInfo:(NSDictionary *)providerInfo {
    if (providerInfo) {
        [_storeDictionary setObject:providerInfo forKey:@"provider"];
    } else {
        [_storeDictionary removeObjectForKey:@"provider"];
    }
}
- (void)copyProviderInfo:(DIMServiceProvider *)provider {
    DIMID *ID = provider.ID;
    if (![ID isValid]) {
        NSAssert(!provider, @"SP error: %@", provider);
        return;
    }
    [self setProviderInfo:@{
        @"ID"  : ID,
    }];
}

@end
