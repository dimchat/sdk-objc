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

#import "DIMForwardContentProcessor.h"
#import "DIMFileContentProcessor.h"
#import "DIMCommandProcessor.h"
#import "DIMHistoryProcessor.h"

#import "DIMContentProcessor.h"

@implementation DIMContentProcessor

- (instancetype)init {
    if (self = [super init]) {
        self.messenger = nil;
    }
    return self;
}

- (DIMFacebook *)facebook {
    return self.messenger.facebook;
}

//
//  Main
//
- (nullable id<DKDContent>)processContent:(id<DKDContent>)content
                              withMessage:(id<DKDReliableMessage>)rMsg {
    NSString *text = [NSString stringWithFormat:@"Content (type: %u) not support yet!", content.type];
    id<DKDContent> res = [[DIMTextContent alloc] initWithText:text];
    // check group message
    id<MKMID> group = content.group;
    if (group) {
        res.group = group;
    }
    return res;
}

@end

@implementation DIMContentProcessor (CPU)

static NSMutableDictionary<NSNumber *, DIMContentProcessor *> *s_processors = nil;

+ (void)registerProcessor:(DIMContentProcessor *)processor
                  forType:(DKDContentType)type {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!s_processors) {
            s_processors = [[NSMutableDictionary alloc] init];
        }
    });
    [s_processors setObject:processor forKey:@(type)];
}

+ (nullable __kindof DIMContentProcessor *)getProcessorForContent:(id<DKDContent>)content {
    return [self getProcessorForType:content.type];
}

+ (nullable __kindof DIMContentProcessor *)getProcessorForType:(DKDContentType)type {
    return [s_processors objectForKey:@(type)];
}

@end

#pragma mark - Register Processors

@implementation DIMContentProcessor (Register)

+ (void)registerAllProcessors {
    //
    //  Register content processors
    //
    DIMContentProcessorRegisterClass(DKDContentType_Forward, DIMForwardContentProcessor);
    
    DIMFileContentProcessor *fileProcessor = [[DIMFileContentProcessor alloc] init];
    DIMContentProcessorRegister(DKDContentType_File, fileProcessor);
    DIMContentProcessorRegister(DKDContentType_Image, fileProcessor);
    DIMContentProcessorRegister(DKDContentType_Audio, fileProcessor);
    DIMContentProcessorRegister(DKDContentType_Video, fileProcessor);
    
    DIMContentProcessorRegisterClass(DKDContentType_Command, DIMCommandProcessor);
    DIMContentProcessorRegisterClass(DKDContentType_History, DIMHistoryCommandProcessor);
}

@end
