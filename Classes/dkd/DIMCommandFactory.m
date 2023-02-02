// license: https://mit-license.org
//
//  DIMP : Decentralized Instant Messaging Protocol
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

// Override
- (nullable id<DKDCommand>)parseCommand:(NSDictionary *)command {
    return _block(command);
}

@end

@implementation DIMGeneralCommandFactory

// Override
- (nullable id<DKDContent>)parseContent:(NSDictionary *)content {
    DIMFactoryManager *man = [DIMFactoryManager sharedManager];
    NSString *cmd = [man.generalFactory getCmd:content];
    // get factory by command name
    id<DKDCommandFactory> factory = [man.generalFactory commandFactoryForName:cmd];
    if (!factory) {
        // check for group commands
        if ([content objectForKey:@"group"]) {
            factory = [man.generalFactory commandFactoryForName:@"group"];
        }
        if (!factory) {
            factory = self;
        }
    }
    return [factory parseCommand:content];
}

// Override
- (nullable id<DKDCommand>)parseCommand:(NSDictionary *)command {
    return [[DIMCommand alloc] initWithDictionary:command];
}

@end

@implementation DIMHistoryCommandFactory

// Override
- (nullable id<DKDCommand>)parseCommand:(NSDictionary *)command {
    return [[DIMHistoryCommand alloc] initWithDictionary:command];
}

@end

@implementation DIMGroupCommandFactory

// Override
- (nullable id<DKDContent>)parseContent:(NSDictionary *)content {
    DIMFactoryManager *man = [DIMFactoryManager sharedManager];
    NSString *cmd = [man.generalFactory getCmd:content];
    // get factory by command name
    id<DKDCommandFactory> factory = [man.generalFactory commandFactoryForName:cmd];
    if (!factory) {
        factory = self;
    }
    return [factory parseCommand:content];
}

// Override
- (nullable id<DKDCommand>)parseCommand:(NSDictionary *)command {
    return [[DIMGroupCommand alloc] initWithDictionary:command];
}

@end

void DIMRegisterCommandFactories(void) {

    // Meta Command
    DIMCommandRegisterClass(DIMCommand_Meta, DIMMetaCommand);

    // Document Command
    DIMCommandRegisterClass(DIMCommand_Document, DIMDocumentCommand);

    // Group Commands
    DIMCommandRegister(@"group", [[DIMGroupCommandFactory alloc] init]);
    DIMCommandRegisterClass(DIMGroupCommand_Invite, DIMInviteGroupCommand);
    DIMCommandRegisterClass(DIMGroupCommand_Expel, DIMExpelGroupCommand);
    DIMCommandRegisterClass(DIMGroupCommand_Join, DIMJoinGroupCommand);
    DIMCommandRegisterClass(DIMGroupCommand_Quit, DIMQuitGroupCommand);
    DIMCommandRegisterClass(DIMGroupCommand_Query, DIMQueryGroupCommand);
    DIMCommandRegisterClass(DIMGroupCommand_Reset, DIMResetGroupCommand);
}
