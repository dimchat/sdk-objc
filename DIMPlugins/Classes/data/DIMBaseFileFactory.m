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
//  DIMBaseFileFactory.m
//  DIMPlugins
//
//  Created by Albert Moky on 2023/12/9.
//  Copyright © 2023 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "DIMBaseFileFactory.h"

@interface BaseNetworkFile : MKMDictionary <MKMPortableNetworkFile> {
    
    DIMBaseFileWrapper *_wrapper;
}

- (instancetype)initWithData:(nullable id<MKMTransportableData>)data
                    filename:(nullable NSString *)name
                         url:(nullable NSURL *)locator
                    password:(nullable id<MKMDecryptKey>)key;

@end

@implementation BaseNetworkFile

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
        _wrapper = [[DIMBaseFileWrapper alloc] initWithDictionary:self.dictionary];
    }
    return self;
}

/* designated initializer */
- (instancetype)init {
    if (self = [super init]) {
        _wrapper = [[DIMBaseFileWrapper alloc] initWithDictionary:self.dictionary];
    }
    return self;
}

- (instancetype)initWithData:(nullable id<MKMTransportableData>)data
                    filename:(nullable NSString *)name
                         url:(nullable NSURL *)locator
                    password:(nullable id<MKMDecryptKey>)key {
    if (self = [self init]) {
        // file data
        if (data) {
            _wrapper.data = data;
        }
        // file name
        if (name) {
            _wrapper.filename = name;
        }
        // remote URL
        if (locator) {
            _wrapper.URL = locator;
        }
        // decrypt key
        if (key) {
            _wrapper.password = key;
        }
    }
    return self;
}

- (NSData *)data {
    return [_wrapper.data data];
}

- (void)setData:(NSData *)data {
    [_wrapper setBinary:data];
}

- (NSString *)filename {
    return [_wrapper filename];
}

- (void)setFilename:(NSString *)filename {
    [_wrapper setFilename:filename];
}

- (NSURL *)URL {
    return [_wrapper URL];;
}

- (void)setURL:(NSURL *)url {
    [_wrapper setURL:url];
}

- (id<MKMDecryptKey>)password {
    return [_wrapper password];
}

- (void)setPassword:(id<MKMDecryptKey>)password {
    [_wrapper setPassword:password];
}

- (NSString *)string {
    NSString *urlString = [self _urlString];
    if (urlString) {
        // only contains 'URL', return the URL string directly
        return urlString;
    }
    // not a single URL, encode the entire dictionary
    return MKMJSONMapEncode([self dictionary]);
}

- (NSObject *)object {
    NSString *urlString = [self _urlString];
    if (urlString) {
        // only contains 'URL', return the URL string directly
        return urlString;
    }
    // not a single URL, return the entire dictionary
    return [self dictionary];
}

- (NSString *)_urlString {
    NSUInteger count = [self count];
    if (count == 1) {
        // if only contains 'URL' field, return the URL string directly
        return [self stringForKey:@"URL" defaultValue:nil];
    } else if (count == 2 && [self objectForKey:@"filename"]) {
        // ignore 'filename' field
        return [self stringForKey:@"URL" defaultValue:nil];
    } else {
        // not a single URL
        return nil;
    }
}

@end

@implementation DIMBaseFileFactory

- (id<MKMPortableNetworkFile>)createPortableNetworkFile:(id<MKMTransportableData>)data
                                               filename:(NSString *)name
                                                    url:(NSURL *)locator
                                               password:(id<MKMDecryptKey>)key {
    return [[BaseNetworkFile alloc] initWithData:data
                                        filename:name
                                             url:locator
                                        password:key];
}

- (id<MKMPortableNetworkFile>)parsePortableNetworkFile:(NSDictionary *)pnf {
    return [[BaseNetworkFile alloc] initWithDictionary:pnf];
}

@end
