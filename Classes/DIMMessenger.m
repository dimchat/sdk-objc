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
//  DIMMessenger.m
//  DIMClient
//
//  Created by Albert Moky on 2019/8/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMContentProcessor.h"
#import "DIMFileContentProcessor.h"

#import "DIMMessageProcessor.h"
#import "DIMMessageTransmitter.h"

#import "DIMFacebook.h"

#import "DIMMessenger.h"

@interface DIMMessenger ()

@property (strong, nonatomic) DIMMessagePacker *messagePacker;
@property (strong, nonatomic) DIMMessageProcessor *messageProcessor;
@property (strong, nonatomic) DIMMessageTransmitter *messageTransmitter;

@end

@implementation DIMMessenger

- (instancetype)init {
    if (self = [super init]) {
        
        _delegate = nil;
        _dataSource = nil;
        
        _messagePacker = nil;
        _messageProcessor = nil;
        _messageTransmitter = nil;
    }
    return self;
}

- (DIMFacebook *)facebook {
    return (DIMFacebook *)self.barrack;
}
- (void)setFacebook:(DIMFacebook *)facebook {
    self.barrack = facebook;
}

- (DIMMessagePacker *)messagePacker {
    if (!_messagePacker) {
        _messagePacker = [self newMessagePacker];
    }
    return _messagePacker;
}
- (DIMMessagePacker *)newMessagePacker {
    return [[DIMMessagePacker alloc] initWithMessenger:self];
}

- (DIMMessageProcessor *)messageProcessor {
    if (!_messageProcessor) {
        _messageProcessor = [self newMessageProcessor];
    }
    return _messageProcessor;
}
- (DIMMessageProcessor *)newMessageProcessor {
    return [[DIMMessageProcessor alloc] initWithMessenger:self];
}

- (DIMMessageTransmitter *)messageTransmitter {
    if (!_messageTransmitter) {
        _messageTransmitter = [self newMessageTransmitter];
    }
    return _messageTransmitter;
}
- (DIMMessageTransmitter *)newMessageTransmitter {
    return [[DIMMessageTransmitter alloc] initWithMessenger:self];
}

- (DIMFileContentProcessor *)fileContentProcessor {
    DIMFileContentProcessor *fpu = [DIMContentProcessor getProcessorForType:DKDContentType_File];
    NSAssert([fpu isKindOfClass:[DIMFileContentProcessor class]],
             @"failed to get file content processor");
    fpu.messenger = self;
    return fpu;
}

#pragma mark DKDInstantMessageDelegate

- (nullable NSData *)message:(id<DKDInstantMessage>)iMsg
            serializeContent:(id<DKDContent>)content
                     withKey:(id<MKMSymmetricKey>)password {
    // check attachment for File/Image/Audio/Video message content
    if ([content isKindOfClass:[DIMFileContent class]]) {
        DIMFileContentProcessor *fpu = [self fileContentProcessor];
        [fpu uploadFileContent:(id<DIMFileContent>)content
                           key:password
                       message:iMsg];
    }
    return [super message:iMsg serializeContent:content withKey:password];
}

- (nullable NSData *)message:(id<DKDInstantMessage>)iMsg
                  encryptKey:(NSData *)data
                 forReceiver:(id<MKMID>)receiver {
    id<MKMEncryptKey> key = [self.facebook publicKeyForEncryption:receiver];
    if (!key) {
        // save this message in a queue waiting receiver's meta response
        [self suspendMessage:iMsg];
        //NSAssert(false, @"failed to get encrypt key for receiver: %@", receiver);
        return nil;
    }
    return [super message:iMsg encryptKey:data forReceiver:receiver];
}

#pragma mark DKDSecureMessageDelegate

- (nullable id<DKDContent>)message:(id<DKDSecureMessage>)sMsg
              deserializeContent:(NSData *)data
                         withKey:(id<MKMSymmetricKey>)password {
    id<DKDContent> content = [super message:sMsg deserializeContent:data withKey:password];
    NSAssert(content, @"failed to deserialize message content: %@", sMsg);
    // check attachment for File/Image/Audio/Video message content
    if ([content isKindOfClass:[DIMFileContent class]]) {
        DIMFileContentProcessor *fpu = [self fileContentProcessor];
        [fpu downloadFileContent:(id<DIMFileContent>)content
                             key:password
                         message:sMsg];
    }
    return content;
}

@end

@implementation DIMMessenger (Processing)

- (NSData *)processData:(NSData *)data {
    return [self.messageProcessor processData:data];
}

- (id<DKDReliableMessage>)processMessage:(id<DKDReliableMessage>)rMsg {
    return [self.messageProcessor processMessage:rMsg];
}

@end

@implementation DIMMessenger (Send)

- (BOOL)sendContent:(id<DKDContent>)content sender:(nullable id<MKMID>)from receiver:(id<MKMID>)to callback:(nullable DIMMessengerCallback)fn priority:(NSInteger)prior {
    if (!from) {
        // Application Layer should make sure user is already login before it send message to server.
        // Application layer should put message into queue so that it will send automatically after user login
        MKMUser *user = [self.facebook currentUser];
        if (!user) {
            NSAssert(false, @"current user not set");
            return NO;
        }
        from = user.ID;
    }
    return [self.messageTransmitter sendContent:content sender:from receiver:to callback:fn priority:prior];
}

- (BOOL)sendInstantMessage:(id<DKDInstantMessage>)iMsg callback:(nullable DIMMessengerCallback)callback priority:(NSInteger)prior {
    return [self.messageTransmitter sendInstantMessage:iMsg callback:callback priority:prior];
}

- (BOOL)sendReliableMessage:(id<DKDReliableMessage>)rMsg callback:(nullable DIMMessengerCallback)callback priority:(NSInteger)prior {
    return [self.messageTransmitter sendReliableMessage:rMsg callback:callback priority:prior];
}

@end

@implementation DIMMessenger (Packing)

- (nullable id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg {
    return [self.messagePacker encryptMessage:iMsg];
}

- (nullable id<DKDReliableMessage>)signMessage:(id<DKDSecureMessage>)sMsg {
    return [self.messagePacker signMessage:sMsg];
}

- (nullable NSData *)serializeMessage:(id<DKDReliableMessage>)rMsg {
    return [self.messagePacker serializeMessage:rMsg];
}

- (nullable id<DKDReliableMessage>)deserializeMessage:(NSData *)data {
    return [self.messagePacker deserializeMessage:data];
}

- (nullable id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg {
    return [self.messagePacker verifyMessage:rMsg];
}

- (nullable id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg {
    return [self.messagePacker decryptMessage:sMsg];
}

@end

@implementation DIMMessenger (Station)

- (BOOL)sendPackageData:(NSData *)data
      completionHandler:(nullable DIMMessengerCompletionHandler)handler
               priority:(NSInteger)prior {
    return [self.delegate sendPackageData:data
                        completionHandler:handler
                                 priority:prior];
}

- (nullable NSURL *)uploadData:(NSData *)CT forMessage:(id<DKDInstantMessage>)iMsg {
    return [self.delegate uploadData:CT forMessage:iMsg];
}

- (nullable NSData *)downloadData:(NSURL *)url forMessage:(id<DKDInstantMessage>)iMsg {
    return [self.delegate downloadData:url forMessage:iMsg];
}

@end

@implementation DIMMessenger (Storage)

- (BOOL)saveMessage:(id<DKDInstantMessage>)iMsg {
    return [self.dataSource saveMessage:iMsg];
}

- (BOOL)suspendMessage:(id<DKDMessage>)msg {
    return [self.dataSource suspendMessage:msg];
}

@end
