// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2022 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2022 Albert Moky
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
//  DIMCustomizedContentProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2022/8/9.
//  Copyright © 2022 Albert Moky. All rights reserved.
//

#import "DIMCustomizedContentProcessor.h"

@implementation DIMCustomizedContentProcessor

// override for your application
- (NSArray<id<DKDContent>> *)filterApplication:(NSString *)app
                                       content:(id<DKDCustomizedContent>)customized
                                      messasge:(id<DKDReliableMessage>)rMsg {
    NSString *text = [NSString stringWithFormat:@"Customized Content (app: %@) not support yet!", app];
    return [self respondText:text withGroup:nil];
}

// override for your module
- (id<DIMCustomizedContentHandler>)fetchModule:(NSString *)mod
                                       content:(id<DKDCustomizedContent>)customized
                                      messasge:(id<DKDReliableMessage>)rMsg {
    // if the application has too many modules, I suggest you to
    // use different handler to do the jobs for each module.
    return self;
}

// override for customized actions
- (NSArray<id<DKDContent>> *)handleAction:(NSString *)act
                                   sender:(id<MKMID>)uid
                                  content:(id<DKDCustomizedContent>)customized
                                  message:(id<DKDReliableMessage>)rMsg {
    NSString *app = [customized application];
    NSString *mod = [customized module];
    NSString *text = [NSString stringWithFormat:@"Customized Content (app: %@, mod: %@, act: %@) not support yet!", app, mod, act];
    return [self respondText:text withGroup:nil];
}

// override for customized actions
- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content conformsToProtocol:@protocol(DKDCustomizedContent)],
             @"customized content error: %@", content);
    id<DKDCustomizedContent> customized = (id<DKDCustomizedContent>)content;
    // 1. check app id
    NSString *app = [customized application];
    NSArray *res = [self filterApplication:app content:customized messasge:rMsg];
    if (res) {
        // app id not found
        return res;
    }
    // 2. get handler with module name
    NSString *mod = [customized module];
    id<DIMCustomizedContentHandler> handler = [self fetchModule:mod content:customized messasge:rMsg];
    if (!handler) {
        // module not support
        return nil;
    }
    // 3. do the job
    NSString *act = [customized action];
    id<MKMID> sender = [rMsg sender];
    return [handler handleAction:act sender:sender content:customized message:rMsg];
}

@end
