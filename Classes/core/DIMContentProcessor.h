// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2019 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2019 Albert Moky
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
//  DIMContentProcessor.h
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 Albert Moky. All rights reserved.
//

#import <DIMSDK/DIMTwinsHelper.h>

NS_ASSUME_NONNULL_BEGIN

/*
 *  CPU: Content Processing Unit
 *  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */
@protocol DIMContentProcessor <NSObject>

/**
 *  Process message content
 *
 * @param content - message content
 * @param rMsg - message with envelope
 * @return content to respond
 */
- (NSArray<id<DKDContent>> *)processContent:(__kindof id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg;

@end

/*
 *  CPU Creator
 *  ~~~~~~~~~~~
 */
@protocol DIMContentProcessorCreator <NSObject>

/**
 *  Create content processor with type
 *
 *  @param type - content type
 *  @return ContentProcessor
 */
- (id<DIMContentProcessor>)createContentProcessor:(DKDContentType)type;

/**
 *  Create command processor with name
 *
 *  @param name - command name
 *  @param msgType - content type
 *  @return CommandProcessor
 */
- (id<DIMContentProcessor>)createCommandProcessor:(NSString *)name
                                             type:(DKDContentType)msgType;

@end

/*
 *  CPU Factory
 *  ~~~~~~~~~~~
 */
@protocol DIMContentProcessorFactory <NSObject>

/**
 *  Get content/command processor
 *
 *  @param content - content/command
 *  @return ContentProcessor
 */
- (id<DIMContentProcessor>)getProcessor:(__kindof id<DKDContent>)content;

- (id<DIMContentProcessor>)getContentProcessor:(DKDContentType)msgType;

- (id<DIMContentProcessor>)getCommandProcessor:(NSString *)name
                                          type:(DKDContentType)msgType;

@end

/**
 *  General ContentProcessor Factory
 *  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */
@interface DIMContentProcessorFactory : DIMTwinsHelper <DIMContentProcessorFactory>

- (instancetype)initWithFacebook:(DIMBarrack *)barrack
                       messenger:(DIMTransceiver *)transceiver
                         creator:(id<DIMContentProcessorCreator>)cpc
NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
