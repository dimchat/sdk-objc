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
//  DIMCommandFactory.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMCommandFactory.h"

@interface DIMCommandFactory () {
    
    DIMCommandParserBlock _block;
}

@end

@implementation DIMCommandFactory

- (instancetype)init {
    NSAssert(false, @"don't call me!");
    DIMCommandParserBlock block = NULL;
    return [self initWithBlock:block];
}

/* NS_DESIGNATED_INITIALIZER */
- (instancetype)initWithBlock:(DIMCommandParserBlock)block {
    if (self = [super init]) {
        _block = block;
    }
    return self;
}

- (nullable id<DKDCommand>)parseCommand:(NSDictionary *)content {
    return _block(content);
}

@end

@implementation DIMBaseCommandFactory

- (nullable id<DKDContent>)parseContent:(NSDictionary *)content {
    DIMCommandFactoryManager *man = [DIMCommandFactoryManager sharedManager];
    // get factory by command name
    NSString *cmd = [man.generalFactory getCmd:content defaultValue:@"*"];
    id<DKDCommandFactory> factory = [man.generalFactory commandFactoryForName:cmd];
    if (!factory) {
        // check for group commands
        if ([content objectForKey:@"group"]
            /*&& ![cmd isEqualToString:@"group"]*/) {
            factory = [man.generalFactory commandFactoryForName:@"group"];
        }
        if (!factory) {
            factory = self;
        }
    }
    return [factory parseCommand:content];
}

- (nullable id<DKDCommand>)parseCommand:(NSDictionary *)content {
    return [[DIMCommand alloc] initWithDictionary:content];
}

@end

@implementation DIMHistoryCommandFactory

- (nullable id<DKDCommand>)parseCommand:(NSDictionary *)content {
    return [[DIMHistoryCommand alloc] initWithDictionary:content];
}

@end

@implementation DIMGroupCommandFactory

- (nullable id<DKDContent>)parseContent:(NSDictionary *)content {
    DIMCommandFactoryManager *man = [DIMCommandFactoryManager sharedManager];
    // get factory by command name
    NSString *cmd = [man.generalFactory getCmd:content defaultValue:@"*"];
    id<DKDCommandFactory> factory = [man.generalFactory commandFactoryForName:cmd];
    if (!factory) {
        factory = self;
    }
    return [factory parseCommand:content];
}

- (nullable id<DKDCommand>)parseCommand:(NSDictionary *)content {
    return [[DIMGroupCommand alloc] initWithDictionary:content];
}

@end

void DIMRegisterCommandFactories(void) {

    // Meta Command
    DIMCommandRegisterClass(DIMCommand_Meta, DIMMetaCommand);

    // Document Command
    DIMCommandRegisterClass(DIMCommand_Document, DIMDocumentCommand);
    
    // Receipt Command
    DIMCommandRegisterClass(DIMCommand_Receipt, DIMReceiptCommand);

    // Group Commands
    DIMCommandRegister(@"group", [[DIMGroupCommandFactory alloc] init]);
    DIMCommandRegisterClass(DIMGroupCommand_Invite, DIMInviteGroupCommand);
    // 'expel' is deprecated (use 'reset' instead)
    DIMCommandRegisterClass(DIMGroupCommand_Expel, DIMExpelGroupCommand);
    DIMCommandRegisterClass(DIMGroupCommand_Join, DIMJoinGroupCommand);
    DIMCommandRegisterClass(DIMGroupCommand_Quit, DIMQuitGroupCommand);
    DIMCommandRegisterClass(DIMGroupCommand_Query, DIMQueryGroupCommand);
    DIMCommandRegisterClass(DIMGroupCommand_Reset, DIMResetGroupCommand);
    // Group Admin Commands
    // TODO:
}
