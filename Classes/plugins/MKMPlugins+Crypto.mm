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
//  MKMPlugins+Crypto.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/12.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "DIMDataDigesters.h"
#import "DIMDataCoders.h"
#import "DIMDataParsers.h"

#import "MKMAESKey.h"
#import "MKMRSAPublicKey.h"
#import "MKMRSAPrivateKey.h"
#import "MKMECCPublicKey.h"
#import "MKMECCPrivateKey.h"

#import "MKMPlugins.h"

/*
 *  Symmetric key for broadcast message,
 *  which will do nothing when en/decoding message data
 *
 *      keyInfo format: {
 *          algorithm: "PLAIN",
 *          data     : ""       // empty data
 *      }
 */
@interface PlainKey : MKMSymmetricKey

+ (instancetype)sharedInstance;

@end

@implementation PlainKey

static PlainKey *s_sharedPlainKey = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!s_sharedPlainKey) {
            s_sharedPlainKey = [[PlainKey alloc] init];
        }
    });
    return s_sharedPlainKey;
}

- (instancetype)init {
    NSDictionary *dict = @{@"algorithm": MKMAlgorithmPlain};
    if (self = [super initWithDictionary:dict]) {
        //
    }
    return self;
}

- (NSData *)data {
    return nil;
}

- (NSData *)encrypt:(NSData *)plaintext {
    return plaintext;
}

- (nullable NSData *)decrypt:(NSData *)ciphertext {
    return ciphertext;
}

@end

@interface KeyFactory : NSObject

@property (readonly, strong, nonatomic) NSString *algorithm;

- (instancetype)initWithAlgorithm:(NSString *)algorithm;

@end

@implementation KeyFactory

- (instancetype)initWithAlgorithm:(NSString *)algorithm {
    if (self = [super init]) {
        _algorithm = algorithm;
    }
    return self;
}

@end

@interface SymmetricKeyFactory : KeyFactory <MKMSymmetricKeyFactory>

@end

@implementation SymmetricKeyFactory

- (id<MKMSymmetricKey>)generateSymmetricKey {
    if ([self.algorithm isEqualToString:MKMAlgorithmPlain]) {
        return [PlainKey sharedInstance];
    }
    NSMutableDictionary *key = [[NSMutableDictionary alloc] init];
    [key setObject:self.algorithm forKey:@"algorithm"];
    return [self parseSymmetricKey:key];
}

- (nullable id<MKMSymmetricKey>)parseSymmetricKey:(NSDictionary *)key {
    NSString *algorithm = [key objectForKey:@"algorithm"];
    // AES key
    if ([algorithm isEqualToString:MKMAlgorithmAES]) {
        return [[MKMAESKey alloc] initWithDictionary:key];
    }
    // Plain Key
    if ([algorithm isEqualToString:MKMAlgorithmPlain]) {
        return [PlainKey sharedInstance];
    }
    NSAssert(false, @"symmetric key algorithm (%@) not support yet", algorithm);
    return nil;
}

@end

@interface PublicKeyFactory : KeyFactory <MKMPublicKeyFactory>

@end

@implementation PublicKeyFactory

- (nullable id<MKMPublicKey>)parsePublicKey:(NSDictionary *)key {
    // RSA key
    if ([self.algorithm isEqualToString:MKMAlgorithmRSA]) {
        return [[MKMRSAPublicKey alloc] initWithDictionary:key];
    }
    // ECC Key
    if ([self.algorithm isEqualToString:MKMAlgorithmECC]) {
        return [[MKMECCPublicKey alloc] initWithDictionary:key];
    }
    NSAssert(false, @"public key algorithm (%@) not support yet", self.algorithm);
    return nil;
}

@end

@interface PrivateKeyFactory : KeyFactory <MKMPrivateKeyFactory>

@end

@implementation PrivateKeyFactory

- (id<MKMPrivateKey>)generatePrivateKey {
    NSMutableDictionary *key = [[NSMutableDictionary alloc] init];
    [key setObject:self.algorithm forKey:@"algorithm"];
    return [self parsePrivateKey:key];
}

- (nullable id<MKMPrivateKey>)parsePrivateKey:(NSDictionary *)key {
    // RSA key
    if ([self.algorithm isEqualToString:MKMAlgorithmRSA]) {
        return [[MKMRSAPrivateKey alloc] initWithDictionary:key];
    }
    // ECC Key
    if ([self.algorithm isEqualToString:MKMAlgorithmECC]) {
        return [[MKMECCPrivateKey alloc] initWithDictionary:key];
    }
    NSAssert(false, @"private key algorithm (%@) not support yet", self.algorithm);
    return nil;
}

@end

@implementation MKMPlugins (Crypto)

+ (void)registerKeyFactories {
    // Symmetric key
    MKMSymmetricKeySetFactory(MKMAlgorithmAES,
                              [[SymmetricKeyFactory alloc] initWithAlgorithm:MKMAlgorithmAES]);
    MKMSymmetricKeySetFactory(MKMAlgorithmPlain,
                              [[SymmetricKeyFactory alloc] initWithAlgorithm:MKMAlgorithmPlain]);

    // public key
    MKMPublicKeySetFactory(MKMAlgorithmRSA,
                           [[PublicKeyFactory alloc] initWithAlgorithm:MKMAlgorithmRSA]);
    MKMPublicKeySetFactory(MKMAlgorithmECC,
                           [[PublicKeyFactory alloc] initWithAlgorithm:MKMAlgorithmECC]);

    // private key
    MKMPrivateKeySetFactory(MKMAlgorithmRSA,
                            [[PrivateKeyFactory alloc] initWithAlgorithm:MKMAlgorithmRSA]);
    MKMPrivateKeySetFactory(MKMAlgorithmECC,
                            [[PrivateKeyFactory alloc] initWithAlgorithm:MKMAlgorithmECC]);
}

@end

#pragma mark -

@implementation MKMPlugins (DataCoder)

+ (void)registerDataCoders {
    DIMRegisterDataCoders();
    DIMRegisterDataParsers();
}

@end

@implementation MKMPlugins (Digest)

+ (void)registerDigesters {
    DIMRegisterDataDigesters();
}

@end
