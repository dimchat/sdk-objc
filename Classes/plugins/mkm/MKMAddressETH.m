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
//  MKMAddressETH.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/15.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "MKMAddressETH.h"

// https://eips.ethereum.org/EIPS/eip-55
static inline NSString *eip55(NSString *hex) {
    NSData *utf8 = MKMUTF8Encode(hex);
    NSData *digest = MKMKECCAK256Digest(utf8);
    UInt8 *origin = (UInt8 *)utf8.bytes;
    UInt8 *hash = (UInt8 *)digest.bytes;
    UInt8 buffer[40];
    UInt8 ch;
    for (int i = 0; i < 40; ++i) {
        ch = origin[i];
        if (ch > '9') {
            // check for each 4 bits in the hash table
            // if the first bit is '1',
            //     change the character to uppercase
            ch -= (hash[i >> 1] << (i << 2 & 4) & 0x80) >> 2;
        }
        buffer[i] = ch;
    }
    return [[NSString alloc] initWithBytes:buffer length:40 encoding:NSUTF8StringEncoding];
}

@implementation MKMAddressETH

+ (instancetype)generate:(NSData *)fingerprint {
    if (fingerprint.length == 65) {
        fingerprint = [fingerprint subdataWithRange:NSMakeRange(1, 64)];
    }
    NSAssert(fingerprint.length == 64, @"key data length error: %lu", fingerprint.length);
    // 1. digest = keccak256(fingerprint);
    NSData *digest = MKMKECCAK256Digest(fingerprint);
    // 2. address = hex_encode(digest.suffix(20));
    NSData *tail = [digest subdataWithRange:NSMakeRange(digest.length - 20, 20)];
    NSString *hex = MKMHexEncode(tail);
    NSString *address = [NSString stringWithFormat:@"0x%@", eip55(hex)];
    return [[self alloc] initWithString:address network:MKMNetwork_Main];
}

+ (instancetype)parse:(NSString *)string {
    NSUInteger len = string.length;
    if (len != 42) {
        return nil;
    }
    NSData *data = MKMUTF8Encode(string);
    UInt8 *buffer = (UInt8 *)data.bytes;
    if (buffer[0] != '0' || buffer[1] != 'x') {
        return nil;
    }
    UInt8 ch;
    for (int i = 2; i < len; ++i) {
        ch = buffer[i];
        if (ch >= '0' && ch <= '9') {
            continue;
        }
        if (ch >= 'A' && ch <= 'F') {
            continue;
        }
        if (ch >= 'a' && ch <= 'f') {
            continue;
        }
        return nil;
    }
    return [[self alloc] initWithString:string network:MKMNetwork_Main];
}

+ (NSString *)validateAddress:(NSString *)address {
    address = [address lowercaseString];
    if ([address hasPrefix:@"0x"]) {
        address = [address substringFromIndex:2];
    }
    return [NSString stringWithFormat:@"0x%@", eip55(address)];
}

+ (BOOL)isValidate:(NSString *)address {
    NSUInteger len = address.length;
    if (len != 42) {
        return NO;
    }
    NSData *data = MKMUTF8Encode(address);
    UInt8 *buffer = (UInt8 *)data.bytes;
    if (buffer[0] != '0' || buffer[1]!= 'x') {
        return false;
    }
    char ch;
    for (int i = 2; i < 42; ++i) {
        ch = buffer[i];
        if (ch >= '0' && ch <= '9') {
            continue;
        }
        if (ch >= 'A' && ch <= 'Z') {
            continue;
        }
        if (ch >= 'a' && ch <= 'z') {
            continue;
        }
        // unexpected character
        return false;
    }
    NSString *hex = [address substringFromIndex:2];
    return [eip55([hex lowercaseString]) isEqualToString:hex];
}

@end
