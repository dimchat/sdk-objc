// license: https://mit-license.org
//
//  DIMP : Decentralized Instant Messaging Protocol
//
//                               Written in 2025 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2025 Albert Moky
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
//  DIMMessageHelpers.m
//  DIMSDK
//
//  Created by Albert Moky on 2025/10/12.
//  Copyright © 2025 Albert Moky. All rights reserved.
//

#import "DIMMessageHelpers.h"

@implementation DIMCipherKeyDelegate

// Override
- (nullable id<MKSymmetricKey>)cipherKeyWithSender:(id<MKMID>)from
                                          receiver:(id<MKMID>)to
                                          generate:(BOOL)create {
    NSAssert(false, @"implement me!");
    return nil;
}

// Override
- (void)cacheCipherKey:(id<MKSymmetricKey>)key
            withSender:(id<MKMID>)from
              receiver:(id<MKMID>)to {
    NSAssert(false, @"implement me!");
}

+ (id<MKMID>)destinationOfMessage:(id<DKDMessage>)msg {
    id<MKMID> receiver = [msg receiver];
    id<MKMID> group = MKMIDParse([msg objectForKey:@"group"]);
    return [self destinationToReceiver:receiver orGroup:group];
}

+ (id<MKMID>)destinationToReceiver:(id<MKMID>)receiver
                           orGroup:(nullable id<MKMID>)group {
    if (!group && [receiver isGroup]) {
        /// Transform:
        ///     (B) => (J)
        ///     (D) => (G)
        group = receiver;
    }
    if (!group) {
        /// A : personal message (or hidden group message)
        /// C : broadcast message for anyone
        NSAssert([receiver isUser], @"receiver error: %@", receiver);
        return receiver;
    }
    NSAssert([group isGroup], @"group error: %@, receiver: %@", group, receiver);
    if ([group isBroadcast]) {
        /// E : unencrypted message for someone
        //      return group as broadcast ID for disable encryption
        /// F : broadcast message for anyone
        /// G : (receiver == group) broadcast group message
        NSAssert([receiver isUser] || [receiver isEqual:group], @"receiver error: %@", receiver);
        return group;
    } else if ([receiver isBroadcast]) {
        /// K : unencrypted group message, usually group command
        //      return receiver as broadcast ID for disable encryption
        NSAssert([receiver isUser], @"receiver error: %@, group: %@", receiver, group);
        return receiver;
    } else {
        /// H    : group message split for someone
        /// J    : (receiver == group) non-split group message
        return group;
    }
}

@end
