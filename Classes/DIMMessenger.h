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
//  DIMMessenger.h
//  DIMClient
//
//  Created by Albert Moky on 2019/8/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Callback for sending message
 *  set by application and executed by DIM Core
 */
typedef void (^DIMMessengerCallback)(id<DKDReliableMessage> rMsg, NSError * _Nullable error);

/*
 *  Message Transmitter
 *  ~~~~~~~~~~~~~~~~~~~
 */
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
             sender:(nullable id<MKMID>)from
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

@protocol DIMCipherKeyDelegate <NSObject>

/**
 *  Get cipher key for encrypt message from 'sender' to 'receiver'
 *
 * @param sender - user or contact ID
 * @param receiver - contact or user/group ID
 * @param create - generate when key not exists
 * @return cipher key
 */
- (nullable id<MKMSymmetricKey>)cipherKeyFrom:(id<MKMID>)sender
                                           to:(id<MKMID>)receiver
                                     generate:(BOOL)create;

/**
 *  Cache cipher key for reusing, with the direction (from 'sender' to 'receiver')
 *
 * @param key - cipher key
 * @param sender - user or contact ID
 * @param receiver - contact or user/group ID
 */
- (void)cacheCipherKey:(id<MKMSymmetricKey>)key
                  from:(id<MKMID>)sender
                    to:(id<MKMID>)receiver;

@end

#pragma mark -

@interface DIMMessenger : DIMTransceiver <DIMCipherKeyDelegate, DIMPacker, DIMProcessor, DIMTransmitter>

/**
 *  Delegate for getting message key
 */
@property (weak, nonatomic) __kindof id<DIMCipherKeyDelegate> keyCache;

/**
 *  Delegate for parsing message
 */
@property (weak, nonatomic) __kindof id<DIMPacker> packer;

/**
 *  Delegate for processing message
 */
@property (weak, nonatomic) __kindof id<DIMProcessor> processor;

/**
 *  Delegate for transmitting message
 */
@property (weak, nonatomic) __kindof id<DIMTransmitter> transmitter;

@end

NS_ASSUME_NONNULL_END
