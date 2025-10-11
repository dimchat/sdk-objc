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
//  DIMMessageCompressor.h
//  DIMSDK
//
//  Created by Albert Moky on 2025/10/12.
//  Copyright © 2025 Albert Moky. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DIMCompressor <NSObject>

- (NSData *)compressContent:(NSMutableDictionary *)content withKey:(NSDictionary *)pwd;
- (nullable NSDictionary *)extractContent:(NSData *)data withKey:(NSDictionary *)pwd;

- (NSData *)compressSymmetricKey:(NSMutableDictionary *)key;
- (nullable NSDictionary *)extractSymmetricKey:(NSData *)data;

- (NSData *)compressReliableMessage:(NSMutableDictionary *)msg;
- (nullable NSDictionary *)extractReliableMessage:(NSData *)data;

@end

@protocol DIMShortener;

@interface DIMMessageCompressor : NSObject <DIMCompressor>

@property (readonly, strong, nonatomic) __kindof id<DIMShortener> shortener;

- (instancetype)initWithShortener:(id<DIMShortener>)shortener
NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
