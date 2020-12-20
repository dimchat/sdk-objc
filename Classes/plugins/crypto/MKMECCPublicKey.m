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
//  MKMECCPublicKey.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/14.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import <secp256k1/secp256k1.h>

#import "MKMSecKeyHelper.h"

#import "MKMECCPublicKey.h"

@interface MKMECCPublicKey () {
    
    NSData *_data;
    
    NSUInteger _keySize;
    
    secp256k1_context *_context;
    secp256k1_pubkey *_pubkey;
}

@property (strong, nonatomic) NSData *data;

@property (nonatomic) NSUInteger keySize;

@property (nonatomic) secp256k1_context *context;
@property (nonatomic) secp256k1_pubkey *pubkey;

@end

@implementation MKMECCPublicKey

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)keyInfo {
    if (self = [super initWithDictionary:keyInfo]) {
        // lazy
        _data = nil;
        
        _keySize = 0;
        
        _context = NULL;
        _pubkey = NULL;
    }
    
    return self;
}

- (void)dealloc {
    
    // clear pubkey
    self.pubkey = NULL;
    // clear context
    self.context = NULL;
    
    //[super dealloc];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    MKMECCPublicKey *key = [super copyWithZone:zone];
    if (key) {
        key.data = _data;
        key.keySize = _keySize;
        key.context = _context;
        key.pubkey = _pubkey;
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
- (void)setContext:(secp256k1_context *)context {
    if (_context != context) {
        if (_context != NULL) {
            secp256k1_context_destroy(_context);
            _context = NULL;
        }
        if (context != NULL) {
            _context = secp256k1_context_clone(context);
        }
    }
}

- (secp256k1_pubkey *)pubkey {
    if (_pubkey == NULL) {
        NSData *data = self.data;
        _pubkey = malloc(sizeof(secp256k1_pubkey));
        memset(_pubkey, 0, sizeof(secp256k1_pubkey));
        int res = secp256k1_ec_pubkey_parse(self.context, _pubkey, data.bytes, data.length);
        NSAssert(res == 1, @"failed to parse ECC public key: %@", self);
    }
    return _pubkey;
}
- (void)setPubkey:(secp256k1_pubkey *)pubkey {
    if (_pubkey != pubkey) {
        if (_pubkey != NULL) {
            free(_pubkey);
            _pubkey = NULL;
        }
        if (pubkey != NULL) {
            _pubkey = malloc(sizeof(secp256k1_pubkey));
            memcpy(_pubkey, pubkey, sizeof(secp256k1_pubkey));
        }
    }
}

- (NSData *)data {
    if (!_data) {
        NSString *pem = [self objectForKey:@"data"];
        // check for raw data (33/65 bytes)
        NSUInteger len = pem.length;
        if (len == 66 || len == 130) {
            // Hex encode
            _data = MKMHexDecode(pem);
        } else if (len > 0) {
            // PEM
            _data = [MKMSecKeyHelper publicKeyDataFromContent:pem algorithm:ACAlgorithmECC];
            
            if (_data.length > 65) {
                // FIXME: X.509 -> Uncompressed Point
                NSAssert(_data.length == 88, @"unexpected ECC public key: %@", self);
                unsigned char *bytes = (unsigned char *)_data.bytes;
                if (bytes[88 - 65] == 0x04) {
                    _data = [_data subdataWithRange:NSMakeRange(88 - 65, 65)];
                } else {
                    @throw [NSException exceptionWithName:@"ECCKeyError" reason:@"not support" userInfo:self.dictionary];
                }
            }
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

- (BOOL)verify:(NSData *)data withSignature:(NSData *)signature {
    secp256k1_ecdsa_signature sig;
    secp256k1_ecdsa_signature_parse_der(self.context, &sig, signature.bytes, signature.length);
    secp256k1_ecdsa_signature lowerS;
    secp256k1_ecdsa_signature_normalize(self.context, &lowerS, &sig);
    NSData *hash = MKMSHA256Digest(data);
    return secp256k1_ecdsa_verify(self.context, &lowerS, hash.bytes, self.pubkey) == 1;
}

@end
