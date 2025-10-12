// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2022 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2022 Albert Moky
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
//  DIMCustomizedContentProcessor.h
//  DIMSDK
//
//  Created by Albert Moky on 2022/8/9.
//  Copyright © 2022 Albert Moky. All rights reserved.
//

#import <DIMSDK/DIMBaseProcessor.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Handler for Customized Content
 *  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */
@protocol DIMCustomizedContentHandler <NSObject>

/**
 *  Do your job
 *
 * @param act  - action
 * @param uid  - user ID
 * @param body - customized content
 * @param rMsg - network message
 * @return responses
 */
- (NSArray<id<DKDContent>> *)handleAction:(NSString *)act
                                   sender:(id<MKMID>)uid
                                  content:(id<DKDCustomizedContent>)body
                                  message:(id<DKDReliableMessage>)rMsg;

@end

/**
 *  Default Handler
 *  ~~~~~~~~~~~~~~~
 *  Base Customized Handler
 */
@interface DIMCustomizedContentHandler : DIMTwinsHelper <DIMCustomizedContentHandler>

// protected
- (NSArray<id<DKDReceiptCommand>> *)respondReceipt:(NSString *)text
                                          envelope:(id<DKDEnvelope>)head
                                           content:(nullable id<DKDContent>)body
                                             extra:(nullable NSDictionary *)info;

@end

#pragma mark -

@interface DIMCustomizedContentProcessor : DIMContentProcessor

// protected
@property (readonly, strong, nonatomic) __kindof id<DIMCustomizedContentHandler> defaultHandler;

// protected
- (id<DIMCustomizedContentHandler>)createDefaultHandler:(DIMFacebook *)facebook
                                              messenger:(DIMMessenger *)transceiver;

/// override for your application
// protected
- (id<DIMCustomizedContentHandler>)filterApplication:(NSString *)app
                                          withModule:(NSString *)mod
                                             content:(id<DKDCustomizedContent>)body
                                            messasge:(id<DKDReliableMessage>)rMsg;

@end

NS_ASSUME_NONNULL_END
