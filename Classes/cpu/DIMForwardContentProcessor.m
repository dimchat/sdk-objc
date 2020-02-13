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
//  DIMForwardContentProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/2/13.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "DIMForwardContentProcessor.h"

@implementation DIMForwardContentProcessor

//
//  Main
//
- (nullable DIMContent *)processContent:(DIMContent *)content
                                 sender:(DIMID *)sender
                                message:(DIMInstantMessage *)iMsg {
    NSAssert([content isKindOfClass:[DIMForwardContent class]], @"forward content error: %@", content);
    DIMForwardContent *forward = (DIMForwardContent *)content;
    DIMReliableMessage *rMsg = forward.forwardMessage;
    
    // [Forward Protocol]
    // do it again to drop the wrapper,
    // the secret inside the content is the real message
    DIMSecureMessage *sMsg = [self.messenger verifyMessage:rMsg];
    if (!sMsg) {
        // TODO: save this message in a queue to wait meta response
        //[self.messenger suspendMessage:rMsg];
        //NSAssert(false, @"failed to verify message: " + rMsg);
        return nil;
    }
    
    return [self.messenger processSecureMessage:sMsg];

    // NOTICE: decrypt failed, not for you?
    //         check content type in subclass, if it's a 'forward' message,
    //         it means you are asked to re-pack and forward this message
    // TODO: override to catch the exception 'receiver error ...'
}

@end
