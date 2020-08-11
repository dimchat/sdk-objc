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
//  DIMMessenger.m
//  DIMClient
//
//  Created by Albert Moky on 2019/8/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"

#import "DIMFacebook.h"
#import "DIMKeyStore.h"

#import "DIMReceiptCommand.h"
#import "DIMHandshakeCommand.h"
#import "DIMLoginCommand.h"
#import "DIMMuteCommand.h"
#import "DIMBlockCommand.h"
#import "DIMStorageCommand.h"

#import "DIMContentProcessor.h"

#import "DIMMessenger.h"

@interface DIMMessenger () {
    
    NSMutableDictionary *_context;
    
    __weak id<DIMMessengerDelegate> _delegate;
    
    __weak DIMFacebook *_facebook;
    
    DIMContentProcessor *_cpu;
}

@end

static inline void load_cmd_classes(void) {
    // receipt
    [DIMCommand registerClass:[DIMReceiptCommand class]
                   forCommand:DIMCommand_Receipt];
    // handshake
    [DIMCommand registerClass:[DIMHandshakeCommand class]
                   forCommand:DIMCommand_Handshake];
    // login
    [DIMCommand registerClass:[DIMLoginCommand class]
                   forCommand:DIMCommand_Login];

    // mute
    [DIMCommand registerClass:[DIMMuteCommand class]
                   forCommand:DIMCommand_Mute];
    // block
    [DIMCommand registerClass:[DIMBlockCommand class]
                   forCommand:DIMCommand_Block];
    
    // storage (contacts, private_key)
    [DIMCommand registerClass:[DIMStorageCommand class]
                   forCommand:DIMCommand_Storage];
    [DIMCommand registerClass:[DIMStorageCommand class]
                   forCommand:DIMCommand_Contacts];
    [DIMCommand registerClass:[DIMStorageCommand class]
                   forCommand:DIMCommand_PrivateKey];
}

@implementation DIMMessenger

- (instancetype)init {
    if (self = [super init]) {
        
        // context
        _context = [[NSMutableDictionary alloc] init];
        
        _delegate = nil;
        
        _facebook = nil;
        
        _cpu = [[DIMContentProcessor alloc] initWithMessenger:self];
        
        // register new commands
        SingletonDispatchOnce(^{
            load_cmd_classes();
        });
    }
    return self;
}

- (NSDictionary *)context {
    return _context;
}

- (nullable id)valueForContextName:(NSString *)key {
    return [_context objectForKey:key];
}

- (void)setContextValue:(id)value forName:(NSString *)key {
    if (value) {
        [_context setObject:value forKey:key];
    } else {
        [_context removeObjectForKey:key];
    }
}

- (DIMFacebook *)facebook {
    if (!_facebook) {
        _facebook = [self valueForContextName:@"facebook"];
        if (!_facebook) {
            NSAssert([self.barrack isKindOfClass:[DIMFacebook class]], @"facebook error: %@", self.barrack);
            _facebook = (DIMFacebook *)self.barrack;
        }
    }
    return _facebook;
}

- (nullable DIMUser *)selectUserWithID:(DIMID *)receiver {
    DIMFacebook *facebook = self.facebook;
    NSArray<DIMUser *> *users = facebook.localUsers;
    if ([users count] == 0) {
        NSAssert(false, @"local users should not be empty");
        return nil;
    } else if ([receiver isBroadcast]) {
        // broadcast message can decrypt by anyone, so just return current user
        return [users firstObject];
    }
    if ([receiver isGroup]) {
        // group message (recipient not designated)
        for (DIMUser *item in users) {
            if ([facebook group:receiver hasMember:item.ID]) {
                //self.currentUser = item;
                return item;
            }
        }
    } else {
        // 1. personal message
        // 2. split group message
        NSAssert([receiver isUser], @"error: %@", receiver);
        for (DIMUser *item in users) {
            if ([receiver isEqual:item.ID]) {
                //self.currentUser = item;
                return item;
            }
        }
    }
    NSAssert(false, @"receiver not in local users: %@, %@", receiver, users);
    return nil;
}

- (nullable NSData *)processPackage:(NSData *)data {
    // 1. deserialize message
    DIMReliableMessage *rMsg = [self deserializeMessage:data];
    if (!rMsg) {
        // no message received
        return nil;
    }
    // 2. process message
    rMsg = [self processMessage:rMsg];
    if (!rMsg) {
        // nothing to response
        return nil;
    }
    // serialize message
    return [self serializeMessage:rMsg];
}

// TODO: override to check broadcast message before calling it
// TODO: override to deliver to the receiver when catch exception "ReceiverError"
- (nullable DIMReliableMessage *)processMessage:(DIMReliableMessage *)rMsg {
    // 1. verify message
    DIMSecureMessage *sMsg = [self verifyMessage:rMsg];
    if (!sMsg) {
        // waiting for sender's meta if not eixsts
        return nil;
    }
    // 2. process message
    sMsg = [self processSecure:sMsg message:rMsg];
    if (!sMsg) {
        // nothing to respond
        return nil;
    }
    // 3. sign message
    return [self signMessage:sMsg];
}

- (nullable DIMSecureMessage *)processSecure:(DIMSecureMessage *)sMsg message:(DIMReliableMessage *)rMsg {
    // 1. decrypt message
    DIMInstantMessage *iMsg = [self decryptMessage:sMsg];
    if (!iMsg) {
        // cannot decrypt this message, not for you?
        // delivering message to other receiver?
        return nil;
    }
    // 2. process message
    iMsg = [self processInstant:iMsg message:rMsg];
    if (!iMsg) {
        // nothing to respond
        return nil;
    }
    // 3. encrypt message
    return [self encryptMessage:iMsg];
}

- (nullable DIMInstantMessage *)processInstant:(DIMInstantMessage *)iMsg message:(DIMReliableMessage *)rMsg {
    // check message delegate
    if (!iMsg.delegate) {
        iMsg.delegate = self;
    }
    DIMEnvelope *env = iMsg.envelope;
    DIMContent *content = iMsg.content;
    DIMID *sender = env.sender;
    
    // process content from sender
    DIMContent *res = [self processContent:content sender:sender message:rMsg];
    if (![self saveMessage:iMsg]) {
        // error
        return nil;
    }
    if (!res) {
        // nothing to respond
        return nil;
    }
    
    // check receiver
    DIMID *receiver = env.receiver;
    DIMUser *user = [self selectUserWithID:receiver];
    NSAssert(user, @"receiver error: %@", receiver);
    
    // pack message
    return [[DIMInstantMessage alloc] initWithContent:res
                                               sender:user.ID
                                             receiver:sender
                                                 time:nil];
}

// TODO: override to check group
// TODO: override to filter the response
- (nullable DIMContent *)processContent:(DIMContent *)content
                                 sender:(DIMID *)sender
                                message:(DIMReliableMessage *)rMsg {
    // call CPU to process it
    return [_cpu processContent:content sender:sender message:rMsg];
}

- (BOOL)saveMessage:(DIMInstantMessage *)iMsg {
    NSAssert(false, @"override me!");
    return NO;
}

- (BOOL)suspendMessage:(DIMMessage *)msg {
    NSAssert(false, @"override me!");
    return NO;
}

@end

@implementation DIMMessenger (MessageDelegate)

#pragma mark DKDInstantMessageDelegate

- (nullable NSData *)message:(DIMInstantMessage *)iMsg
            serializeContent:(DIMContent *)content
                     withKey:(NSDictionary *)password {
    
    DIMSymmetricKey *key = MKMSymmetricKeyFromDictionary(password);
    NSAssert(key == password, @"irregular symmetric key: %@", password);
    
    // check attachment for File/Image/Audio/Video message content
    if ([content isKindOfClass:[DIMFileContent class]]) {
        DIMFileContent *file = (DIMFileContent *)content;
        NSAssert(file.fileData != nil, @"content.fileData should not be empty");
        NSAssert(file.URL == nil, @"content.URL exists, already uploaded?");
        // encrypt and upload file data onto CDN and save the URL in message content
        NSData *CT = [key encrypt:file.fileData];
        NSURL *url = [_delegate uploadData:CT forMessage:iMsg];
        if (url) {
            // replace 'data' with 'URL'
            file.URL = url;
            file.fileData = nil;
        }
        //[iMsg setObject:file forKey:@"content"];
    }
    
    return [super message:iMsg serializeContent:content withKey:key];
}

- (nullable NSData *)message:(DIMInstantMessage *)iMsg
                  encryptKey:(NSData *)data
                 forReceiver:(NSString *)receiver {
    DIMID *to = [self.facebook IDWithString:receiver];
    id<DIMEncryptKey> key = [self.facebook publicKeyForEncryption:to];
    if (!key) {
        DIMMeta *meta = [self.facebook metaForID:to];
        if (![meta.key conformsToProtocol:@protocol(MKMEncryptKey)]) {
            // save this message in a queue waiting receiver's meta response
            [self suspendMessage:iMsg];
            //NSAssert(false, @"failed to get encrypt key for receiver: %@", receiver);
            return nil;
        }
    }
    return [super message:iMsg encryptKey:data forReceiver:receiver];
}

#pragma mark DKDSecureMessageDelegate

- (nullable DIMContent *)message:(DIMSecureMessage *)sMsg
              deserializeContent:(NSData *)data
                         withKey:(NSDictionary *)password {
    DIMSymmetricKey *key = MKMSymmetricKeyFromDictionary(password);
    NSAssert(key == password, @"irregular symmetric key: %@", password);
    
    DIMContent *content = [super message:sMsg deserializeContent:data withKey:key];
    if (!content) {
        return nil;
    }
    
    // check attachment for File/Image/Audio/Video message content
    if ([content isKindOfClass:[DIMFileContent class]]) {
        DIMFileContent *file = (DIMFileContent *)content;
        NSAssert(file.URL != nil, @"content.URL should not be empty");
        NSAssert(file.fileData == nil, @"content.fileData already download");
        DIMInstantMessage *iMsg;
        iMsg = [[DIMInstantMessage alloc] initWithContent:content
                                                 envelope:sMsg.envelope];
        // download from CDN
        NSData *fileData = [_delegate downloadData:file.URL forMessage:iMsg];
        if (fileData) {
            // decrypt file data
            file.fileData = [key decrypt:fileData];
            file.URL = nil;
        } else {
            // save the symmetric key for decrypte file data later
            file.password = key;
        }
        //content = file;
    }
    
    return content;
}

@end

@implementation DIMMessenger (Transform)

- (nullable DIMSecureMessage *)trimMessage:(DIMSecureMessage *)sMsg {
    // check message delegate
    if (!sMsg.delegate) {
        sMsg.delegate = self;
    }
    DIMID *receiver = sMsg.envelope.receiver;
    DIMUser *user = [self selectUserWithID:receiver];
    if (!user) {
        // local users not matched
        sMsg = nil;
    } else if ([receiver isGroup]) {
        // trim group message
        sMsg = [sMsg trimForMember:user.ID];
    }
    return sMsg;
}

- (nullable DIMSecureMessage *)verifyMessage:(DIMReliableMessage *)rMsg {
    // check message delegate
    if (!rMsg.delegate) {
        rMsg.delegate = self;
    }
    // Notice: check meta before calling me
    DIMID *sender = rMsg.envelope.sender;
    DIMMeta *meta = MKMMetaFromDictionary(rMsg.meta);
    if (meta) {
        // [Meta Protocol]
        // save meta for sender
        if (![self.facebook saveMeta:meta forID:sender]) {
            NSAssert(false, @"save meta error: %@, %@", sender, meta);
            return nil;
        }
    } else {
        meta = [self.facebook metaForID:sender];
        if (!meta) {
            // NOTICE: the application will query meta automatically
            // save this message in a queue waiting sender's meta response
            [self suspendMessage:rMsg];
            //NSAssert(false, @"failed to get meta for sender: %@", sender);
            return nil;
        }
    }
    return [super verifyMessage:rMsg];
}

- (nullable DIMInstantMessage *)decryptMessage:(DIMSecureMessage *)sMsg {
    // trim message
    DIMSecureMessage *msg = [self trimMessage:sMsg];
    if (!msg) {
        // not for you?
        @throw [NSException exceptionWithName:@"ReceiverError" reason:@"not for you?" userInfo:sMsg];
    }
    // decrypt message
    return [super decryptMessage:msg];
}

@end
