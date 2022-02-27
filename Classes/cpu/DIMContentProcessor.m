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
//  DIMContentProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 Albert Moky. All rights reserved.
//

#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMReceiptCommand.h"

#import "DIMContentProcessor.h"

@interface DIMContentProcessor ()

@property (weak, nonatomic) DIMMessenger *messenger;

@end

@implementation DIMContentProcessor

- (instancetype)init {
    NSAssert(false, @"don't call me!");
    DIMMessenger *messenger = nil;
    return [self initWithMessenger:messenger];
}

/* designated initializer */
- (instancetype)initWithMessenger:(DIMMessenger *)messenger {
    if (self = [super init]) {
        _messenger = messenger;
    }
    return self;
}

- (DIMFacebook *)facebook {
    return self.messenger.facebook;
}

//
//  Main
//
- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSString *text = [NSString stringWithFormat:DIM_CONTENT_NOT_SUPPORT_FMT, content.type];
    return [self respondText:text withGroup:content.group];
}

- (NSArray<id<DKDContent>> *)respondText:(NSString *)text withGroup:(nullable id<MKMID>)group {
    DIMTextContent *res = [[DIMTextContent alloc] initWithText:text];
    if (group) {
        res.group = group;
    }
    return @[res];
}

- (NSArray<id<DKDContent>> *)respondReceipt:(NSString *)text {
    DIMReceiptCommand *res = [[DIMReceiptCommand alloc] initWithMessage:text];
    return @[res];
}

- (NSArray<id<DKDContent>> *)respondContent:(nullable id<DKDContent>)res {
    if (!res) {
        return nil;
    } else {
        return @[res];
    }
}

@end
