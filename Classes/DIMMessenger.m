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
    
    DIMFacebook *_facebook;
}

@end

@implementation DIMMessenger

- (instancetype)init {
    if (self = [super init]) {
        
        _transmitter = nil;
        
        _facebook = nil;
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

@end

@implementation DIMMessenger (Send)

- (BOOL)sendContent:(id<DKDContent>)content sender:(nullable id<MKMID>)from receiver:(id<MKMID>)to callback:(nullable DIMMessengerCallback)fn priority:(NSInteger)prior {
    return [self.transmitter sendContent:content sender:from receiver:to callback:fn priority:prior];
}

- (BOOL)sendInstantMessage:(id<DKDInstantMessage>)iMsg callback:(nullable DIMMessengerCallback)callback priority:(NSInteger)prior {
    return [self.transmitter sendInstantMessage:iMsg callback:callback priority:prior];
}

- (BOOL)sendReliableMessage:(id<DKDReliableMessage>)rMsg callback:(nullable DIMMessengerCallback)callback priority:(NSInteger)prior {
    return [self.transmitter sendReliableMessage:rMsg callback:callback priority:prior];
}

@end
