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
//  DIMBaseDataFactory.m
//  DIMPlugins
//
//  Created by Albert Moky on 2023/12/9.
//  Copyright © 2023 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "DIMBaseDataFactory.h"

@interface Base64Data : MKMDictionary <MKMTransportableData> {
    
    DIMBaseDataWrapper *_wrapper;
}

- (instancetype)initWithData:(NSData *)binary;

- (NSString *)encode:(NSString *)mimeType;

@end

@implementation Base64Data

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
        _wrapper = [[DIMBaseDataWrapper alloc] initWithDictionary:self.dictionary];
    }
    return self;
}

/* designated initializer */
- (instancetype)init {
    if (self = [super init]) {
        _wrapper = [[DIMBaseDataWrapper alloc] initWithDictionary:self.dictionary];
    }
    return self;
}

- (instancetype)initWithData:(NSData *)binary {
    if (self = [self init]) {
        // encode algorithm
        _wrapper.algorithm = MKMAlgorithm_Base64;
        // binary data
        if ([binary length] > 0) {
            _wrapper.data = binary;
        }
    }
    return self;
}

- (NSString *)algorithm {
    return [_wrapper algorithm];
}

- (NSData *)data {
    return [_wrapper data];
}

- (NSObject *)object {
    return [self string];
}

- (NSString *)string {
    // 0. "{BASE64_ENCODE}"
    // 1. "base64,{BASE64_ENCODE}"
    return [_wrapper encode];
}

- (NSString *)encode:(NSString *)mimeType {
    // 2. "data:image/png;base64,{BASE64_ENCODE}"
    return [_wrapper encode:mimeType];
}

@end

#pragma mark -

@implementation DIMBase64DataFactory

- (id<MKMTransportableData>)createTransportableData:(NSData *)data {
    return [[Base64Data alloc] initWithData:data];
}

- (nullable id<MKMTransportableData>)parseTransportableData:(NSDictionary *)ted {
    // TODO: 1. check algorithm
    //       2. check data format
    return [[Base64Data alloc] initWithDictionary:ted];
}

@end
