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
//  MKMAddressBTC.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/12.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "MKMAddressBTC.h"

/**
 *  BTC address algorithm:
 *      digest     = ripemd160(sha256(fingerprint));
 *      check_code = sha256(sha256(network + digest)).prefix(4);
 *      addr       = base58_encode(network + digest + check_code);
 */
@implementation MKMAddressBTC

static inline NSData *check_code(NSData *data) {
    assert([data length] == 21);
    NSData *sha256d = MKMSHA256Digest(MKMSHA256Digest(data));
    return [sha256d subdataWithRange:NSMakeRange(0, 4)];
}

+ (instancetype)generate:(NSData *)fingerprint network:(UInt8)type {
    // 1. digest = ripemd160(sha256(fingerprint))
    NSData *digest = MKMRIPEMD160Digest(MKMSHA256Digest(fingerprint));
    // 2. head = network + digest
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:&type length:1];
    [data appendData:digest];
    // 3. cc = sha256(sha256(head)).prefix(4)
    NSData *cc = check_code(data);
    // 4. addr = base58_encode(_h + cc)
    [data appendData:cc];
    NSString *string = MKMBase58Encode(data);
    return [[self alloc] initWithString:string network:type];
}

+ (instancetype)parse:(NSString *)string {
    if (string.length < 26) {
        return nil;
    }
    // decode
    NSData *data = MKMBase58Decode(string);
    if (data.length != 25) {
        return nil;
    }
    // Check Code
    NSData *prefix = [data subdataWithRange:NSMakeRange(0, 21)];
    NSData *suffix = [data subdataWithRange:NSMakeRange(21, 4)];
    NSData *cc = check_code(prefix);
    if ([cc isEqualToData:suffix]) {
        UInt8 *bytes = (UInt8 *)data.bytes;
        return [[self alloc] initWithString:string network:bytes[0]];
    } else {
        return nil;
    }
}

@end
