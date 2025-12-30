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
//  DIMVisaAgent.h
//  DIMSDK
//
//  Created by Albert Moky on 2025/12/21.
//  Copyright © 2025 Albert Moky. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DIMEncryptedData;

@protocol DIMVisaAgent <NSObject>

/**
 *  Encrypt plaintext to ciphertexts with all visa keys
 *
 * @param plaintext - key data
 * @param meta      - meta for public key
 * @param documents - visa documents for public keys
 * @return encrypted data with terminals
 */
- (__kindof id<DIMEncryptedData>)encryptData:(NSData *)plaintext
                                forDocuments:(NSArray<id<MKMDocument>> *)documents
                                        meta:(id<MKMMeta>)meta;

/**
 *  Get all verify keys from documents and meta
 *
 * @param meta      - meta for public key
 * @param documents - visa documents for public keys
 * @return verify keys
 */
- (NSArray<id<MKVerifyKey>> *)keysFromDocuments:(NSArray<id<MKMDocument>> *)documents
                                           meta:(id<MKMMeta>)meta;

/**
 *  Get all terminals from documents
 *
 * @param documents - visa documents
 * @return terminals
 */
- (NSSet<NSString *> *)terminalsFromDocuments:(NSArray<id<MKMDocument>> *)documents;

@end

@interface DIMVisaAgent : NSObject <DIMVisaAgent>

@end

// protected
@interface DIMVisaAgent (Extended)

- (nullable __kindof id<MKVerifyKey>)verifyKeyFromDocument:(id<MKMDocument>)doc;

- (nullable __kindof id<MKEncryptKey>)encryptKeyFromDocument:(id<MKMDocument>)doc;

- (nullable NSString *)terminalFromDocument:(id<MKMDocument>)doc;

@end

#pragma mark -

@interface DIMSharedVisaAgent : NSObject

+ (instancetype)sharedInstance;

@property (strong, nonatomic, nullable) __kindof id<DIMVisaAgent> agent;

@end

NS_ASSUME_NONNULL_END
