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
//  DIMCommandProcessor.m
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 Albert Moky. All rights reserved.
//

#import "NSObject+Singleton.h"

#import "DIMMessenger.h"

#import "DIMMetaCommandProcessor.h"
#import "DIMProfileCommandProcessor.h"

#import "DIMCommandProcessor.h"

@interface _DefaultCommandProcessor : DIMCommandProcessor

@end

@implementation _DefaultCommandProcessor

//
//  Main
//
- (nullable DIMContent *)processContent:(DIMContent *)content
                                 sender:(DIMID *)sender
                                message:(DIMReliableMessage *)rMsg {
    NSAssert([content isKindOfClass:[DIMCommand class]], @"command error: %@", content);
    // process command content by name
    DIMCommand *cmd = (DIMCommand *)content;
    NSString *text = [NSString stringWithFormat:@"Command (%@) not support yet!", cmd.command];
    DIMContent *res = [[DIMTextContent alloc] initWithText:text];
    res.group = content.group;
    return res;
}

@end

static inline void load_cpu_classes(void) {
    // meta
    [DIMCommandProcessor registerClass:[DIMMetaCommandProcessor class]
                            forCommand:DIMCommand_Meta];
    // profile
    [DIMCommandProcessor registerClass:[DIMProfileCommandProcessor class]
                            forCommand:DIMCommand_Profile];
    // unknown command (default)
    [DIMCommandProcessor registerClass:[_DefaultCommandProcessor class]
                            forCommand:DIMCommand_Unknown];
}

#pragma mark -

@interface DIMCommandProcessor () {
    
    NSMutableDictionary<NSString *, DIMCommandProcessor *> *_processors;
}

@end

@interface DIMCommandProcessor (Create)

- (DIMCommandProcessor *)processorForCommand:(NSString *)name;

@end

@implementation DIMCommandProcessor

- (instancetype)initWithMessenger:(DIMMessenger *)messenger {
    if (self = [super initWithMessenger:messenger]) {
        _processors = nil;
        
        // register CPU classes
        SingletonDispatchOnce(^{
            load_cpu_classes();
        });
    }
    return self;
}

//
//  Main
//
- (nullable DIMContent *)processContent:(DIMContent *)content
                                 sender:(DIMID *)sender
                                message:(DIMReliableMessage *)rMsg {
    NSAssert([self isMemberOfClass:[DIMCommandProcessor class]], @"error!");
    NSAssert([content isKindOfClass:[DIMCommand class]], @"command error: %@", content);
    // process command content by name
    DIMCommand *cmd = (DIMCommand *)content;
    DIMCommandProcessor *cpu = [self processorForCommand:cmd.command];
    NSAssert(cpu != self, @"Dead cycle!");
    return [cpu processContent:content sender:sender message:rMsg];
}

@end

static NSMutableDictionary<NSString *, Class> *cpu_classes(void) {
    static NSMutableDictionary<NSString *, Class> *classes = nil;
    SingletonDispatchOnce(^{
        classes = [[NSMutableDictionary alloc] init];
        // ...
    });
    return classes;
}

@implementation DIMCommandProcessor (Runtime)

+ (void)registerClass:(Class)clazz forCommand:(NSString *)name {
    NSAssert(![clazz isEqual:self], @"only subclass");
    if (clazz) {
        NSAssert([clazz isSubclassOfClass:self], @"error: %@", clazz);
        [cpu_classes() setObject:clazz forKey:name];
    } else {
        [cpu_classes() removeObjectForKey:name];
    }
}

- (DIMContentProcessor *)processorForCommand:(NSString *)name {
    SingletonDispatchOnce(^{
        self->_processors = [[NSMutableDictionary alloc] init];
    });
    // 1. get from pool
    DIMCommandProcessor *cpu = [_processors objectForKey:name];
    if (cpu) {
        return cpu;
    }
    // 2. get CPU class by command name
    Class clazz = [cpu_classes() objectForKey:name];
    if (!clazz) {
        if ([name isEqualToString:DIMCommand_Unknown]) {
            NSAssert(false, @"default CPU not register yet");
            return nil;
        }
        // call default CPU
        return [self processorForCommand:DIMCommand_Unknown];
    }
    // 3. create CPU with messenger
    cpu = [[clazz alloc] initWithMessenger:self.messenger];
    [_processors setObject:cpu forKey:name];
    return cpu;
}

@end

