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

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@class DIMMessenger;
@class DIMFacebook;

@interface DIMContentProcessor : NSObject

@property (weak, nonatomic) DIMMessenger *messenger;
@property (readonly, weak, nonatomic) DIMFacebook *facebook;

- (instancetype)init;

/**
 *  Process message content
 *
 * @param content - message content
 * @param rMsg - message with envelope
 * @return content to respond
 */
- (nullable id<DKDContent>)processContent:(id<DKDContent>)content
                              withMessage:(id<DKDReliableMessage>)rMsg;

@end

@interface DIMContentProcessor (CPU)

+ (void)registerProcessor:(DIMContentProcessor *)processor
                  forType:(DKDContentType)type;

+ (nullable __kindof DIMContentProcessor *)getProcessorForType:(DKDContentType)type;

+ (nullable __kindof DIMContentProcessor *)getProcessorForContent:(id<DKDContent>)content;

@end

#define DIMContentProcessorRegister(type, cpu)                                 \
            [DIMContentProcessor registerProcessor:(cpu) forType:(type)]       \
                              /* EOF 'DIMContentProcessorRegister(type, cpu)' */

#define DIMContentProcessorRegisterClass(type, clazz)                          \
            DIMContentProcessorRegister((type), [[clazz alloc] init])          \
                       /* EOF 'DIMContentProcessorRegisterClass(type, clazz)' */

@interface DIMContentProcessor (Register)

+ (void)registerAllProcessors;

@end

NS_ASSUME_NONNULL_END
