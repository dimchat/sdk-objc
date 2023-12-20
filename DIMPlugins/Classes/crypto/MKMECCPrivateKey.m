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
//  MKMECCPrivateKey.m
//  DIMPlugins
//
//  Created by Albert Moky on 2020/12/14.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import <string.h>

#import "uECC.h"

/**
 *  Refs:
 *      https://github.com/kmackay/micro-ecc
 *      https://github.com/digitalbitbox/mcu/blob/master/src/ecc.c
 */

static inline int ecc_sig_to_der(const uint8_t *sig, uint8_t *der)
{
    int i;
    uint8_t *p = der, *len, *len1, *len2;
    *p = 0x30;
    p++; // sequence
    *p = 0x00;
    len = p;
    p++; // len(sequence)

    *p = 0x02;
    p++; // integer
    *p = 0x00;
    len1 = p;
    p++; // len(integer)

    // process R
    i = 0;
    while (sig[i] == 0 && i < 32) {
        i++; // skip leading zeroes
    }
    if (sig[i] >= 0x80) { // put zero in output if MSB set
        *p = 0x00;
        p++;
        *len1 = *len1 + 1;
    }
    while (i < 32) { // copy bytes to output
        *p = sig[i];
        p++;
        *len1 = *len1 + 1;
        i++;
    }

    *p = 0x02;
    p++; // integer
    *p = 0x00;
    len2 = p;
    p++; // len(integer)

    // process S
    i = 32;
    while (sig[i] == 0 && i < 64) {
        i++; // skip leading zeroes
    }
    if (sig[i] >= 0x80) { // put zero in output if MSB set
        *p = 0x00;
        p++;
        *len2 = *len2 + 1;
    }
    while (i < 64) { // copy bytes to output
        *p = sig[i];
        p++;
        *len2 = *len2 + 1;
        i++;
    }

    *len = *len1 + *len2 + 4;
    return *len + 2;
}

#import "MKMSecKeyHelper.h"
#import "MKMECCPublicKey.h"

#import "MKMECCPrivateKey.h"

@interface MKMECCPrivateKey () {
    
    NSData *_data;
    
    NSUInteger _keySize;
    
    const uint8_t *_prikey;
    
    MKMECCPublicKey *_publicKey;
}

@property (strong, nonatomic) NSData *data;

@property (nonatomic) NSUInteger keySize;

@property (nonatomic) const uint8_t *prikey;

@property (strong, nonatomic, nullable) MKMECCPublicKey *publicKey;

@end

@implementation MKMECCPrivateKey

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)keyInfo {
    if (self = [super initWithDictionary:keyInfo]) {
        // lazy
        _data = nil;
        
        _keySize = 0;
        
        _prikey = NULL;
        
        _publicKey = nil;
    }
    
    return self;
}

- (void)dealloc {
    
    // clear prikey
    self.prikey = NULL;

    //[super dealloc];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    MKMECCPrivateKey *key = [super copyWithZone:zone];
    if (key) {
        key.data = _data;
        key.keySize = _keySize;
        key.prikey = _prikey;
        key.publicKey = _publicKey;
    }
    return key;
}

- (uECC_Curve)curve {
    // TODO: other curve?
    return uECC_secp256k1();
}

- (NSData *)data {
    if (!_data) {
        NSString *pem = [self objectForKey:@"data"];
        // check for raw data (32 bytes)
        NSUInteger len = pem.length;
        if (len == 64) {
            // Hex encode
            _data = MKMHexDecode(pem);
        } else if (len > 0) {
            // PEM
            _data = [MKMSecKeyHelper privateKeyDataFromContent:pem algorithm:MKMAlgorithm_ECC];
        } else {
            // generate it
            // TODO: check key size?
            uint8_t pubkey[64] = {0};
            uint8_t prikey[32] = {0};
            int res = uECC_make_key(pubkey, prikey, self.curve);
            if (res != 1) {
                NSAssert(false, @"failed to generate ECC private key");
                return nil;
            }
            _data = [[NSData alloc] initWithBytes:prikey length:32];
            [self setObject:MKMHexEncode(_data) forKey:@"data"];
        }
    }
    return _data;
}
- (void)setData:(NSData *)data {
    _data = data;
}

- (NSUInteger)keySize {
    if (_keySize == 0) {
        NSNumber *size = [self objectForKey:@"keySize"];
        if (size == nil) {
            _keySize = 256 / 8; // 32
        } else {
            _keySize = size.unsignedIntegerValue;
        }
    }
    return _keySize;
}

- (const uint8_t *)prikey {
    if (_prikey == NULL) {
        NSData *data = self.data;
        _prikey = data.bytes;
    }
    return _prikey;
}

- (MKMECCPublicKey *)publicKey {
    if (!_publicKey) {
        // get public key content from private key
        uint8_t pubkey[65] = {0};
        pubkey[0] = 0x04;
        int res = uECC_compute_public_key(self.prikey, pubkey+1, self.curve);
        if (res != 1) {
            NSAssert(false, @"failed to create ECC public key");
            return nil;
        }
        size_t len = sizeof(pubkey);
        
        NSData *data = [[NSData alloc] initWithBytes:pubkey length:len];
        NSString *hex = MKMHexEncode(data);
        NSDictionary *dict = @{@"algorithm":MKMAlgorithm_ECC,
                               @"data"     :hex,
                               @"curve"    :@"secp256k1",
                               @"digest"   :@"SHA256",
                               };
        _publicKey = [[MKMECCPublicKey alloc] initWithDictionary:dict];
    }
    return _publicKey;
}

- (void)setPublicKey:(nullable MKMECCPublicKey *)publicKey {
    _publicKey = publicKey;
}

- (NSData *)sign:(NSData *)data {
    NSData *hash = MKMSHA256Digest(data);
    uint8_t sig[64];
    int res = uECC_sign(self.prikey, hash.bytes, (unsigned)hash.length, sig, self.curve);
    if (res != 1) {
        NSAssert(false, @"failed to sign with ECC private key");
        return nil;
    }
    uint8_t vchSig[72];
    size_t nSigLen = ecc_sig_to_der(sig, vchSig);
    return [[NSData alloc] initWithBytes:vchSig length:nSigLen];
}

@end
