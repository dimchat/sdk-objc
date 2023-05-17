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
//  DIMDataParsers.m
//  DIMPlugins
//
//  Created by Albert Moky on 2020/4/7.
//  Copyright © 2020 DIM Group. All rights reserved.
//

#import "DIMDataParsers.h"

@interface JSON : NSObject <MKMObjectCoder>

@end

@implementation JSON

- (NSString *)encode:(id)container {
    if (![NSJSONSerialization isValidJSONObject:container]) {
        NSAssert(false, @"object format not support for json: %@", container);
        return nil;
    }
    static NSJSONWritingOptions opt = NSJSONWritingSortedKeys;
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:container
                                                   options:opt
                                                     error:&error];
    NSAssert(!error, @"JSON encode error: %@", error);
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}

- (nullable id)decode:(NSString *)json {
    static NSJSONReadingOptions opt = NSJSONReadingAllowFragments;
    //static NSJSONReadingOptions opt = NSJSONReadingMutableContainers;
    NSError *error = nil;
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:data
                                             options:opt
                                               error:&error];
    //NSAssert(!error, @"JSON decode error: %@", error);
    return obj;
}

@end

@interface UTF8 : NSObject <MKMStringCoder>

@end

@implementation UTF8

- (NSData *)encode:(NSString *)string {
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (nullable NSString *)decode:(NSData *)data {
    const unsigned char *bytes = (const unsigned char *)[data bytes];
    // rtrim '\0'
    NSInteger pos = data.length - 1;
    for (; pos >= 0; --pos) {
        if (bytes[pos] != 0) {
            break;
        }
    }
    NSUInteger length = pos + 1;
    return [[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding];
}

@end

void DIMRegisterDataParsers(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([MKMJSON getCoder] == nil) {
            [MKMJSON setCoder:[[JSON alloc] init]];
        }
        if ([MKMUTF8 getCoder] == nil) {
            [MKMUTF8 setCoder:[[UTF8 alloc] init]];
        }
    });
}
