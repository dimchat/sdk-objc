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

#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMCustomizedContentProcessor.h"

@implementation DIMCustomizedContentHandler

- (NSArray<id<DKDReceiptCommand>> *)respondReceipt:(NSString *)text
                                   envelope:(id<DKDEnvelope>)head
                                    content:(nullable id<DKDContent>)body
                                      extra:(nullable NSDictionary *)info {
    return @[
        [DIMContentProcessor createReceipt:text
                                  envelope:head
                                   content:body
                                     extra:info]
    ];
}

// override for customized actions
- (NSArray<id<DKDContent>> *)handleAction:(NSString *)act
                                   sender:(id<MKMID>)uid
                                  content:(id<DKDCustomizedContent>)customized
                                  message:(id<DKDReliableMessage>)rMsg {
    NSString *app = [customized application];
    NSString *mod = [customized moduleName];
    // extra info for receipt
    NSDictionary *info = @{
        @"template": @"Customized content (app: ${app}, mod: ${mod}, act: ${act}) not support yet!",
        @"replacements": @{
            @"app": app,
            @"mod": mod,
            @"act": act,
        },
    };
    return [self respondReceipt:@"Content not support."
                       envelope:rMsg.envelope
                        content:customized
                          extra:info];
}

@end

#pragma mark -

@interface DIMCustomizedContentProcessor ()

@property (strong, nonatomic) __kindof id<DIMCustomizedContentHandler> defaultHandler;

@end

@implementation DIMCustomizedContentProcessor

- (instancetype)initWithFacebook:(DIMFacebook *)facebook
                       messenger:(DIMMessenger *)transceiver {
    if (self = [super initWithFacebook:facebook messenger:transceiver]) {
        self.defaultHandler = [self createDefaultHandler:facebook
                                               messenger:transceiver];
    }
    return self;
}

- (id<DIMCustomizedContentHandler>)createDefaultHandler:(DIMFacebook *)facebook
                                              messenger:(DIMMessenger *)transceiver {
    return [[DIMCustomizedContentHandler alloc] initWithFacebook:facebook
                                                       messenger:transceiver];
}

//
//  Main
//
- (NSArray<id<DKDContent>> *)processContent:(__kindof id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content conformsToProtocol:@protocol(DKDCustomizedContent)],
             @"customized content error: %@", content);
    id<DKDCustomizedContent> customized = content;
    // get handler for 'app' & 'mod'
    NSString *app = [customized application];
    NSString *mod = [customized moduleName];
    id<DIMCustomizedContentHandler> handler;
    handler = [self filterApplication:app
                           withModule:mod
                              content:content
                             messasge:rMsg];
    // hand the action
    NSString *act = [customized actionName];
    id<MKMID> sender = [rMsg sender];
    return [handler handleAction:act
                          sender:sender
                         content:customized
                         message:rMsg];
}

// override for your module
- (id<DIMCustomizedContentHandler>)filterApplication:(NSString *)app
                                          withModule:(NSString *)mod
                                             content:(id<DKDCustomizedContent>)body
                                            messasge:(id<DKDReliableMessage>)rMsg {
    // if the application has too many modules, I suggest you to
    // use different handler to do the jobs for each module.
    return [self defaultHandler];
}

@end
