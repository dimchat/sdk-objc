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

@property (strong, nonatomic) NSData *data; // Key Data
@property (strong, nonatomic) NSData *iv;   // Initialization Vector

@end

@implementation MKMAESKey

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)keyInfo {
    if (self = [super initWithDictionary:keyInfo]) {
        // lazy
        _data = nil;
        _iv = nil;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MKMAESKey *key = [super copyWithZone:zone];
    if (key) {
        key.data = _data;
        key.iv = _iv;
    }
    return key;
}

- (NSUInteger)keySize {
    // TODO: get from key data
    //...
    
    // get from dictionary
    NSNumber *size = [_storeDictionary objectForKey:@"keySize"];
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
    NSNumber *size = [_storeDictionary objectForKey:@"blockSize"];
    if (size == nil) {
        return kCCBlockSizeAES128; // 16
    } else {
        return size.unsignedIntegerValue;
    }
}

- (void)setData:(NSData *)data {
    _data = data;
}

- (NSData *)data {
    while (!_data) {
        NSString *PW;
        
        // data
        PW = [_storeDictionary objectForKey:@"data"];
        if (PW) {
            _data = MKMBase64Decode(PW);
            break;
        }
        
        //
        // key data empty? generate new key info
        //
        
        // random password
        NSUInteger keySize = [self keySize];
        _data = random_data(keySize);
        PW = MKMBase64Encode(_data);
        [_storeDictionary setObject:PW forKey:@"data"];
        
        // random initialization vector
        NSUInteger blockSize = [self blockSize];
        _iv = random_data(blockSize);
        NSString *IV = MKMBase64Encode(_iv);
        [_storeDictionary setObject:IV forKey:@"iv"];
        
        // other parameters
        //[_storeDictionary setObject:@"CBC" forKey:@"mode"];
        //[_storeDictionary setObject:@"PKCS7" forKey:@"padding"];
        
        break;
    }
    return _data;
}

- (NSData *)iv {
    if (!_iv) {
        NSString *iv = [_storeDictionary objectForKey:@"iv"];
        _iv = MKMBase64Decode(iv);
    }
    return _iv;
}

#pragma mark - Protocol

- (NSData *)encrypt:(NSData *)plaintext {
    NSData *ciphertext = nil;
    NSAssert(self.keySize == kCCKeySizeAES256, @"only support AES-256 now");
    
    // AES encrypt algorithm
    if (self.keySize == kCCKeySizeAES256) {
        ciphertext = [plaintext AES256EncryptWithKey:self.data
                                initializationVector:self.iv];
    }
    
    return ciphertext;
}

- (nullable NSData *)decrypt:(NSData *)ciphertext {
    NSData *plaintext = nil;
    NSAssert(self.keySize == kCCKeySizeAES256, @"only support AES-256 now");
    
    // AES decrypt algorithm
    if (self.keySize == kCCKeySizeAES256) {
        plaintext = [ciphertext AES256DecryptWithKey:self.data
                                initializationVector:self.iv];
    }
    
    return plaintext;
}

@end
