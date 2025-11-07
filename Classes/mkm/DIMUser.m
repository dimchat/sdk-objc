// license: https://mit-license.org
//
//  DIMP : Decentralized Instant Messaging Protocol
//
//                               Written in 2018 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2018 Albert Moky
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
//  DIMUser.m
//  DIMCore
//
//  Created by Albert Moky on 2018/9/26.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DIMAccountUtils.h"

#import "DIMUser.h"

@implementation DIMUser

// Override
- (nullable id<MKMVisa>)visa {
    NSArray<id<MKMDocument>> *docs = [self documents];
    return DIMDocumentGetVisa(docs);
}

// Override
- (BOOL)verifyVisa:(id<MKMVisa>)visa {
    // NOTICE: only verify visa with meta.key
    //         (if meta not exists, user won't be created)
    id<MKMID> ID = [self identifier];
    // check document ID
    id<MKMID> did = [visa identifier];
    if ([ID isEqual:did]) {
        // OK
    } else {
        // visa ID not match
        NSAssert(false, @"visa ID not match:%@, %@", ID, did);
        return NO;
    }
    // if meta not exists, user won't be created
    id<MKMMeta> meta = [self meta];
    id<MKVerifyKey> PK = [meta publicKey];
    NSAssert(PK, @"failed to get verify key for visa: %@", ID);
    return [visa verify:PK];
}

// Override
- (BOOL)verify:(NSData *)data withSignature:(NSData *)signature {
    id<MKMUserDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"user data source not set yet");
    id<MKMID> ID = [self identifier];
    NSArray<id<MKVerifyKey>> *keys = [facebook publicKeysForVerification:ID];
    NSAssert([keys count] > 0, @"failed to get verify keys: %@", ID);
    for (id<MKVerifyKey> PK in keys) {
        if ([PK verify:data withSignature:signature]) {
            // matched!
            return YES;
        }
    }
    // signature not match
    // TODO: check whether visa is expired, query new document for this contact
    return NO;
}

// Override
- (NSData *)encrypt:(NSData *)plaintext {
    id<MKMUserDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"user data source not set yet");
    id<MKMID> ID = [self identifier];
    // NOTICE: meta.key will never changed, so use visa.key to encrypt message
    //         is a better way
    id<MKEncryptKey> PK = [facebook publicKeyForEncryption:ID];
    NSAssert(PK, @"failed to get encrypt key for user: %@", ID);
    return [PK encrypt:plaintext extra:nil];
}

#pragma mark Local User

- (NSString *)debugDescription {
    NSString *desc = [super debugDescription];
    NSDictionary *dict = MKJsonDecode(desc);
    NSMutableDictionary *info;
    if ([dict isKindOfClass:[NSMutableDictionary class]]) {
        info = (NSMutableDictionary *)dict;
    } else {
        info = [dict mutableCopy];
    }
    [info setObject:@(self.contacts.count) forKey:@"contacts"];
    return MKJsonEncode(info);
}

// Override
- (NSArray<id<MKMID>> *)contacts {
    id<MKMUserDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"user data source not set yet");
    id<MKMID> ID = [self identifier];
    return [facebook contacts:ID];
}

// Override
- (nullable id<MKMVisa>)signVisa:(id<MKMVisa>)visa {
    id<MKMUserDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"user data source not set yet");
    // check document ID
    id<MKMID> ID = [self identifier];
    id<MKMID> did = [visa identifier];
    if ([ID isEqual:did]) {
        // OK
    } else {
        NSAssert(false, @"visa ID not match:%@, %@", ID, did);
        //return nil;
    }
    // NOTICE: only sign visa with the private key paired with your meta.key
    id<MKSignKey> SK = [facebook privateKeyForVisaSignature:did];
    NSAssert(SK, @"failed to get visa sign key for user: %@", did);
    NSData *sig = [visa sign:SK];
    if ([sig length] == 0) {
        NSAssert(false, @"failed to sign visa: %@, %@", did, visa);
        return nil;
    }
    return visa;
}

// Override
- (NSData *)sign:(NSData *)data {
    id<MKMUserDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"user data source not set yet");
    id<MKMID> ID = [self identifier];
    id<MKSignKey> SK = [facebook privateKeyForSignature:ID];
    NSAssert(SK, @"failed to get sign key for user: %@", ID);
    return [SK sign:data];
}

// Override
- (nullable NSData *)decrypt:(NSData *)ciphertext {
    id<MKMUserDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"user data source not set yet");
    id<MKMID> ID = [self identifier];
    // NOTICE: if you provide a public key in visa for encryption
    //         here you should return the private key paired with visa.key
    NSArray<id<MKDecryptKey>> *keys = [facebook privateKeysForDecryption:ID];
    NSAssert([keys count] > 0, @"failed to get decrypt keys for user: %@", ID);
    NSData *plaintext = nil;
    for (id<MKDecryptKey> SK in keys) {
        // try decrypting it with each private key
        plaintext = [SK decrypt:ciphertext params:nil];
        if ([plaintext length] > 0) {
            // OK!
            return plaintext;
        }
    }
    // decryption failed
    // TODO: check whether my visa key is changed, push new visa to this contact
    return nil;
}

@end
