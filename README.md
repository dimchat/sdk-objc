# Decentralized Instant Messaging (Objective-C SDK)

[![License](https://img.shields.io/github/license/dimchat/sdk-objc)](https://github.com/dimchat/sdk-objc/blob/master/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/dimchat/sdk-objc/pulls)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20OSX%20%7C%20watchOS%20%7C%20tvOS-brightgreen.svg)](https://github.com/dimchat/sdk-objc/wiki)
[![Issues](https://img.shields.io/github/issues/dimchat/sdk-objc)](https://github.com/dimchat/sdk-objc/issues)
[![Repo Size](https://img.shields.io/github/repo-size/dimchat/sdk-objc)](https://github.com/dimchat/sdk-objc/archive/refs/heads/master.zip)
[![Tags](https://img.shields.io/github/tag/dimchat/sdk-objc)](https://github.com/dimchat/sdk-objc/tags)
[![Version](https://img.shields.io/cocoapods/v/DIMSDK
)](https://cocoapods.org/pods/DIMSDK)

[![Watchers](https://img.shields.io/github/watchers/dimchat/sdk-objc)](https://github.com/dimchat/sdk-objc/watchers)
[![Forks](https://img.shields.io/github/forks/dimchat/sdk-objc)](https://github.com/dimchat/sdk-objc/forks)
[![Stars](https://img.shields.io/github/stars/dimchat/sdk-objc)](https://github.com/dimchat/sdk-objc/stargazers)
[![Followers](https://img.shields.io/github/followers/dimchat)](https://github.com/orgs/dimchat/followers)

## Dependencies

* Latest Versions

| Name | Version | Description |
|------|---------|-------------|
| [Ming Ke Ming (名可名)](https://github.com/dimchat/mkm-objc) | [![Version](https://img.shields.io/cocoapods/v/MingKeMing)](https://cocoapods.org/pods/MingKeMing) | Decentralized User Identity Authentication |
| [Dao Ke Dao (道可道)](https://github.com/dimchat/dkd-objc) | [![Version](https://img.shields.io/cocoapods/v/DaoKeDao)](https://cocoapods.org/pods/DaoKeDao) | Universal Message Module |
| [DIMP (去中心化通讯协议)](https://github.com/dimchat/core-objc) | [![Version](https://img.shields.io/cocoapods/v/DIMCore)](https://cocoapods.org/pods/DIMCore) | Decentralized Instant Messaging Protocol |

## Extensions

### Content

extends [CustomizedContent](https://github.com/dimchat/core-objc#extends-content)

### ContentProcessor

```objective-c
#import <DIMSDK/DIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

/*
 *  Customized Content Processing Unit
 *  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *  Handle content for application customized
 */
@interface DIMAppCustomizedProcessor : DIMCustomizedContentProcessor

- (void)setContentHandler:(id<DIMCustomizedContentHandler>)handler
                forModule:(NSString *)mod
            inApplication:(NSString *)app;

// protected
- (nullable id<DIMCustomizedContentHandler>)contentHandlerForModule:(NSString *)mod
                                                      inApplication:(NSString *)app;

@end

/*  Command Transform:

    +===============================+===============================+
    |      Customized Content       |      Group Query Command      |
    +-------------------------------+-------------------------------+
    |   "type" : i2s(0xCC)          |   "type" : i2s(0x88)          |
    |   "sn"   : 123                |   "sn"   : 123                |
    |   "time" : 123.456            |   "time" : 123.456            |
    |   "app"  : "chat.dim.group"   |                               |
    |   "mod"  : "history"          |                               |
    |   "act"  : "query"            |                               |
    |                               |   "command"   : "query"       |
    |   "group"     : "{GROUP_ID}"  |   "group"     : "{GROUP_ID}"  |
    |   "last_time" : 0             |   "last_time" : 0             |
    +===============================+===============================+
 */
@interface DIMGroupHistoryHandler : DIMCustomizedContentHandler

@end

NS_ASSUME_NONNULL_END
```

```objective-c
#import "DIMGroupCommand.h"

#import "DIMAppCustomizedProcessor.h"

static inline NSString *build_key(NSString *app, NSString *mod) {
    return [[NSString alloc] initWithFormat:@"%@:%@", app, mod];;
}

@interface DIMAppCustomizedProcessor () {
    
    NSMutableDictionary<NSString *, id<DIMCustomizedContentHandler>> *_handlers;
}

@end

@implementation DIMAppCustomizedProcessor

- (instancetype)initWithFacebook:(DIMFacebook *)facebook
                       messenger:(DIMMessenger *)transceiver {
    if (self = [super initWithFacebook:facebook messenger:transceiver]) {
        _handlers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setContentHandler:(id<DIMCustomizedContentHandler>)handler
                forModule:(NSString *)mod
            inApplication:(NSString *)app {
    [_handlers setObject:handler forKey:build_key(app, mod)];
}

- (nullable id<DIMCustomizedContentHandler>)contentHandlerForModule:(NSString *)mod
                                                      inApplication:(NSString *)app {
    return [_handlers objectForKey:build_key(app, mod)];
}

// Override
- (id<DIMCustomizedContentHandler>)filterApplication:(NSString *)app
                                          withModule:(NSString *)mod
                                             content:(id<DKDCustomizedContent>)body
                                            messasge:(id<DKDReliableMessage>)rMsg {
    id<DIMCustomizedContentHandler> handler;
    handler = [self contentHandlerForModule:mod inApplication:app];
    if (handler) {
        return handler;
    }
    // default handler
    return [super filterForModule:mod inApplication:app content:body messasge:rMsg];
}

@end

@implementation DIMGroupHistoryHandler

// Override
- (NSArray<id<DKDContent>> *)handleAction:(NSString *)act
                                   sender:(id<MKMID>)uid
                                  content:(id<DKDCustomizedContent>)body
                                  message:(id<DKDReliableMessage>)rMsg {
    if ([body group] == nil) {
        NSAssert(false, @"group command error: %@, sender: %@", body, uid);
        NSString *text = @"Group command error.";
        return [self respondReceipt:text envelope:rMsg.envelope content:body extra:nil];
    } else if ([act isEqualToString:DIMGroupHistory_ActQuery]) {
        return [self transformQueryCommand:body message:rMsg];
    }
    NSAssert(false, @"unknown action: %@, %@, sender: %@", act, body, uid);
    return [super handleAction:act sender:uid content:body message:rMsg];
}

// private
- (NSArray<id<DKDContent>> *)transformQueryCommand:(id<DKDCustomizedContent>)body
                                           message:(id<DKDReliableMessage>)rMsg {
    DIMMessenger *transceiver = [self messenger];
    if (!transceiver) {
        NSAssert(false, @"messenger lost");
        return nil;
    }
    NSMutableDictionary *info = [body copyDictionary:NO];
    [info setObject:DKDContentType_Command forKey:@"type"];
    [info setObject:DKDGroupCommand_Query forKey:@"command"];
    id<DKDContent> query = DKDContentParse(info);
    if ([query conformsToProtocol:@protocol(DKDQueryGroupCommand)]) {
        return [transceiver processContent:query
                withReliableMessageMessage:rMsg];
    }
    NSAssert(false, @"query command error: %@, %@, sender: %@", query, body, rMsg.sender);
    NSString *text = @"Query command error.";
    return [self respondReceipt:text envelope:rMsg.envelope content:body extra:nil];
}

@end
```

### ContentProcessorCreator

```objective-c
#import <DIMSDK/DIMSDK.h>

#import "DIMAppCustomizedProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface DIMClientContentProcessorCreator : DIMContentProcessorCreator

@end

@interface DIMClientContentProcessorCreator (Customized)

// protected
- (DIMAppCustomizedProcessor *)createCustomizedProcessor:(DIMFacebook *)facebook
                                               messenger:(DIMMessenger *)transceiver;

@end
```

```objective-c
#import "DIMHandshakeCommandProcessor.h"

#import "DIMCreator.h"

#define CREATE_CPU(clazz)                                                      \
            [[clazz alloc] initWithFacebook:self.facebook                      \
                                  messenger:self.messenger]                    \
                                                   /* EOF 'CREATE_CPU(clazz)' */

@implementation DIMClientContentProcessorCreator

- (DIMAppCustomizedProcessor *)createCustomizedProcessor:(DIMFacebook *)facebook
                                               messenger:(DIMMessenger *)transceiver {

    DIMAppCustomizedProcessor *cpu = CREATE_CPU(DIMAppCustomizedProcessor);
    // 'chat.dim.group:history'
    [cpu setContentHandler:CREATE_CPU(DIMGroupHistoryHandler)
                 forModule:DIMGroupHistory_Mod
             inApplication:DIMGroupHistory_App];
    
    return cpu;
}

// Override
- (id<DIMContentProcessor>)createContentProcessor:(NSString *)type {
    // application customized
    if ([type isEqualToString:DKDContentType_Application] ||
        [type isEqualToString:DKDContentType_Customized]) {
        return [self createCustomizedProcessor:self.facebook messenger:self.messenger];
    }
    
    // ...
    
    // others
    return [super createContentProcessor:type];
}

// Override
- (id<DIMContentProcessor>)createCommandProcessor:(NSString *)name withType:(NSString *)msgType {
    // handshake
    if ([name isEqualToString:DKDCommand_Handshake]) {
        return CREATE_CPU(DIMHandshakeCommandProcessor);
    }
    
    // ...

    // others
    return [super createCommandProcessor:name withType:msgType];
}

@end
```

## Usage

To let your **DIMAppCustomizedProcessor** start to work,
you must override ```DIMContentProcessorCreator``` for message types:

1. DKDContentType_Application 
2. DKDContentType_Customized

and then set your **creator** for ```DIMContentProcessorFactory``` in the ```DIMMessageProcessor```.

----

Copyright &copy; 2018-2026 Albert Moky
[![Followers](https://img.shields.io/github/followers/moky)](https://github.com/moky?tab=followers)
