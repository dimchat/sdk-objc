// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2020 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2020 Albert Moky
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
//  DIMMessagePacker.h
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/22.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import <DIMSDK/DIMTwinsHelper.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMMessagePacker : DIMTwinsHelper <DIMPacker>

@end

@class DIMInstantMessagePacker;
@class DIMSecureMessagePacker;
@class DIMReliableMessagePacker;

// protected
@interface DIMMessagePacker (Attachments)

@property (readonly, strong, nonatomic) DIMInstantMessagePacker *instantPacker;
@property (readonly, strong, nonatomic) DIMSecureMessagePacker *securePacker;
@property (readonly, strong, nonatomic) DIMReliableMessagePacker *reliablePacker;

/**
 *  Check meta & visa
 *
 * @param rMsg - received message
 * @return false on error
 */
- (BOOL)checkAttachments:(id<DKDReliableMessage>)rMsg;

@end

NS_ASSUME_NONNULL_END
