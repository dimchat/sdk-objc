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

@protocol DIMTransmitter;

@class DIMFacebook;

@interface DIMMessenger : DIMTransceiver

/**
 *  Delegate for transmitting message
 */
@property (weak, nonatomic) __kindof id<DIMTransmitter> transmitter;

@property (readonly, strong, nonatomic) DIMFacebook *facebook;

- (DIMFacebook *)createFacebook;

@end

@interface DIMMessenger (Processing)

//
//  Interfaces for Processing Message
//

- (NSData *)processData:(NSData *)data;

- (id<DKDReliableMessage>)processMessage:(id<DKDReliableMessage>)rMsg;

@end

@interface DIMMessenger (Sending)

//
//  Interfaces for Sending Message
//

- (BOOL)sendContent:(id<DKDContent>)content
             sender:(nullable id<MKMID>)from
           receiver:(id<MKMID>)to
           callback:(nullable DIMMessengerCallback)fn
           priority:(NSInteger)prior;

- (BOOL)sendInstantMessage:(id<DKDInstantMessage>)iMsg
                  callback:(nullable DIMMessengerCallback)callback
                  priority:(NSInteger)prior;

- (BOOL)sendReliableMessage:(id<DKDReliableMessage>)rMsg
                   callback:(nullable DIMMessengerCallback)callback
                   priority:(NSInteger)prior;

@end

@interface DIMMessenger (Packing)

//
//  Interfaces for Packing Message
//

- (nullable id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg;

- (nullable id<DKDReliableMessage>)signMessage:(id<DKDSecureMessage>)sMsg;

- (nullable NSData *)serializeMessage:(id<DKDReliableMessage>)rMsg;

- (nullable id<DKDReliableMessage>)deserializeMessage:(NSData *)data;

- (nullable id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg;

- (nullable id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg;

@end

NS_ASSUME_NONNULL_END
