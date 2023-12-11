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
//  DIMPlugins
//
//  Created by Albert Moky on 2020/12/14.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "uECC.h"

#import "MKMSecKeyHelper.h"

#import "MKMECCPublicKey.h"

/**
 *  Refs:
 *      https://github.com/kmackay/micro-ecc
 *      https://github.com/digitalbitbox/mcu/blob/master/src/ecc.c
 */

static int trim_to_32_bytes(const uint8_t *src, int src_len, uint8_t *dst)
{
    int dst_offset;
    while (*src == '\0' && src_len > 0) {
        src++;
        src_len--;
    }
    if (src_len > 32 || src_len < 1) {
        return 1;
    }
    dst_offset = 32 - src_len;
    memset(dst, 0, dst_offset);
    memcpy(dst + dst_offset, src, src_len);
    return 0;
}

static inline int ecc_der_to_sig(const uint8_t *der, int der_len, uint8_t *sig_64)
{
    /*
     * Structure is:
     *   0x30 0xNN  SEQUENCE + s_length
     *   0x02 0xNN  INTEGER + r_length
     *   0xAA 0xBB  ..   r_length bytes of "r" (offset 4)
     *   0x02 0xNN  INTEGER + s_length
     *   0xMM 0xNN  ..   s_length bytes of "s" (offset 6 + r_len)
     */
    int seq_len;
    //uint8_t r_bytes[32];
    //uint8_t s_bytes[32];
    int r_len;
    int s_len;

    //memset(r_bytes, 0, sizeof(r_bytes));
    //memset(s_bytes, 0, sizeof(s_bytes));

    /*
     * Must have at least:
     * 2 bytes sequence header and length
     * 2 bytes R integer header and length
     * 1 byte of R
     * 2 bytes S integer header and length
     * 1 byte of S
     *
     * 8 bytes total
     */
    if (der_len < 8 || der[0] != 0x30 || der[2] != 0x02) {
        return 1;
    }

    seq_len = der[1];
    if ((seq_len <= 0) || (seq_len + 2 != der_len)) {
        return 1;
    }

    r_len = der[3];
    /*
     * Must have at least:
     * 2 bytes for R header and length
     * 2 bytes S integer header and length
     * 1 byte of S
     */
    if ((r_len < 1) || (r_len > seq_len - 5) || (der[4 + r_len] != 0x02)) {
        return 1;
    }
    s_len = der[5 + r_len];

    /**
     * Must have:
     * 2 bytes for R header and length
     * r_len bytes for R
     * 2 bytes S integer header and length
     */
    if ((s_len < 1) || (s_len != seq_len - 4 - r_len)) {
        return 1;
    }

    /*
     * ASN.1 encoded integers are zero-padded for positive integers. Make sure we have
     * a correctly-sized buffer and that the resulting integer isn't too large.
     */
    if (trim_to_32_bytes(&der[4], r_len, sig_64) ||
            trim_to_32_bytes(&der[6 + r_len], s_len, sig_64 + 32)) {
        return 1;
    }

    return 0;
}

@interface MKMECCPublicKey () {
    
    NSData *_data;
    
    NSUInteger _keySize;
    
    const uint8_t *_pubkey;
}

@property (strong, nonatomic) NSData *data;

@property (nonatomic) NSUInteger keySize;

@property (nonatomic) const uint8_t *pubkey;

@end

@implementation MKMECCPublicKey

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)keyInfo {
    if (self = [super initWithDictionary:keyInfo]) {
        // lazy
        _data = nil;
        
        _keySize = 0;
        
        _pubkey = NULL;
    }
    
    return self;
}

- (void)dealloc {
    
    // clear pubkey
    self.pubkey = NULL;
    
    //[super dealloc];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    MKMECCPublicKey *key = [super copyWithZone:zone];
    if (key) {
        key.data = _data;
        key.keySize = _keySize;
        key.pubkey = _pubkey;
    }
    return key;
}

- (uECC_Curve)curve {
    // TODO: other curve?
    return uECC_secp256k1();
}

- (const uint8_t *)pubkey {
    if (_pubkey == NULL) {
        NSData *data = self.data;
        _pubkey = data.bytes;
        // TODO: check for compressed key
        if (data.length == 65) {
            _pubkey = _pubkey+1;
        }
    }
    return _pubkey;
}
- (void)setPubkey:(const uint8_t *)pubkey {
    if (_pubkey != pubkey) {
        if (_pubkey != NULL) {
            //free(_pubkey);
            _pubkey = NULL;
        }
        if (pubkey != NULL) {
            _pubkey = pubkey;
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
            _data = [MKMSecKeyHelper publicKeyDataFromContent:pem algorithm:MKMAlgorithm_ECC];
            
            if (_data.length > 65) {
                // FIXME: X.509 -> Uncompressed Point
                NSAssert(_data.length == 88, @"unexpected ECC public key: %@", self);
                unsigned char *bytes = (unsigned char *)_data.bytes;
                if (bytes[88 - 65] == 0x04) {
                    _data = [_data subdataWithRange:NSMakeRange(88 - 65, 65)];
                } else {
                    //@throw [NSException exceptionWithName:@"ECCKeyError" reason:@"not support" userInfo:self.dictionary];
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
    NSData *hash = MKMSHA256Digest(data);
    uint8_t sig[64];
    @try {
        int res = ecc_der_to_sig(signature.bytes, (int)signature.length, sig);
        if (res != 0) {
            NSAssert(false, @"failed to verify with ECC private key");
            return NO;
        }
        return uECC_verify(self.pubkey, hash.bytes, (unsigned)hash.length, sig, self.curve);
    } @catch (NSException *exception) {
        NSLog(@"[ECC] failed to verify: %@", exception);
    } @finally {
        //
    }
}

@end
