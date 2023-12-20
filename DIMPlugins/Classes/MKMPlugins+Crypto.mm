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
//  DIMPlugins
//
//  Created by Albert Moky on 2020/12/12.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "DIMDataDigesters.h"
#import "DIMDataCoders.h"
#import "DIMDataParsers.h"
#import "DIMBaseDataFactory.h"
#import "DIMBaseFileFactory.h"

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
@interface PlainKey : DIMSymmetricKey

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
    NSDictionary *dict = @{@"algorithm": MKMAlgorithm_Plain};
    if (self = [super initWithDictionary:dict]) {
        //
    }
    return self;
}

- (NSData *)data {
    return nil;
}

- (NSData *)encrypt:(NSData *)plaintext
             params:(nullable NSMutableDictionary *)extra {
    return plaintext;
}

- (nullable NSData *)decrypt:(NSData *)ciphertext
                      params:(nullable NSDictionary *)extra {
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
    if ([self.algorithm isEqualToString:MKMAlgorithm_Plain]) {
        return [PlainKey sharedInstance];
    }
    NSMutableDictionary *key = [[NSMutableDictionary alloc] init];
    [key setObject:self.algorithm forKey:@"algorithm"];
    return [self parseSymmetricKey:key];
}

- (nullable id<MKMSymmetricKey>)parseSymmetricKey:(NSDictionary *)key {
    NSString *algorithm = [key objectForKey:@"algorithm"];
    // AES key
    if ([algorithm isEqualToString:MKMAlgorithm_AES]) {
        return [[MKMAESKey alloc] initWithDictionary:key];
    }
    // Plain Key
    if ([algorithm isEqualToString:MKMAlgorithm_Plain]) {
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
    if ([self.algorithm isEqualToString:MKMAlgorithm_RSA]) {
        return [[MKMRSAPublicKey alloc] initWithDictionary:key];
    }
    // ECC Key
    if ([self.algorithm isEqualToString:MKMAlgorithm_ECC]) {
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
    if ([self.algorithm isEqualToString:MKMAlgorithm_RSA]) {
        return [[MKMRSAPrivateKey alloc] initWithDictionary:key];
    }
    // ECC Key
    if ([self.algorithm isEqualToString:MKMAlgorithm_ECC]) {
        return [[MKMECCPrivateKey alloc] initWithDictionary:key];
    }
    NSAssert(false, @"private key algorithm (%@) not support yet", self.algorithm);
    return nil;
}

@end

@implementation MKMPlugins (Crypto)

+ (void)registerKeyFactories {
    // Symmetric key
    MKMSymmetricKeySetFactory(MKMAlgorithm_AES,
                              [[SymmetricKeyFactory alloc] initWithAlgorithm:MKMAlgorithm_AES]);
    MKMSymmetricKeySetFactory(MKMAlgorithm_Plain,
                              [[SymmetricKeyFactory alloc] initWithAlgorithm:MKMAlgorithm_Plain]);

    // public key
    MKMPublicKeySetFactory(MKMAlgorithm_RSA,
                           [[PublicKeyFactory alloc] initWithAlgorithm:MKMAlgorithm_RSA]);
    MKMPublicKeySetFactory(MKMAlgorithm_ECC,
                           [[PublicKeyFactory alloc] initWithAlgorithm:MKMAlgorithm_ECC]);

    // private key
    MKMPrivateKeySetFactory(MKMAlgorithm_RSA,
                            [[PrivateKeyFactory alloc] initWithAlgorithm:MKMAlgorithm_RSA]);
    MKMPrivateKeySetFactory(MKMAlgorithm_ECC,
                            [[PrivateKeyFactory alloc] initWithAlgorithm:MKMAlgorithm_ECC]);
}

@end

#pragma mark -

@implementation MKMPlugins (DataCoder)

+ (void)registerDataCoders {
    DIMRegisterDataCoders();
    DIMRegisterDataParsers();
    
    // PNF
    MKMPortableNetworkFileSetFactory([[DIMBaseFileFactory alloc] init]);
    
    // TED
    DIMBase64DataFactory *b64Factory = [[DIMBase64DataFactory alloc] init];
    MKMTransportableDataSetFactory(MKMAlgorithm_Base64, b64Factory);
    //MKMTransportableDataSetFactory(MKMAlgorithm_TransportableDefault, b64Factory);
    MKMTransportableDataSetFactory(@"*", b64Factory);
}

@end

@implementation MKMPlugins (Digest)

+ (void)registerDigesters {
    DIMRegisterDataDigesters();
}

@end
