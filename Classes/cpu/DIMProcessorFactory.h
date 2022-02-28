// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2021 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2021 Albert Moky
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
//  DIMProcessorFactory.h
//  DIMSDK
//
//  Created by Albert Moky on 2021/11/22.
//  Copyright © 2021 Albert Moky. All rights reserved.
//

#import <DIMSDK/DIMContentProcessor.h>
#import <DIMSDK/DIMCommandProcessor.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMProcessorFactory : NSObject

@property (readonly, weak, nonatomic) __kindof DIMFacebook *facebook;
@property (readonly, weak, nonatomic) __kindof DIMMessenger *messenger;

- (instancetype)initWithFacebook:(DIMFacebook *)barrack
                       messenger:(DIMMessenger *)transceiver
NS_DESIGNATED_INITIALIZER;

/**
 *  Get content/command processor
 */
- (nullable __kindof DIMContentProcessor *)processorForContent:(id<DKDContent>)content;

/**
 *  Get content processor
 */
- (nullable __kindof DIMContentProcessor *)processorForType:(DKDContentType)type;

/**
 *  Get command processor
 */
- (nullable __kindof DIMCommandProcessor *)processorForName:(NSString *)command
                                                       type:(DKDContentType)type;

#pragma mark -

/**
 *  Create content processor with type
 */
- (DIMContentProcessor *)createProcessorWithType:(DKDContentType)type;

/**
 *  Create command processor with type & name
 */
- (DIMCommandProcessor *)createProcessorWithName:(NSString *)command
                                            type:(DKDContentType)type;

@end

NS_ASSUME_NONNULL_END
