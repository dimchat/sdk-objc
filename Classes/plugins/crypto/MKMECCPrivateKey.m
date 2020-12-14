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
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/14.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import <secp256k1/secp256k1.h>

#import "MKMECCHelper.h"
#import "MKMECCPublicKey.h"

#import "MKMECCPrivateKey.h"

@interface MKMECCPrivateKey () {
    
    NSData *_data;
    
    NSUInteger _keySize;
    
    secp256k1_context *_context;
    
    MKMECCPublicKey *_publicKey;
}

@property (strong, nonatomic) NSData *data;

@property (nonatomic) NSUInteger keySize;

@property (nonatomic) secp256k1_context *context;

@property (strong, atomic, nullable) MKMECCPublicKey *publicKey;

@end

@implementation MKMECCPrivateKey

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)keyInfo {
    if (self = [super initWithDictionary:keyInfo]) {
        // lazy
        _data = nil;
        
        _keySize = 0;
        
        _context = NULL;
        
        _publicKey = nil;
    }
    
    return self;
}

- (void)dealloc {
    
    // clear context
    if (_context) {
        secp256k1_context_destroy(_context);
        _context = NULL;
    }
    
    //[super dealloc];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    MKMECCPrivateKey *key = [super copyWithZone:zone];
    if (key) {
        key.data = _data;
        key.keySize = _keySize;
        key.publicKey = _publicKey;
        key.context = _context;
    }
    return key;
}

- (secp256k1_context *)context {
    if (_context == NULL) {
        unsigned int flags = SECP256K1_CONTEXT_VERIFY | SECP256K1_CONTEXT_SIGN;
        _context = secp256k1_context_create(flags);
    }
    return _context;
}

- (void)setData:(NSData *)data {
    _data = data;
}

- (NSData *)data {
    if (!_data) {
        NSString *pem = [self objectForKey:@"data"];
        NSUInteger len = pem.length;
        if (len == 64) {
            // Hex encode
            _data = MKMHexDecode(pem);
        } else if (len > 0) {
            // PEM
            NSString *base64 = ECCPrivateKeyContentFromNSString(pem);
            _data = MKMBase64Decode(base64);
        } else {
            // generate it
            unsigned char seed[32];
            arc4random_buf(seed, 32);
            int res = secp256k1_context_randomize(self.context, seed);
            NSAssert(res == 1, @"failed to generate ECC private key");
            _data = [[NSData alloc] initWithBytes:seed length:32];
            [self setObject:MKMHexEncode(_data) forKey:@"data"];
        }
    }
    return _data;
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

- (nullable __kindof MKMPublicKey *)publicKey {
    if (!_publicKey) {
        // get public key content from private key
        secp256k1_pubkey pKey;
        memset(&pKey, 0, sizeof(pKey));
        int res = secp256k1_ec_pubkey_create(self.context, &pKey, self.data.bytes);
        NSAssert(res == 1, @"failed to create ECC public key");
        unsigned char result[65] = {0};
        size_t len = sizeof(result);
        secp256k1_ec_pubkey_serialize(self.context, result, &len, &pKey, SECP256K1_EC_COMPRESSED);
        
        NSData *data = [[NSData alloc] initWithBytes:result length:len];
        NSString *base64 = MKMBase64Encode(data);
        NSString *pem = NSStringFromECCPublicKeyContent(base64);
        NSDictionary *dict = @{@"algorithm":ACAlgorithmECC,
                               @"data"     :pem,
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
    secp256k1_context *ctx = [self context];
    secp256k1_ecdsa_signature sig;
    secp256k1_ecdsa_sign(ctx, &sig, hash.bytes, self.data.bytes,
                         secp256k1_nonce_function_rfc6979, NULL);
    return [[NSData alloc] initWithBytes:sig.data length:sizeof(sig.data)];
}

@end
