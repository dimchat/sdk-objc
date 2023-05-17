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
//  DIMDataDigesters.m
//  DIMPlugins
//
//  Created by Albert Moky on 2020/4/7.
//  Copyright © 2020 DIM Group. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "ripemd160.h"
#import "sha3.h"

#import "DIMDataDigesters.h"

@interface MD5 : NSObject <MKMDataDigester>

@end

@implementation MD5

- (NSData *)digest:(NSData *)data {
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5([data bytes], (CC_LONG)[data length], digest);
    return [[NSData alloc] initWithBytes:digest length:CC_MD5_DIGEST_LENGTH];
}

@end

@interface SHA1 : NSObject <MKMDataDigester>

@end

@implementation SHA1

- (NSData *)digest:(NSData *)data {
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([data bytes], (CC_LONG)[data length], digest);
    return [[NSData alloc] initWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

@end

@interface SHA256 : NSObject <MKMDataDigester>

@end

@implementation SHA256

- (NSData *)digest:(NSData *)data {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([data bytes], (CC_LONG)[data length], digest);
    return [[NSData alloc] initWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}

@end

@interface RIPEMD160 : NSObject <MKMDataDigester>

@end

@implementation RIPEMD160

- (NSData *)digest:(NSData *)data {
    const unsigned char *bytes = (const unsigned char *)[data bytes];
    unsigned char digest[CRIPEMD160::OUTPUT_SIZE];
    CRIPEMD160().Write(bytes, (size_t)[data length]).Finalize(digest);
    return [[NSData alloc] initWithBytes:digest length:CRIPEMD160::OUTPUT_SIZE];
}

@end

@interface KECCAK256 : NSObject <MKMDataDigester>

@end

@implementation KECCAK256

- (NSData *)digest:(NSData *)data {
    const unsigned char *bytes = (const unsigned char *)[data bytes];
    size_t len = data.length;
    unsigned char digest[32];
    sha3_256(digest, 32, bytes, len);
    return [[NSData alloc] initWithBytes:digest length:32];
}

@end

void DIMRegisterDataDigesters(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([MKMMD5 getDigester] == nil) {
            [MKMMD5 setDigester:[[MD5 alloc] init]];
        }
        if ([MKMSHA1 getDigester] == nil) {
            [MKMSHA1 setDigester:[[SHA1 alloc] init]];
        }
        if ([MKMSHA256 getDigester] == nil) {
            [MKMSHA256 setDigester:[[SHA256 alloc] init]];
        }
        if ([MKMRIPEMD160 getDigester] == nil) {
            [MKMRIPEMD160 setDigester:[[RIPEMD160 alloc] init]];
        }
        if ([MKMKECCAK256 getDigester] == nil) {
            [MKMKECCAK256 setDigester:[[KECCAK256 alloc] init]];
        }
    });
}
