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
//  DIMContentFactory.m
//  DIMCore
//
//  Created by Albert Moky on 2020/12/8.
//  Copyright © 2020 DIM Group. All rights reserved.
//

#import "DIMCommandFactory.h"

#import "DIMContentFactory.h"

@interface DIMContentFactory () {
    
    DIMContentParserBlock _block;
}

@end

@implementation DIMContentFactory

- (instancetype)init {
    NSAssert(false, @"don't call me!");
    DIMContentParserBlock block = NULL;
    return [self initWithBlock:block];
}

/* NS_DESIGNATED_INITIALIZER */
- (instancetype)initWithBlock:(DIMContentParserBlock)block {
    if (self = [super init]) {
        _block = block;
    }
    return self;
}

- (nullable id<DKDContent>)parseContent:(NSDictionary *)content {
    return _block(content);
}

@end

void DIMRegisterContentFactories(void) {
    
    // Text
    DIMContentRegisterClass(DKDContentType_Text, DIMTextContent);
    
    // File
    DIMContentRegisterClass(DKDContentType_File, DIMFileContent);
    // Image
    DIMContentRegisterClass(DKDContentType_Image, DIMImageContent);
    // Audio
    DIMContentRegisterClass(DKDContentType_Audio, DIMAudioContent);
    // Video
    DIMContentRegisterClass(DKDContentType_Video, DIMVideoContent);
    
    // Web Page
    DIMContentRegisterClass(DKDContentType_Page, DIMPageContent);
    
    // Name Card
    DIMContentRegisterClass(DKDContentType_NameCard, DIMNameCard);
    
    // Money
    DIMContentRegisterClass(DKDContentType_Money, DIMMoneyContent);
    DIMContentRegisterClass(DKDContentType_Transfer, DIMTransferContent);
    
    // Command
    id<DKDContentFactory> cmdParser = [[DIMBaseCommandFactory alloc] init];
    DIMContentRegister(DKDContentType_Command, cmdParser);
    
    // History Command
    id<DKDContentFactory> hisParser = [[DIMHistoryCommandFactory alloc] init];
    DIMContentRegister(DKDContentType_History, hisParser);
    
    /*
    // Application Customized
    DIMContentRegisterClass(DKDContentType_Customized, DIMCustomizedContent);
    DIMContentRegisterClass(DKDContentType_Application, DIMCustomizedContent);
     */
    
    // Content Array
    DIMContentRegisterClass(DKDContentType_Array, DIMArrayContent);

    // Top-Secret
    DIMContentRegisterClass(DKDContentType_Forward, DIMForwardContent);

    // unknown content type
    DIMContentRegisterClass(0, DIMContent);
}
