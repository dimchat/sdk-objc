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

#import "DIMEncryptedBundle.h"
#import "DIMVisaAgent.h"

#import "DIMUser.h"

@implementation DIMUser

/* designated initializer */
- (instancetype)initWithID:(id<MKMID>)did {
    if (self = [super initWithID:did]) {
    }
    return self;
}

// Override
- (NSSet<NSString *> *)terminals {
    NSArray<id<MKMDocument>> *docs = [self documents];
    if ([docs count] == 0) {
        NSAssert(false, @"failed to get documents: %@", self.identifier);
        return nil;
    }
    id<DIMVisaAgent> visaAgent = [[DIMSharedVisaAgent sharedInstance] agent];
    return [visaAgent terminalsFromDocuments:docs];
}

// Override
- (id<DIMEncryptedBundle>)encryptBundle:(NSData *)plaintext {
    id<MKMMeta> meta = [self meta];
    NSArray<id<MKMDocument>> *docs = [self documents];
    if (meta && docs) {
        // OK
    } else {
        NSAssert(false, @"user not ready: %@", self.identifier);
        return nil;
    }
    NSAssert([docs count] > 0, @"documents empty: %@", self.identifier);
    id<DIMVisaAgent> visaAgent = [[DIMSharedVisaAgent sharedInstance] agent];
    return [visaAgent encryptBundle:plaintext forDocuments:docs meta:meta];
}

// Override
- (BOOL)verify:(NSData *)data withSignature:(NSData *)signature {
    id<MKMMeta> meta = [self meta];
    NSArray<id<MKMDocument>> *docs = [self documents];
    if (meta && docs) {
        // OK
    } else {
        NSAssert(false, @"user not ready: %@", self.identifier);
        return NO;
    }
    NSAssert([docs count] > 0, @"documents empty: %@", self.identifier);
    id<DIMVisaAgent> visaAgent = [[DIMSharedVisaAgent sharedInstance] agent];
    NSArray<id<MKVerifyKey>> *keys = [visaAgent keysFromDocuments:docs meta:meta];
    NSAssert([keys count] > 0, @"failed to get verify keys: %@", self.identifier);
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
- (BOOL)verifyVisa:(id<MKMVisa>)visa {
    // NOTICE: only verify visa with meta.key
    //         (if meta not exists, user won't be created)
    id<MKMID> uid = [self identifier];
    // check document ID
    id<MKMID> did = MKMIDParse([visa objectForKey:@"did"]);
    if (did == nil || [did.address isEqual:uid.address]) {
        // OK
    } else {
        // visa ID not match
        NSAssert(false, @"visa ID not match:%@, %@", uid, did);
        return NO;
    }
    // if meta not exists, user won't be created
    id<MKMMeta> meta = [self meta];
    id<MKVerifyKey> PK = [meta publicKey];
    NSAssert(PK, @"failed to get verify key for visa: %@", uid);
    return [visa verify:PK];
}

#pragma mark Local User

//- (NSString *)debugDescription {
//    NSString *desc = [super debugDescription];
//    NSDictionary *dict = MKJsonMapDecode(desc);
//    NSMutableDictionary *info;
//    if ([dict isKindOfClass:[NSMutableDictionary class]]) {
//        info = (NSMutableDictionary *)dict;
//    } else {
//        info = [dict mutableCopy];
//    }
//    [info setObject:@(self.contacts.count) forKey:@"contacts"];
//    return MKJsonMapEncode(info);
//}

// Override
- (NSArray<id<MKMID>> *)contacts {
    id<MKMUserDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"user data source not set yet");
    id<MKMID> uid = [self identifier];
    return [facebook contactsOfUser:uid];
}

// Override
- (nullable id<MKMVisa>)signVisa:(id<MKMVisa>)visa {
    // check document ID
    id<MKMID> did = MKMIDParse([visa objectForKey:@"did"]);
    if (did) {
        NSAssert([self.identifier.address isEqual:did.address], @"visa ID not matched: %@, %@", did, self.identifier);
    }
    // NOTICE: only sign visa with the private key paired with your meta.key
    id<MKSignKey> SK = [self privateKeyForVisaSignature];
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
    id<MKSignKey> SK = [self privateKeyForSignature];
    NSAssert(SK, @"failed to get sign key for user: %@", self.identifier);
    return [SK sign:data];
}

// Override
- (nullable NSData *)decryptBundle:(id<DIMEncryptedBundle>)bundle {
    // NOTICE: if you provide a public key in visa for encryption
    //         here you should return the private key paired with visa.key
    NSDictionary<NSString *, NSData *> *map = [bundle dictionary];
    NSAssert([map count] > 0, @"key data empty: %@", bundle);
    __block NSData *plaintext = nil;
    [map enumerateKeysAndObjectsUsingBlock:^(NSString *terminal, NSData *ciphertext, BOOL *stop) {
        // get private keys for terminal
        NSArray<id<MKDecryptKey>> *keys = [self privateKeysForDecryption:terminal];
        if ([keys count] == 0) {
            NSAssert(false, @"failed to get decrypt keys for user: %@, terminal: %@", self.identifier, terminal);
            return;
        }
        // try decrypting it with each private key
        NSData *plain;
        for (id<MKDecryptKey> SK in keys) {
            plain = [SK decrypt:ciphertext params:nil];
            if ([plain length] > 0) {
                // OK!
                plaintext = plain;
                *stop = true;
                break;
            }
        }
    }];
    // decryption failed
    // TODO: check whether my visa key is changed, push new visa to this contact
    return plaintext;
}

@end

@implementation DIMUser (PrivateKey)

- (NSArray<id<MKDecryptKey>> *)privateKeysForDecryption:(NSString *)terminal {
    id<MKMUserDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"user data source not set yet");
    if ([terminal length] == 0 || [terminal isEqualToString:@"*"]) {
        return [facebook privateKeysForDecryption:self.identifier];
    }
    id<MKMID> did = [self identifier];
    id<MKMID> uid = MKMIDCreate(did.name, did.address, terminal);
    return [facebook privateKeysForDecryption:uid];
}

- (nullable id<MKSignKey>)privateKeyForSignature {
    id<MKMUserDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"user data source not set yet");
    return [facebook privateKeyForSignature:self.identifier];
}

- (nullable id<MKSignKey>)privateKeyForVisaSignature {
    id<MKMUserDataSource> facebook = [self dataSource];
    NSAssert(facebook, @"user data source not set yet");
    return [facebook privateKeyForVisaSignature:self.identifier];
}

@end
