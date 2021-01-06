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
//  DIMMessageTransmitter.h
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/19.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "DIMMessenger.h"
#import "DIMMessagePacker.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DIMTransmitter <NSObject>

/**
 *  Send message content to receiver
 *
 * @param content - message content
 * @param from - sender ID
 * @param to - receiver ID
 * @param fn - callback function
 * @param prior - task priority
 * @return true on success
 */
- (BOOL)sendContent:(id<DKDContent>)content
             sender:(id<MKMID>)from
           receiver:(id<MKMID>)to
           callback:(nullable DIMMessengerCallback)fn
           priority:(NSInteger)prior;

/**
 *  Send instant message (encrypt and sign) onto DIM network
 *
 * @param iMsg - instant message
 * @param callback - callback function
 * @return NO on data/delegate error
 */
- (BOOL)sendInstantMessage:(id<DKDInstantMessage>)iMsg
                  callback:(nullable DIMMessengerCallback)callback
                  priority:(NSInteger)prior;

- (BOOL)sendReliableMessage:(id<DKDReliableMessage>)rMsg
                   callback:(nullable DIMMessengerCallback)callback
                   priority:(NSInteger)prior;

@end

@interface DIMMessageTransmitter : NSObject <DIMTransmitter>

@property (readonly, weak, nonatomic) DIMMessenger *messenger;
@property (readonly, weak, nonatomic) id<DIMPacker> packer;

- (instancetype)initWithMessenger:(DIMMessenger *)transceiver;

@end

NS_ASSUME_NONNULL_END
