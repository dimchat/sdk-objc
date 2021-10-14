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

#import "DIMFacebook.h"
#import "DIMMessagePacker.h"
#import "DIMMessageProcessor.h"
#import "DIMMessageTransmitter.h"

#import "DIMMessenger.h"

@interface DIMMessenger () {
    
    //id<DIMMessengerDelegate> _delegate;
    
    id<DIMTransmitter> _transmitter;
    
    DIMFacebook *_facebook;
    DIMMessagePacker *_messagePacker;
    DIMMessageProcessor *_messageProcessor;
    DIMMessageTransmitter *_messageTransmitter;
}

@end

@implementation DIMMessenger

- (instancetype)init {
    if (self = [super init]) {
        
        _delegate = nil;
        
        _transmitter = nil;
        
        _facebook = nil;
        _messagePacker = nil;
        _messageProcessor = nil;
        _messageTransmitter = nil;
    }
    return self;
}

#pragma mark Facebook (EntityDelegate)

- (id<DIMEntityDelegate>)barrack {
    id<DIMEntityDelegate> delegate = [super barrack];
    if (!delegate) {
        delegate = [self facebook];
        [super setBarrack:delegate];
    }
    return delegate;
}
- (void)setBarrack:(id<DIMEntityDelegate>)barrack {
    [super setBarrack:barrack];
    if ([barrack isKindOfClass:[DIMFacebook class]]) {
        _facebook = (DIMFacebook *)barrack;
    }
}
- (DIMFacebook *)facebook {
    if (!_facebook) {
        _facebook = [self createFacebook];
    }
    return _facebook;
}
- (DIMFacebook *)createFacebook {
    NSAssert(false, @"implement me!");
    return nil;
}

#pragma mark Message Packer

- (id<DIMPacker>)packer {
    id<DIMPacker> delegate = [super packer];
    if (!delegate) {
        delegate = [self messagePacker];
        [super setPacker:delegate];
    }
    return delegate;
}
- (void)setPacker:(id<DIMPacker>)packer {
    [super setPacker:packer];
    if ([packer isKindOfClass:[DIMMessagePacker class]]) {
        _messagePacker = (DIMMessagePacker *)packer;
    }
}
- (DIMMessagePacker *)messagePacker {
    if (!_messagePacker) {
        _messagePacker = [self createMessagePacker];
    }
    return _messagePacker;
}
- (DIMMessagePacker *)createMessagePacker {
    return [[DIMMessagePacker alloc] initWithMessenger:self];
}

#pragma mark Message Processor

- (id<DIMProcessor>)processor {
    id<DIMProcessor> delegate = [super processor];
    if (!delegate) {
        delegate = [self messageProcessor];
        [super setProcessor:delegate];
    }
    return delegate;
}
- (void)setProcessor:(id<DIMProcessor>)processor {
    [super setProcessor:processor];
    if ([processor isKindOfClass:[DIMMessageProcessor class]]) {
        _messageProcessor = (DIMMessageProcessor *)processor;
    }
}
- (DIMMessageProcessor *)messageProcessor {
    if (!_messageProcessor) {
        _messageProcessor = [self createMessageProcessor];
    }
    return _messageProcessor;
}
- (DIMMessageProcessor *)createMessageProcessor {
    return [[DIMMessageProcessor alloc] initWithMessenger:self];
}

#pragma mark Message Transmitter

- (id<DIMTransmitter>)transmitter {
    id<DIMTransmitter> delegate = _transmitter;
    if (!delegate) {
        delegate = _transmitter = [self messageTransmitter];
    }
    return delegate;
}
- (void)setTransmitter:(id<DIMTransmitter>)transmitter {
    _transmitter = transmitter;
    if ([transmitter isKindOfClass:[DIMMessageTransmitter class]]) {
        _messageTransmitter = (DIMMessageTransmitter *)transmitter;
    }
}
- (DIMMessageTransmitter *)messageTransmitter {
    if (!_messageTransmitter) {
        _messageTransmitter = [self createMessageTransmitter];
    }
    return _messageTransmitter;
}
- (DIMMessageTransmitter *)createMessageTransmitter {
    NSAssert(false, @"implements me!");
    return nil;
}

@end

@implementation DIMMessenger (Processing)

- (NSArray<NSData *> *)processData:(NSData *)data {
    return [self.messageProcessor processData:data];
}

- (NSArray<id<DKDReliableMessage>> *)processMessage:(id<DKDReliableMessage>)rMsg {
    return [self.messageProcessor processMessage:rMsg];
}

@end

@implementation DIMMessenger (Send)

- (BOOL)sendContent:(id<DKDContent>)content sender:(nullable id<MKMID>)from receiver:(id<MKMID>)to callback:(nullable DIMMessengerCallback)fn priority:(NSInteger)prior {
    if (!from) {
        // Application Layer should make sure user is already login before it send message to server.
        // Application layer should put message into queue so that it will send automatically after user login
        DIMUser *user = [self.facebook currentUser];
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
