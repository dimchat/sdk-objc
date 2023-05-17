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
//  DIMDataCoders.m
//  DIMPlugins
//
//  Created by Albert Moky on 2020/4/7.
//  Copyright © 2020 DIM Group. All rights reserved.
//

#import "base58.h"

#import "DIMDataCoders.h"

@interface Hex : NSObject <MKMDataCoder>

@end

static inline char hex_char(char ch) {
    if (ch >= '0' && ch <= '9') {
        return ch - '0';
    }
    if (ch >= 'a' && ch <= 'f') {
        return ch - 'a' + 10;
    }
    if (ch >= 'A' && ch <= 'F') {
        return ch - 'A' + 10;
    }
    return 0;
}

@implementation Hex

- (NSString *)encode:(NSData *)data {
    NSMutableString *output = nil;
    
    const unsigned char *bytes = (const unsigned char *)[data bytes];
    NSUInteger len = [data length];
    output = [[NSMutableString alloc] initWithCapacity:(len*2)];
    for (int i = 0; i < len; ++i) {
        [output appendFormat:@"%02x", bytes[i]];
    }
    
    return output;
}

- (nullable NSData *)decode:(NSString *)string {
    NSMutableData *output = nil;
    
    NSString *str = string;
    // 1. remove ' ', ':', '-', '\n'
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@":" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"-" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    // 2. skip '0x' prefix
    char ch0, ch1;
    NSUInteger pos = 0;
    NSUInteger len = [string length];
    if (len > 2) {
        ch0 = [str characterAtIndex:0];
        ch1 = [str characterAtIndex:1];
        if (ch0 == '0' && (ch1 == 'x' || ch1 == 'X')) {
            pos = 2;
        }
    }
    
    // 3. decode bytes
    output = [[NSMutableData alloc] initWithCapacity:(len/2)];
    unsigned char byte;
    for (; (pos + 1) < len; pos += 2) {
        ch0 = [str characterAtIndex:pos];
        ch1 = [str characterAtIndex:(pos + 1)];
        byte = hex_char(ch0) * 16 + hex_char(ch1);
        [output appendBytes:&byte length:1];
    }
    
    return output;
}

@end

@interface Base58 : NSObject <MKMDataCoder>

@end

@implementation Base58

- (NSString *)encode:(NSData *)data {
    NSString *output = nil;
    const unsigned char *pbegin = (const unsigned char *)[data bytes];
    const unsigned char *pend = pbegin + [data length];
    std::string str = EncodeBase58(pbegin, pend);
    output = [[NSString alloc] initWithCString:str.c_str()
                                      encoding:NSUTF8StringEncoding];
    return output;
}

- (nullable NSData *)decode:(NSString *)string {
    NSData *output = nil;
    const char *cstr = [string cStringUsingEncoding:NSUTF8StringEncoding];
    std::vector<unsigned char> vch;
    DecodeBase58(cstr, vch);
    std::string str(vch.begin(), vch.end());
    output = [[NSData alloc] initWithBytes:str.c_str() length:str.size()];
    return output;
}

@end

@interface Base64 : NSObject <MKMDataCoder>

@end

@implementation Base64

- (NSString *)encode:(NSData *)data {
    NSDataBase64EncodingOptions opt;
    opt = NSDataBase64EncodingEndLineWithCarriageReturn;
    return [data base64EncodedStringWithOptions:opt];
}

- (nullable NSData *)decode:(NSString *)string {
    NSDataBase64DecodingOptions opt;
    opt = NSDataBase64DecodingIgnoreUnknownCharacters;
    return [[NSData alloc] initWithBase64EncodedString:string options:opt];
}

@end

void DIMRegisterDataCoders(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([MKMHex getCoder] == nil) {
            [MKMHex setCoder:[[Hex alloc] init]];
        }
        if ([MKMBase58 getCoder] == nil) {
            [MKMBase58 setCoder:[[Base58 alloc] init]];
        }
        if ([MKMBase64 getCoder] == nil) {
            [MKMBase64 setCoder:[[Base64 alloc] init]];
        }
    });
}
