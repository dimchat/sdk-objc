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
//  DIMContentProcessorCreator.h
//  DIMSDK
//
//  Created by Albert Moky on 2022/04/10.
//  Copyright © 2022 Albert Moky. All rights reserved.
//

#import "DIMForwardContentProcessor.h"
#import "DIMArrayContentProcessor.h"
//#import "DIMCustomizedContentProcessor.h"

#import "DIMMetaCommandProcessor.h"
#import "DIMDocumentCommandProcessor.h"

#import "DIMContentProcessorCreator.h"

#define CREATE_CPU(clazz)                                                      \
            [[clazz alloc] initWithFacebook:self.facebook                      \
                                  messenger:self.messenger]                    \
                                                   /* EOF 'CREATE_CPU(clazz)' */

@implementation DIMContentProcessorCreator

- (id<DIMContentProcessor>)createContentProcessor:(DKDContentType)type {
    // forward content
    if (type == DKDContentType_Forward) {
        return CREATE_CPU(DIMForwardContentProcessor);
    }
    // array content
    if (type == DKDContentType_Array) {
        return CREATE_CPU(DIMArrayContentProcessor);
    }
    /*
    // application customized
    if (type == DKDContentType_Application) {
        return CREATE_CPU(DIMCustomizedContentProcessor);
    } else if (type == DKDContentType_Customized) {
        return CREATE_CPU(DIMCustomizedContentProcessor);
    }
     */
    // default commands
    if (type == DKDContentType_Command) {
        return CREATE_CPU(DIMCommandProcessor);
    }
    /*
    // default contents
    if (type == 0) {
        // must return a default processor for type==0
        return CREATE_CPU(DIMContentProcessor);
    }
     */
    // unknown
    return nil;
}

- (id<DIMContentProcessor>)createCommandProcessor:(NSString *)name type:(DKDContentType)msgType { 
    // meta command
    if ([name isEqualToString:DIMCommand_Meta]) {
        return CREATE_CPU(DIMMetaCommandProcessor);
    }
    // document command
    if ([name isEqualToString:DIMCommand_Document]) {
        return CREATE_CPU(DIMDocumentCommandProcessor);
    }
    // unknown
    return nil;
}

@end
