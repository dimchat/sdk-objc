// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2023 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2023 Albert Moky
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
//  DIMMessageFactory.m
//  DIMSDK
//
//  Created by Albert Moky on 2023/2/2.
//  Copyright © 2023 Albert Moky. All rights reserved.
//

#import "DIMContentFactory.h"
#import "DIMCommandFactory.h"

#import "DIMMessageFactory.h"

@implementation DIMEnvelopeFactory

- (id<DKDEnvelope>)createEnvelopeWithSender:(id<MKMID>)from
                                   receiver:(id<MKMID>)to
                                       time:(nullable NSDate *)when {
    return [[DIMEnvelope alloc] initWithSender:from receiver:to time:when];
}

- (nullable id<DKDEnvelope>)parseEnvelope:(NSDictionary *)env {
    // check 'sender'
    id sender = [env objectForKey:@"sender"];
    if (!sender) {
        // env.sender should not be empty
        return nil;
    }
    return [[DIMEnvelope alloc] initWithDictionary:env];
}

@end

@interface DIMInstantMessageFactory () {
    
    uint32_t _sn;
}

@end

@implementation DIMInstantMessageFactory

- (instancetype)init {
    if (self = [super init]) {
        _sn = arc4random();
    }
    return self;
}

/**
 *  next sn
 *
 * @return 1 ~ 2^31-1
 */
- (uint32_t)_next {
    uint32_t sn = _sn;
    if (sn < 0x7fffffff) {
        sn += 1;
    } else {
        sn = 1;
    }
    return _sn = sn;
}

- (NSUInteger)generateSerialNumber:(DKDContentType)type time:(NSDate *)now {
    // because we must make sure all messages in a same chat box won't have
    // same serial numbers, so we can't use time-related numbers, therefore
    // the best choice is a totally random number, maybe.
    /*/
    uint32_t sn = arc4random();
    if (sn == 0) {
        // ZERO? do it again!
        sn = 9527 + 9394;
    }
    return sn;
    /*/
    return [self _next];
}

- (id<DKDInstantMessage>)createInstantMessageWithEnvelope:(id<DKDEnvelope>)head
                                                  content:(id<DKDContent>)body {
    return [[DIMInstantMessage alloc] initWithEnvelope:head content:body];
}

- (nullable id<DKDInstantMessage>)parseInstantMessage:(NSDictionary *)msg {
    // check 'sender', 'content'
    id sender = [msg objectForKey:@"sender"];
    id content = [msg objectForKey:@"content"];
    if (!sender || !content) {
        // msg.sender should not be empty
        // msg.content should not be empty
        return nil;
    }
    return [[DIMInstantMessage alloc] initWithDictionary:msg];
}

@end

@implementation DIMSecureMessageFactory

- (nullable id<DKDSecureMessage>)parseSecureMessage:(NSDictionary *)msg {
    // check 'sender', 'data'
    id sender = [msg objectForKey:@"sender"];
    id data = [msg objectForKey:@"data"];
    if (!sender || !data) {
        // msg.sender should not be empty
        // msg.data should not be empty
        return nil;
    }
    // check 'signature'
    id signature = [msg objectForKey:@"signature"];
    if ([signature length] > 0) {
        return [[DIMReliableMessage alloc] initWithDictionary:msg];
    }
    return [[DIMSecureMessage alloc] initWithDictionary:msg];
}

@end

@implementation DIMReliableMessageFactory

- (nullable id<DKDReliableMessage>)parseReliableMessage:(NSDictionary *)msg {
    // check 'sender', 'data', 'signature'
    id sender = [msg objectForKey:@"sender"];
    id data = [msg objectForKey:@"data"];
    id signature = [msg objectForKey:@"signature"];
    if (!sender || !data || !signature) {
        // msg.sender should not be empty
        // msg.data should not be empty
        // msg.signature should not be empty
        return nil;
    }
    return [[DIMReliableMessage alloc] initWithDictionary:msg];
}

@end

void DIMRegisterMessageFactories(void) {
    // Envelope factory
    DKDEnvelopeSetFactory([[DIMEnvelopeFactory alloc] init]);
    // Message factories
    DKDInstantMessageSetFactory([[DIMInstantMessageFactory alloc] init]);
    DKDSecureMessageSetFactory([[DIMSecureMessageFactory alloc] init]);
    DKDReliableMessageSetFactory([[DIMReliableMessageFactory alloc] init]);
}

void DIMRegisterAllFactories(void) {
    //
    //  Register core factories
    //
    DIMRegisterMessageFactories();
    DIMRegisterContentFactories();
    DIMRegisterCommandFactories();
    
    //
    //  Register customized factories
    //
    DIMContentRegisterClass(DKDContentType_Customized, DIMCustomizedContent);
    DIMContentRegisterClass(DKDContentType_Application, DIMCustomizedContent);
}
