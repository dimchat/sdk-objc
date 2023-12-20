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
//  DIMArrayContentProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2022/8/9.
//  Copyright © 2022 Albert Moky. All rights reserved.
//

#import "DIMMessenger.h"

#import "DIMArrayContentProcessor.h"

@implementation DIMArrayContentProcessor

//
//  Main
//
- (NSArray<id<DKDContent>> *)processContent:(__kindof id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content conformsToProtocol:@protocol(DKDArrayContent)],
             @"array content error: %@", content);
    // get content array
    NSArray<id<DKDContent>> *array = [content contents];
    // call messenger to process it
    DIMMessenger *messenger = self.messenger;
    NSMutableArray *responses = [[NSMutableArray alloc] initWithCapacity:[array count]];
    id<DKDContent> res;
    NSArray *results;
    for (id<DKDContent> item in array) {
        results = [messenger processContent:item
                 withReliableMessageMessage:rMsg];
        /*if (!results) {
            res = [[DIMArrayContent alloc] initWithContents:@[]];
        } else */if ([results count] == 1) {
            res = [results firstObject];
        } else {
            res = [[DIMArrayContent alloc] initWithContents:results];
        }
        [responses addObject:res];
    }
    return responses;
}

@end
