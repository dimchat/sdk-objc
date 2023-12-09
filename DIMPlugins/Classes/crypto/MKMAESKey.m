// license: https://mit-license.org
//
//  Ming-Ke-Ming : Decentralized User Identity Authentication
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
//  MKMAESKey.m
//  MingKeMing
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>

#import "NSData+Crypto.h"

#import "MKMAESKey.h"

static inline NSData *random_data(NSUInteger size) {
    unsigned char *buf = malloc(size * sizeof(unsigned char));
    arc4random_buf(buf, size);
    return [[NSData alloc] initWithBytesNoCopy:buf length:size freeWhenDone:YES];
}

@interface MKMAESKey ()

@property (readonly, nonatomic) NSUInteger keySize;
@property (readonly, nonatomic) NSUInteger blockSize;

@property (strong, nonatomic) id<MKMTransportableData> keyData;  // Key Data
@property (strong, nonatomic) id<MKMTransportableData> ivData;   // Initialization Vector

@end

@implementation MKMAESKey

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)keyInfo {
    if (self = [super initWithDictionary:keyInfo]) {
        if ([self objectForKey:@"data"]) {
            // lazy
            _keyData = nil;
            _ivData = nil;
        } else {
            // TODO: check algorithm parameters
            // 1. check mode = 'CBC'
            // 2. check padding = 'PKCS7Padding'
            [self _generate];
        }
    }
    
    return self;
}

- (void)_generate {
    id<MKMTransportableData> ted;
    
    //
    // key data empty? generate new key info
    //
    
    // random password
    NSUInteger keySize = [self keySize];
    NSData *pw = random_data(keySize);
    ted = MKMTransportableDataCreate(pw, nil);
    [self setObject:ted.object forKey:@"data"];
    _keyData = ted;
    
    // random initialization vector
    NSUInteger blockSize = [self blockSize];
    NSData *iv = random_data(blockSize);
    ted = MKMTransportableDataCreate(iv, nil);
    [self setObject:ted.object forKey:@"iv"];
    _ivData = ted;
    
    // other parameters
    //[self setObject:@"CBC" forKey:@"mode"];
    //[self setObject:@"PKCS7" forKey:@"padding"];
    
}

- (id)copyWithZone:(nullable NSZone *)zone {
    MKMAESKey *key = [super copyWithZone:zone];
    if (key) {
        key.keyData = _keyData;
        key.ivData = _ivData;
    }
    return key;
}

- (NSUInteger)keySize {
    // TODO: get from key data
    //...
    
    // get from dictionary
    NSNumber *size = [self objectForKey:@"keySize"];
    if (size == nil) {
        return kCCKeySizeAES256; // 32
    } else {
        return size.unsignedIntegerValue;
    }
}

- (NSUInteger)blockSize {
    // TODO: get from iv data
    //...
    
    // get from dictionary
    NSNumber *size = [self objectForKey:@"blockSize"];
    if (size == nil) {
        return kCCBlockSizeAES128; // 16
    } else {
        return size.unsignedIntegerValue;
    }
}

- (id<MKMTransportableData>)ivData {
    id<MKMTransportableData> ted = _ivData;
    if (!ted) {
        id base64 = [self objectForKey:@"iv"];
        if (base64) {
            _ivData = ted = MKMTransportableDataParse(base64);
            NSAssert(ted, @"iv data error: %@", base64);
        } else {
            // zero iv
        }
    }
    return ted;
}
- (void)_setInitVector:(id)base64 {
    // if new iv not exists, this will erase the decoded ivData,
    // and cause reloading from dictionary again.
    _ivData = MKMTransportableDataParse(base64);
}

- (id<MKMTransportableData>)keyData {
    id<MKMTransportableData> ted = _keyData;
    if (!ted) {
        id base64 = [self objectForKey:@"data"];
        if (base64) {
            _keyData = ted = MKMTransportableDataParse(base64);
            NSAssert(ted, @"key data error: %@", base64);
        } else {
            NSAssert(false, @"key data not found: %@", self);
        }
    }
    return ted;
}

- (NSString *)_ivString {
    id<MKMTransportableData> ted = [self ivData];
    NSString *base64 = [ted string];
    // TODO: trim base64 string
    return base64;
}

- (NSString *)_keyString {
    id<MKMTransportableData> ted = [self keyData];
    NSString *base64 = [ted string];
    // TODO: trim base64 string
    return base64;
}

- (NSData *)data {
    id<MKMTransportableData> ted = [self keyData];
    return [ted data];
}

- (NSData *)iv {
    id<MKMTransportableData> ted = [self ivData];
    return [ted data];
}

#pragma mark - Protocol

- (NSData *)encrypt:(NSData *)plaintext params:(nullable NSMutableDictionary<NSString *,id> *)extra {
    NSAssert(self.keySize == kCCKeySizeAES256, @"only support AES-256 now");
    // 0. TODO: random new 'IV'
    NSString *base64 = [self _ivString];
    [extra setObject:base64 forKey:@"IV"];
    // 1. get key data & initial vector
    NSData *key = [self data];
    NSData *iv = [self iv];
    // 2. try to encrypt
    NSData *ciphertext = nil;
    @try {
        ciphertext = [plaintext AES256EncryptWithKey:key
                                initializationVector:iv];
    } @catch (NSException *exception) {
        NSLog(@"[AES] failed to encrypt: %@", exception);
    } @finally {
        //
    }
    NSAssert(ciphertext, @"AES encrypt failed");
    return ciphertext;
}

- (nullable NSData *)decrypt:(NSData *)ciphertext params:(nullable NSDictionary<NSString *,id> *)extra {
    NSAssert(self.keySize == kCCKeySizeAES256, @"only support AES-256 now");
    // 0. get 'IV' from extra params
    id base64 = [extra objectForKey:@"IV"];
    if (base64) {
        [self _setInitVector:base64];
    }
    // 1. get key data & initial vector
    NSData *key = [self data];
    NSData *iv = [self iv];
    // 2. try to decrypt
    NSData *plaintext = nil;
    @try {
        // AES decrypt algorithm
        plaintext = [ciphertext AES256DecryptWithKey:key
                                initializationVector:iv];
    } @catch (NSException *exception) {
        NSLog(@"[AES] failed to decrypt: %@", exception);
    } @finally {
        //
    }
    //NSAssert(plaintext, @"AES decrypt failed");
    return plaintext;
}

@end
