// license: https://mit-license.org
//
//  DIMP : Decentralized Instant Messaging Protocol
//
//                               Written in 2025 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2025 Albert Moky
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
//  DIMVisaAgent.m
//  DIMSDK
//
//  Created by Albert Moky on 2025/12/21.
//  Copyright © 2025 Albert Moky. All rights reserved.
//

#import "DIMEncryptedData.h"

#import "DIMVisaAgent.h"

@implementation DIMVisaAgent

// Override
- (id<DIMEncryptedData>)encryptData:(NSData *)plaintext
                       forDocuments:(NSArray<id<MKMDocument>> *)documents
                               meta:(id<MKMMeta>)meta {
    // NOTICE: meta.key will never changed, so use visa.key to encrypt message
    //         is a better way
    id<DIMEncryptedData> results = [[DIMEncryptedData alloc] init];
    NSString *terminal;
    id<MKEncryptKey> pubKey;
    NSData *ciphertext;
    //
    //  1. encrypt with visa keys
    //
    for (id<MKMDocument> doc in documents) {
        // encrypt by public key
        pubKey = [self encryptKeyFromDocument:doc];
        if (!pubKey) {
            continue;
        }
        // get visa.terminal
        terminal = [self terminalFromDocument:doc];
        if ([terminal length] == 0) {
            terminal = @"*";
        }
        if ([results dataForTerminal:terminal] != nil) {
            NSAssert(false, @"duplicated visa key: %@", doc);
            continue;
        }
        ciphertext = [pubKey encrypt:plaintext extra:nil];
        [results setData:ciphertext forTerminal:terminal];
    }
    if ([results isEmpty]) {
        //
        //  2. encrypt with meta key
        //
        id<MKVerifyKey> metaKey = [meta publicKey];
        if ([metaKey conformsToProtocol:@protocol(MKEncryptKey)]) {
            pubKey = (id<MKEncryptKey>)metaKey;
            //terminal = @"*";
            ciphertext = [pubKey encrypt:plaintext extra:nil];
            [results setData:ciphertext forTerminal:@"*"];
        }
    }
    // OK
    return results;
}

// Override
- (NSArray<id<MKVerifyKey>> *)keysFromDocuments:(NSArray<id<MKMDocument>> *)documents
                                           meta:(id<MKMMeta>)meta {
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    id<MKVerifyKey> pubKey;
    // the sender may use communication key to sign message.data,
    // try to verify it with visa.key first;
    for (id<MKMDocument> doc in documents) {
        pubKey = [self verifyKeyFromDocument:doc];
        if (pubKey) {
            [keys addObject:pubKey];
        } else {
            NSAssert(false, @"failed to get visa key: %@", doc);
        }
    }
    // the sender may use identity key to sign message.data,
    // try to verify it with meta.key too.
    pubKey = [meta publicKey];
    if (pubKey) {
        [keys addObject:pubKey];
    } else {
        NSAssert(false, @"failed to get meta key: %@", meta);
    }
    // OK
    return keys;
}

// Override
- (NSSet<NSString *> *)terminalsFromDocuments:(NSArray<id<MKMDocument>> *)documents {
    NSMutableSet<NSString *> *devices = [[NSMutableSet alloc] init];
    NSString *terminal;
    for (id<MKMDocument> doc in documents) {
        terminal = [self terminalFromDocument:doc];
        if ([terminal length] == 0) {
            terminal = @"*";
        }
        [devices addObject:terminal];
    }
    return devices;
}

@end

@implementation DIMVisaAgent (Extended)

- (nullable id<MKVerifyKey>)verifyKeyFromDocument:(id<MKMDocument>)doc {
    if ([doc conformsToProtocol:@protocol(MKMVisa)]) {
        id<MKEncryptKey> visaKey = [(id<MKMVisa>)doc publicKey];
        if ([visaKey conformsToProtocol:@protocol(MKVerifyKey)]) {
            return (id<MKVerifyKey>)visaKey;
        }
        NSAssert(false, @"failed to get visa key: %@", doc);
        return nil;
    }
    // public key in user profile?
    id<MKPublicKey> pubKey = MKPublicKeyParse([doc propertyForKey:@"key"]);
    return pubKey;
}

- (nullable id<MKEncryptKey>)encryptKeyFromDocument:(id<MKMDocument>)doc {
    if ([doc conformsToProtocol:@protocol(MKMVisa)]) {
        id<MKEncryptKey> visaKey = [(id<MKMVisa>)doc publicKey];
        if (visaKey) {
            return visaKey;
        }
        NSAssert(false, @"failed to get visa key: %@", doc);
        return nil;
    }
    id<MKPublicKey> pubKey = MKPublicKeyParse([doc propertyForKey:@"key"]);
    if ([pubKey conformsToProtocol:@protocol(MKEncryptKey)]) {
        return (id<MKEncryptKey>)pubKey;
    }
    NSAssert(pubKey == nil, @"visa key error: %@", pubKey);
    return nil;
}

- (nullable NSString *)terminalFromDocument:(id<MKMDocument>)doc {
    NSString *terminal;
    // get from visa
    if ([doc conformsToProtocol:@protocol(MKMVisa)]) {
        terminal = [(id<MKMVisa>)doc terminal];
        if (terminal) {
            return terminal;
        }
    }
    // get from document
    terminal = [doc stringForKey:@"terminal" defaultValue:nil];
    if (!terminal) {
        id<MKMID> did = MKMIDParse([doc objectForKey:@"did"]);
        NSAssert(did, @"document ID not found: %@", doc);
        terminal = [did terminal];
    }
    return terminal;
}

@end

#pragma mark -

@implementation DIMSharedVisaAgent

static DIMSharedVisaAgent *s_visa_agent = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_visa_agent = [[self alloc] init];
    });
    return s_visa_agent;
}

- (instancetype)init {
    if (self = [super init]) {
        self.agent = [[DIMVisaAgent alloc] init];
    }
    return self;
}

@end
