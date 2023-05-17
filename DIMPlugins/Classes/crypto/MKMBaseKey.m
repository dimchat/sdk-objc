// license: https://mit-license.org
//
//  Ming-Ke-Ming : Decentralized User Identity Authentication
//
//                               Written in 2023 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2023 Albert Moky
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
//  MKMBaseKey.m
//  DIMPlugins
//
//  Created by Albert Moky on 2023/2/2.
//  Copyright © 2023 Albert Moky. All rights reserved.
//

#import "MKMBaseKey.h"

@implementation MKMCryptographyKey

- (NSString *)algorithm {
    MKMKeyFactoryManager *man = [MKMKeyFactoryManager sharedManager];
    return [man.generalFactory algorithm:self.dictionary];
}

- (NSData *)data {
    NSAssert(false, @"implement me!");
    return nil;
}

@end

@implementation MKMSymmetricKey

- (NSString *)algorithm {
    MKMKeyFactoryManager *man = [MKMKeyFactoryManager sharedManager];
    return [man.generalFactory algorithm:self.dictionary];
}

- (NSData *)data {
    NSAssert(false, @"implement me!");
    return nil;
}

- (BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        return YES;
    }
    if ([object conformsToProtocol:@protocol(MKMSymmetricKey)]) {
        return [self isMatch:object];
    }
    return NO;
}

- (BOOL)isMatch:(id<MKMEncryptKey>)pKey {
    MKMKeyFactoryManager *man = [MKMKeyFactoryManager sharedManager];
    return [man.generalFactory isEncryptKey:pKey matchDecryptKey:self];
}

- (NSData *)encrypt:(NSData *)plaintext {
    NSAssert(false, @"implement me!");
    return nil;
}

- (nullable NSData *)decrypt:(NSData *)ciphertext {
    NSAssert(false, @"implement me!");
    return nil;
}

@end

@implementation MKMAsymmetricKey

- (NSString *)algorithm {
    MKMKeyFactoryManager *man = [MKMKeyFactoryManager sharedManager];
    return [man.generalFactory algorithm:self.dictionary];
}

- (NSData *)data {
    NSAssert(false, @"implement me!");
    return nil;
}

@end

@implementation MKMPrivateKey

- (NSString *)algorithm {
    MKMKeyFactoryManager *man = [MKMKeyFactoryManager sharedManager];
    return [man.generalFactory algorithm:self.dictionary];
}

- (NSData *)data {
    NSAssert(false, @"implement me!");
    return nil;
}

- (BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        return YES;
    }
    if ([object conformsToProtocol:@protocol(MKMSignKey)]) {
        return [self.publicKey isMatch:object];
    }
    return NO;
}

- (id<MKMPublicKey>)publicKey {
    NSAssert(false, @"implement me!");
    return nil;
}

- (NSData *)sign:(NSData *)data {
    NSAssert(false, @"implement me!");
    return nil;
}

@end

@implementation MKMPublicKey

- (NSString *)algorithm {
    MKMKeyFactoryManager *man = [MKMKeyFactoryManager sharedManager];
    return [man.generalFactory algorithm:self.dictionary];
}

- (NSData *)data {
    NSAssert(false, @"implement me!");
    return nil;
}

- (BOOL)verify:(NSData *)data withSignature:(NSData *)signature {
    NSAssert(false, @"implement me!");
    return NO;
}

- (BOOL)isMatch:(id<MKMSignKey>)sKey {
    MKMKeyFactoryManager *man = [MKMKeyFactoryManager sharedManager];
    return [man.generalFactory isSignKey:sKey matchVerifyKey:self];
}

@end
