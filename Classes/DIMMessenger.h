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
typedef void (^DIMMessengerCallback)(id<DKDReliableMessage>rMsg,
                                     NSError * _Nullable error);

/**
 *  Handler to call after sending package complete
 *  executed by application
 */
typedef void (^DIMMessengerCompletionHandler)(NSError * _Nullable error);

@protocol DIMMessengerDelegate <NSObject>

/**
 *  Send out a data package onto network
 *
 *  @param data - package`
 *  @param handler - completion handler
 *  @param prior - task priority
 *  @return NO on data/delegate error
 */
- (BOOL)sendPackageData:(NSData *)data
      completionHandler:(nullable DIMMessengerCompletionHandler)handler
               priority:(NSInteger)prior;

/**
 *  Upload encrypted data to CDN
 *
 *  @param CT - encrypted file data
 *  @param iMsg - instant message
 *  @return download URL
 */
- (nullable NSURL *)uploadData:(NSData *)CT forMessage:(id<DKDInstantMessage>)iMsg;

/**
 *  Download encrypted data from CDN
 *
 *  @param url - download URL
 *  @param iMsg - instant message
 *  @return encrypted file data
 */
- (nullable NSData *)downloadData:(NSURL *)url forMessage:(id<DKDInstantMessage>)iMsg;

@end

@protocol DIMMessengerDataSource <NSObject>

/**
 * Save the message into local storage
 *
 * @param iMsg - instant message
 * @return true on success
 */
- (BOOL)saveMessage:(id<DKDInstantMessage>)iMsg;

/**
 *  Suspend message for the contact's meta
 *
 * @param msg - message received from network / instant message to be sent
 * @return NO on error
 */
- (BOOL)suspendMessage:(id<DKDMessage>)msg;

@end

#pragma mark -

@protocol DIMTransmitter;
@class DIMFacebook;
@class DIMMessagePacker;
@class DIMMessageProcessor;
@class DIMMessageTransmitter;

@interface DIMMessenger : DIMTransceiver

@property (weak, nonatomic) id<DIMMessengerDelegate> delegate;
@property (weak, nonatomic) id<DIMMessengerDataSource> dataSource;

@property (weak, nonatomic) id<DIMTransmitter> transmitter;

@property (strong, nonatomic) DIMFacebook *facebook;
@property (strong, nonatomic) DIMMessagePacker *messagePacker;
@property (strong, nonatomic) DIMMessageProcessor *messageProcessor;
@property (strong, nonatomic) DIMMessageTransmitter *messageTransmitter;

- (DIMFacebook *)createFacebook;
- (DIMMessagePacker *)createMessagePacker;
- (DIMMessageProcessor *)createMessageProcessor;
- (DIMMessageTransmitter *)createMessageTransmitter;

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

@interface DIMMessenger (Station)

//
//  Interfaces for Station
//

- (BOOL)sendPackageData:(NSData *)data
      completionHandler:(nullable DIMMessengerCompletionHandler)handler
               priority:(NSInteger)prior;

- (nullable NSURL *)uploadData:(NSData *)CT forMessage:(id<DKDInstantMessage>)iMsg;

- (nullable NSData *)downloadData:(NSURL *)url forMessage:(id<DKDInstantMessage>)iMsg;

@end

@interface DIMMessenger (Storage)

//
//  Interfaces for Message Storage
//

- (BOOL)saveMessage:(id<DKDInstantMessage>)iMsg;

- (BOOL)suspendMessage:(id<DKDMessage>)msg;

@end

NS_ASSUME_NONNULL_END
