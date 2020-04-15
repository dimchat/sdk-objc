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
//  DIMMessenger+Send.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/8/6.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "DKDInstantMessage+Extension.h"
#import "DIMFacebook.h"

#import "DIMMessenger.h"

@implementation DIMMessenger (Send)

- (BOOL)sendContent:(DIMContent *)content
           receiver:(DIMID *)receiver {
    
    return [self sendContent:content receiver:receiver callback:NULL dispersedly:NO];
}

- (BOOL)sendContent:(DIMContent *)content
           receiver:(DIMID *)receiver
           callback:(nullable DIMMessengerCallback)callback {
    
    return [self sendContent:content receiver:receiver callback:callback dispersedly:NO];
}

- (BOOL)sendContent:(DIMContent *)content
           receiver:(DIMID *)receiver
           callback:(nullable DIMMessengerCallback)callback
        dispersedly:(BOOL)split {
    
    //Application Layer should make sure user is already login before it send message to server.
    //Application layer should put message into queue so that it will send automatically after user login
    DIMUser *user = self.facebook.currentUser;
    NSAssert(user, @"current user not found");
    
    DIMInstantMessage *iMsg;
    iMsg = [[DIMInstantMessage alloc] initWithContent:content
                                               sender:user.ID
                                             receiver:receiver
                                                 time:nil];
    return [self sendInstantMessage:iMsg
                           callback:callback
                        dispersedly:split];
}

- (BOOL)sendInstantMessage:(DIMInstantMessage *)iMsg {
    
    return [self sendInstantMessage:iMsg callback:NULL dispersedly:NO];
}

- (BOOL)sendInstantMessage:(DIMInstantMessage *)iMsg
                  callback:(nullable DIMMessengerCallback)callback {
    
    return [self sendInstantMessage:iMsg callback:callback dispersedly:NO];
}

- (BOOL)sendInstantMessage:(DIMInstantMessage *)iMsg
                  callback:(nullable DIMMessengerCallback)callback
               dispersedly:(BOOL)split {
    
    // Send message (secured + certified) to target station
    DIMSecureMessage *sMsg = [self encryptMessage:iMsg];
    DIMReliableMessage *rMsg = [self signMessage:sMsg];
    if (!rMsg) {
        NSAssert(false, @"failed to encrypt and sign message: %@", iMsg);
        iMsg.content.state = DIMMessageState_Error;
        iMsg.content.error = @"Encryption failed.";
        return NO;
    }
    
    DIMID *receiver = [self.facebook IDWithString:iMsg.envelope.receiver];
    BOOL OK = YES;
    if (split && [receiver isGroup]) {
        NSAssert([receiver isEqual:iMsg.content.group], @"error: %@", iMsg);
        // split for each members
        NSArray<DIMID *> *members = [self.facebook membersOfGroup:receiver];
        NSAssert([members count] > 0, @"group members empty: %@", receiver);
        NSArray *messages = [rMsg splitForMembers:members];
        if ([members count] == 0) {
            NSLog(@"failed to split msg, send it to group: %@", receiver);
            OK = [self sendReliableMessage:rMsg callback:callback];
        } else {
            for (DIMReliableMessage *item in messages) {
                if (![self sendReliableMessage:item callback:callback]) {
                    OK = NO;
                }
            }
        }
    } else {
        OK = [self sendReliableMessage:rMsg callback:callback];
    }
    
    // sending status
    if (OK) {
        iMsg.content.state = DIMMessageState_Sending;
    } else {
        NSLog(@"cannot send message now, put in waiting queue: %@", iMsg);
        iMsg.content.state = DIMMessageState_Waiting;
    }
    
    if (![self saveMessage:iMsg]) {
        return NO;
    }
    return OK;
}

- (BOOL)sendReliableMessage:(DIMReliableMessage *)rMsg {
    
    return [self sendReliableMessage:rMsg callback:NULL];
}

- (BOOL)sendReliableMessage:(DIMReliableMessage *)rMsg
                   callback:(nullable DIMMessengerCallback)callback {
    
    NSData *data = [self serializeMessage:rMsg];
    NSAssert(self.delegate, @"transceiver delegate not set");
    return [self.delegate sendPackage:data
                    completionHandler:^(NSError * _Nullable error) {
                        !callback ?: callback(rMsg, error);
                    }];
}

@end
