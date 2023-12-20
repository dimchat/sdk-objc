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
//  MKMRSAPrivateKey.m
//  MingKeMing
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "MKMSecKeyHelper.h"
#import "MKMRSAPublicKey.h"

#import "MKMRSAPrivateKey.h"

@interface MKMRSAPrivateKey () {
    
    NSData *_data;
    
    NSUInteger _keySize;
    
    SecKeyRef _privateKeyRef;
    
    MKMRSAPublicKey *_publicKey;
}

@property (strong, nonatomic) NSData *data;

@property (nonatomic) NSUInteger keySize;

@property (nonatomic) SecKeyRef privateKeyRef;

@property (strong, nonatomic, nullable) MKMRSAPublicKey *publicKey;

@end

@implementation MKMRSAPrivateKey

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)keyInfo {
    if (self = [super initWithDictionary:keyInfo]) {
        // lazy
        _data = nil;
        
        _keySize = 0;
        
        _privateKeyRef = NULL;
        
        _publicKey = nil;
    }
    
    return self;
}

- (void)dealloc {
    
    // clear key ref
    self.privateKeyRef = NULL;
    
    //[super dealloc];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    MKMRSAPrivateKey *key = [super copyWithZone:zone];
    if (key) {
        key.data = _data;
        key.keySize = _keySize;
        key.privateKeyRef = _privateKeyRef;
        key.publicKey = _publicKey;
    }
    return key;
}

- (void)setData:(NSData *)data {
    _data = data;
}

- (NSData *)data {
    if (!_data) {
        NSString *pem = [self objectForKey:@"data"];
        _data = [MKMSecKeyHelper privateKeyDataFromContent:pem algorithm:MKMAlgorithm_RSA];
    }
    return _data;
}

- (NSUInteger)keySize {
    if (_keySize == 0) {
        // get from key
        if (_privateKeyRef || [self objectForKey:@"data"]) {
            size_t bytes = SecKeyGetBlockSize(self.privateKeyRef);
            _keySize = bytes * sizeof(uint8_t);
        } else {
            // get from dictionary
            NSNumber *size = [self objectForKey:@"keySize"];
            if (size == nil) {
                _keySize = 1024 / 8; // 128
            } else {
                _keySize = size.unsignedIntegerValue;
            }
        }
    }
    return _keySize;
}

- (void)setPrivateKeyRef:(SecKeyRef)privateKeyRef {
    if (_privateKeyRef != privateKeyRef) {
        if (_privateKeyRef) {
            CFRelease(_privateKeyRef);
            _privateKeyRef = NULL;
        }
        if (privateKeyRef) {
            _privateKeyRef = (SecKeyRef)CFRetain(privateKeyRef);
        }
    }
}

- (SecKeyRef)privateKeyRef {
    if (!_privateKeyRef) {
        // 1. get private key from data content
        NSString *pem = [self objectForKey:@"data"];
        if (pem) {
            // key from data
            NSData *data = [MKMSecKeyHelper privateKeyDataFromContent:pem algorithm:MKMAlgorithm_RSA];
            _privateKeyRef = [MKMSecKeyHelper privateKeyFromData:data algorithm:MKMAlgorithm_RSA];
            return _privateKeyRef;
        }
        
        // 2. generate key pairs
        NSAssert(!_publicKey, @"RSA public key should not be set yet");
        
        // 2.1. key size
        NSUInteger keySize = self.keySize;
        // 2.2. prepare parameters
        NSDictionary *params;
        params = @{(id)kSecAttrKeyType      :(id)kSecAttrKeyTypeRSA,
                   (id)kSecAttrKeySizeInBits:@(keySize * 8),
                   //(id)kSecAttrIsPermanent:@YES,
                   };
        // 2.3. generate
        CFErrorRef error = NULL;
        _privateKeyRef = SecKeyCreateRandomKey((CFDictionaryRef)params,
                                               &error);
        if (error) {
            NSAssert(!_privateKeyRef, @"RSA key ref should be empty when failed");
            NSAssert(false, @"RSA failed to generate key: %@", error);
            CFRelease(error);
            error = NULL;
            return nil;
        }
        NSAssert(_privateKeyRef, @"RSA private key ref should be set here");
        
        // 2.4. key to data
        pem = [MKMSecKeyHelper serializePrivateKey:_privateKeyRef algorithm:MKMAlgorithm_RSA];
        [self setObject:pem forKey:@"data"];
        
        // 3. other parameters
        [self setObject:@"ECB" forKey:@"mode"];
        [self setObject:@"PKCS1" forKey:@"padding"];
        [self setObject:@"SHA256" forKey:@"digest"];
    }
    return _privateKeyRef;
}

- (MKMRSAPublicKey *)publicKey {
    if (!_publicKey) {
        // get public key content from private key
        SecKeyRef publicKeyRef = SecKeyCopyPublicKey(self.privateKeyRef);
        NSString *pem = [MKMSecKeyHelper serializePublicKey:publicKeyRef algorithm:MKMAlgorithm_RSA];
        NSDictionary *dict = @{@"algorithm":MKMAlgorithm_RSA,
                               @"data"     :pem,
                               @"mode"     :@"ECB",
                               @"padding"  :@"PKCS1",
                               @"digest"   :@"SHA256",
                               };
        _publicKey = [[MKMRSAPublicKey alloc] initWithDictionary:dict];
    }
    return _publicKey;
}

- (void)setPublicKey:(nullable MKMRSAPublicKey *)publicKey {
    _publicKey = publicKey;
}

#pragma mark - Protocol

- (nullable NSData *)decrypt:(NSData *)ciphertext params:(nullable NSDictionary *)extra {
    if (ciphertext.length != (self.keySize)) {
        NSLog(@"[RSA] ciphertext length not correct: %lu", ciphertext.length);
        return nil;
    }
    NSData *plaintext = nil;
    
    @try {
        SecKeyRef keyRef = self.privateKeyRef;
        NSAssert(keyRef != NULL, @"RSA private key error");
        
        CFErrorRef error = NULL;
        SecKeyAlgorithm alg = kSecKeyAlgorithmRSAEncryptionPKCS1;
        CFDataRef data;
        data = SecKeyCreateDecryptedData(keyRef,
                                         alg,
                                         (CFDataRef)ciphertext,
                                         &error);
        if (error) {
            NSLog(@"[RSA] failed to decrypt: %@", error);
            NSAssert(!data, @"RSA decrypted data should be empty when failed");
            //NSAssert(false, @"RSA decrypt error: %@", error);
            CFRelease(error);
            error = NULL;
        } else {
            NSAssert(data, @"RSA decrypted data should not be empty");
            plaintext = (__bridge_transfer NSData *)data;
        }
    } @catch (NSException *exception) {
        NSLog(@"[RSA] failed to decrypt: %@", exception);
    } @finally {
        //
    }
    
    //NSAssert(plaintext, @"RSA decrypt failed");
    return plaintext;
}

- (NSData *)sign:(NSData *)data {
    NSAssert(self.privateKeyRef != NULL, @"RSA private key cannot be empty");
    NSAssert(data.length > 0, @"RSA data cannot be empty");
    NSData *signature = nil;
    
    CFErrorRef error = NULL;
    SecKeyAlgorithm alg = kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256;
    CFDataRef CT;
    CT = SecKeyCreateSignature(self.privateKeyRef,
                               alg,
                               (CFDataRef)data,
                               &error);
    if (error) {
        NSLog(@"[RSA] failed to sign: %@", error);
        NSAssert(!CT, @"RSA signature should be empty when failed");
        NSAssert(false, @"RSA sign error: %@", error);
        CFRelease(error);
        error = NULL;
    } else {
        NSAssert(CT, @"RSA signature should not be empty");
        signature = (__bridge_transfer NSData *)CT;
    }
    
    NSAssert(signature, @"RSA sign failed");
    return signature;
}

- (BOOL)matchEncryptKey:(id<MKMEncryptKey>)pKey {
    return DIMCryptoMatchEncryptKey(pKey, self);
}

@end
