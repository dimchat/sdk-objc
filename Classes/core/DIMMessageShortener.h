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
//  DIMMessageShortener.h
//  DIMSDK
//
//  Created by Albert Moky on 2025/10/12.
//  Copyright © 2025 Albert Moky. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
  Short Keys

  ======+==================================================+==================
        |   Message        Content        Symmetric Key    |    Description
  ------+--------------------------------------------------+------------------
  "A"   |                                 "algorithm"      |
  "C"   |   "content"      "command"                       |
  "D"   |   "data"                        "data"           |
  "F"   |   "sender"                                       |   (From)
  "G"   |   "group"        "group"                         |
  "I"   |                                 "iv"             |
  "K"   |   "key", "keys"                                  |
  "M"   |   "meta"                                         |
  "N"   |                  "sn"                            |   (Number)
  "P"   |   "visa"                                         |   (Profile)
  "R"   |   "receiver"                                     |
  "S"   |   ...                                            |
  "T"   |   "type"         "type"                          |
  "V"   |   "signature"                                    |   (Verification)
  "W"   |   "time"         "time"                          |   (When)
  ======+==================================================+==================

  Note:
      "S" - deprecated (ambiguous for "sender" and "signature")
 */
@protocol DIMShortener <NSObject>

///
///  Compress Content
///
- (NSMutableDictionary *)compressContent:(NSDictionary *)content;
- (NSMutableDictionary *)extractContent:(NSDictionary *)content;

///
///  Compress SymmetricKey
///
- (NSMutableDictionary *)compressSymmetricKey:(NSDictionary *)key;
- (NSMutableDictionary *)extractSymmetricKey:(NSDictionary *)key;

///
///  Compress ReliableMessage
///
- (NSMutableDictionary *)compressReliableMessage:(NSDictionary *)msg;
- (NSMutableDictionary *)extractReliableMessage:(NSDictionary *)msg;

@end

@interface DIMMessageShortener : NSObject <DIMShortener>

@property (strong, nonatomic) NSArray<NSString *> *cryptoShortKeys;

@property (strong, nonatomic) NSArray<NSString *> *contentShortKeys;

@property (strong, nonatomic) NSArray<NSString *> *messageShortKeys;

@end

// protected
@interface DIMMessageShortener (Modification)

- (void)dictionary:(NSMutableDictionary *)dict
           moveKey:(NSString *)from
             toKey:(NSString *)to;

- (void)dictionary:(NSMutableDictionary *)dict
       shortenKeys:(NSArray<NSString *> *)keys;

- (void)dictionary:(NSMutableDictionary *)dict
       restoreKeys:(NSArray<NSString *> *)keys;

@end

NS_ASSUME_NONNULL_END
