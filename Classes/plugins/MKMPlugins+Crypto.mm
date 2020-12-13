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

#import "base58.h"
#import "ripemd160.h"

#import "NSObject+Singleton.h"

#import "MKMAESKey.h"
#import "MKMRSAPublicKey.h"
#import "MKMRSAPrivateKey.h"

#import "MKMPlugins.h"

#define SCAlgorithmPlain @"PLAIN"

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

SingletonImplementations(PlainKey, sharedInstance)

- (instancetype)init {
    NSDictionary *dict = @{@"algorithm": SCAlgorithmPlain};
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

@interface SymmetricKeyFactory : NSObject <MKMSymmetricKeyFactory>

@end

@implementation SymmetricKeyFactory

- (nullable __kindof id<MKMSymmetricKey>)generateSymmetricKey:(NSString *)algorithm {
    if ([algorithm isEqualToString:SCAlgorithmPlain]) {
        return [PlainKey sharedInstance];
    }
    NSMutableDictionary *key = [[NSMutableDictionary alloc] init];
    [key setObject:algorithm forKey:@"algorithm"];
    return [self parseSymmetricKey:key];
}

- (nullable __kindof id<MKMSymmetricKey>)parseSymmetricKey:(NSDictionary *)key {
    NSString *algorithm = [key objectForKey:@"algorithm"];
    // AES key
    if ([algorithm isEqualToString:SCAlgorithmAES]) {
        return [[MKMAESKey alloc] initWithDictionary:key];
    }
    // Plain Key
    if ([algorithm isEqualToString:SCAlgorithmPlain]) {
        return [PlainKey sharedInstance];
    }
    NSAssert(false, @"symmetric key algorithm (%@) not support yet", algorithm);
    return nil;
}

@end

@interface PublicKeyFactory : NSObject <MKMPublicKeyFactory>

@end

@implementation PublicKeyFactory

- (nullable __kindof id<MKMPublicKey>)parsePublicKey:(NSDictionary *)key {
    NSString *algorithm = [key objectForKey:@"algorithm"];
    // RSA key
    if ([algorithm isEqualToString:ACAlgorithmRSA]) {
        return [[MKMRSAPublicKey alloc] initWithDictionary:key];
    }
    // ECC Key
    if ([algorithm isEqualToString:ACAlgorithmECC]) {
        //
    }
    NSAssert(false, @"public key algorithm (%@) not support yet", algorithm);
    return nil;
}

@end

@interface PrivateKeyFactory : NSObject <MKMPrivateKeyFactory>

@end

@implementation PrivateKeyFactory

- (nullable __kindof id<MKMPrivateKey>)generatePrivateKey:(NSString *)algorithm {
    NSMutableDictionary *key = [[NSMutableDictionary alloc] init];
    [key setObject:algorithm forKey:@"algorithm"];
    return [self parsePrivateKey:key];
}

- (nullable __kindof id<MKMPrivateKey>)parsePrivateKey:(NSDictionary *)key {
    NSString *algorithm = [key objectForKey:@"algorithm"];
    // RSA key
    if ([algorithm isEqualToString:ACAlgorithmRSA]) {
        return [[MKMRSAPrivateKey alloc] initWithDictionary:key];
    }
    // ECC Key
    if ([algorithm isEqualToString:ACAlgorithmECC]) {
        //
    }
    NSAssert(false, @"private key algorithm (%@) not support yet", algorithm);
    return nil;
}

@end

@implementation MKMPlugins (Crypto)

+ (void)registerKeyFactories {
    SymmetricKeyFactory *symmetricFactory = [[SymmetricKeyFactory alloc] init];
    [MKMSymmetricKey setFactory:symmetricFactory];
    
    PublicKeyFactory *publicFactory = [[PublicKeyFactory alloc] init];
    [MKMPublicKey setFactory:publicFactory];
    
    PrivateKeyFactory *privateFactory = [[PrivateKeyFactory alloc] init];
    [MKMPrivateKey setFactory:privateFactory];
}

@end

#pragma mark -

@interface Hex : NSObject <MKMDataCoder>

@end

static inline char hex_char(char ch) {
    if (ch >= '0' && ch <= '9') {
        return ch - '0';
    }
    if (ch >= 'a' && ch <= 'f') {
        return ch - 'a' + 10;
    }
    if (ch >= 'A' && ch <= 'F') {
        return ch - 'A' + 10;
    }
    return 0;
}

@implementation Hex

- (nullable NSString *)encode:(NSData *)data {
    NSMutableString *output = nil;
    
    const unsigned char *bytes = (const unsigned char *)[data bytes];
    NSUInteger len = [data length];
    output = [[NSMutableString alloc] initWithCapacity:(len*2)];
    for (int i = 0; i < len; ++i) {
        [output appendFormat:@"%02x", bytes[i]];
    }
    
    return output;
}

- (nullable NSData *)decode:(NSString *)string {
    NSMutableData *output = nil;
    
    NSString *str = string;
    // 1. remove ' ', ':', '-', '\n'
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@":" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"-" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    // 2. skip '0x' prefix
    char ch0, ch1;
    NSUInteger pos = 0;
    NSUInteger len = [string length];
    if (len > 2) {
        ch0 = [str characterAtIndex:0];
        ch1 = [str characterAtIndex:1];
        if (ch0 == '0' && (ch1 == 'x' || ch1 == 'X')) {
            pos = 2;
        }
    }
    
    // 3. decode bytes
    output = [[NSMutableData alloc] initWithCapacity:(len/2)];
    unsigned char byte;
    for (; (pos + 1) < len; pos += 2) {
        ch0 = [str characterAtIndex:pos];
        ch1 = [str characterAtIndex:(pos + 1)];
        byte = hex_char(ch0) * 16 + hex_char(ch1);
        [output appendBytes:&byte length:1];
    }
    
    return output;
}

@end

@interface Base58 : NSObject <MKMDataCoder>

@end

@implementation Base58

- (nullable NSString *)encode:(NSData *)data {
    NSString *output = nil;
    const unsigned char *pbegin = (const unsigned char *)[data bytes];
    const unsigned char *pend = pbegin + [data length];
    std::string str = EncodeBase58(pbegin, pend);
    output = [[NSString alloc] initWithCString:str.c_str()
                                      encoding:NSUTF8StringEncoding];
    return output;
}

- (nullable NSData *)decode:(NSString *)string {
    NSData *output = nil;
    const char *cstr = [string cStringUsingEncoding:NSUTF8StringEncoding];
    std::vector<unsigned char> vch;
    DecodeBase58(cstr, vch);
    std::string str(vch.begin(), vch.end());
    output = [[NSData alloc] initWithBytes:str.c_str() length:str.size()];
    return output;
}

@end

@implementation MKMPlugins (Coder)

+ (void)registerCoders {
    Hex *hex = [[Hex alloc] init];
    [MKMHex setCoder:hex];
    
    Base58 *base58 = [[Base58 alloc] init];
    [MKMBase58 setCoder:base58];
}

@end

#pragma mark -

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

@implementation MKMPlugins (Digest)

+ (void)registerDigesters {
    RIPEMD160 *ripemd = [[RIPEMD160 alloc] init];
    [MKMRIPEMD160 setDigester:ripemd];
    
    // TODO: KECCAK256
}

@end
