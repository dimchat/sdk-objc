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

#import "DKDInstantMessage+Extension.h"
#import "DIMFacebook.h"

#import "DIMReceiptCommand.h"
#import "DIMHandshakeCommand.h"
#import "DIMLoginCommand.h"
#import "DIMMuteCommand.h"
#import "DIMBlockCommand.h"
#import "DIMStorageCommand.h"

#import "DIMContentProcessor.h"
#import "DIMFileContentProcessor.h"
#import "DIMMessageProcessor.h"

#import "DIMMessenger.h"

@interface DIMMessenger () {
    
    NSMutableDictionary *_context;
    
    __weak id<DIMMessengerDelegate> _delegate;
    
    __weak DIMFacebook *_facebook;
    
    DIMContentProcessor *_cpu;
}

@end

static inline void load_cmd_classes(void) {
//    // receipt
//    [DIMCommand registerClass:[DIMReceiptCommand class]
//                   forCommand:DIMCommand_Receipt];
//    // handshake
//    [DIMCommand registerClass:[DIMHandshakeCommand class]
//                   forCommand:DIMCommand_Handshake];
//    // login
//    [DIMCommand registerClass:[DIMLoginCommand class]
//                   forCommand:DIMCommand_Login];
//
//    // mute
//    [DIMCommand registerClass:[DIMMuteCommand class]
//                   forCommand:DIMCommand_Mute];
//    // block
//    [DIMCommand registerClass:[DIMBlockCommand class]
//                   forCommand:DIMCommand_Block];
//
//    // storage (contacts, private_key)
//    [DIMCommand registerClass:[DIMStorageCommand class]
//                   forCommand:DIMCommand_Storage];
//    [DIMCommand registerClass:[DIMStorageCommand class]
//                   forCommand:DIMCommand_Contacts];
//    [DIMCommand registerClass:[DIMStorageCommand class]
//                   forCommand:DIMCommand_PrivateKey];
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

- (DIMFacebook *)facebook {
    if (!_facebook) {
        NSAssert([self.barrack isKindOfClass:[DIMFacebook class]], @"facebook error: %@", self.barrack);
        _facebook = (DIMFacebook *)self.barrack;
    }
    return _facebook;
}

- (DIMFileContentProcessor *)fileContentProcessor {
    DIMContentProcessor *cpu = [self.processor getContentProcessorForType:DKDContentType_File];
    return (DIMFileContentProcessor *)cpu;
}

#pragma mark DKDInstantMessageDelegate

- (nullable NSData *)message:(id<DKDInstantMessage>)iMsg
            serializeContent:(id<DKDContent>)content
                     withKey:(id<MKMSymmetricKey>)password {
    // check attachment for File/Image/Audio/Video message content
    if ([content isKindOfClass:[DIMFileContent class]]) {
        DIMFileContentProcessor *fpu = [self fileContentProcessor];
        [fpu uploadFileContent:(id<DIMFileContent>)content
                           key:password
                       message:iMsg];
    }
    return [super message:iMsg serializeContent:content withKey:password];
}

- (nullable id<MKMEncryptKey>)publicKeyForEncryption:(id<MKMID>)receiver {
    id doc = [self.facebook documentForID:receiver withType:MKMDocument_Visa];
    if ([doc conformsToProtocol:@protocol(MKMVisa)]) {
        id<MKMEncryptKey> key = [(id<MKMVisa>)doc key];
        if (key) {
            return key;
        }
    }
    id<MKMMeta> meta = [self.facebook metaForID:receiver];
    id key = [meta key];
    if ([key conformsToProtocol:@protocol(MKMEncryptKey)]) {
        return key;
    }
    return nil;
}

- (nullable NSData *)message:(id<DKDInstantMessage>)iMsg
                  encryptKey:(NSData *)data
                 forReceiver:(id<MKMID>)receiver {
    id<MKMEncryptKey> key = [self publicKeyForEncryption:receiver];
    if (!key) {
        // save this message in a queue waiting receiver's meta response
        [self suspendMessage:iMsg];
        //NSAssert(false, @"failed to get encrypt key for receiver: %@", receiver);
        return nil;
    }
    return [super message:iMsg encryptKey:data forReceiver:receiver];
}

#pragma mark DKDSecureMessageDelegate

- (nullable id<DKDContent>)message:(id<DKDSecureMessage>)sMsg
              deserializeContent:(NSData *)data
                         withKey:(id<MKMSymmetricKey>)password {
    id<DKDContent>content = [super message:sMsg deserializeContent:data withKey:password];
    NSAssert(content, @"failed to deserialize message content: %@", sMsg);
    // check attachment for File/Image/Audio/Video message content
    if ([content isKindOfClass:[DIMFileContent class]]) {
        DIMFileContentProcessor *fpu = [self fileContentProcessor];
        [fpu downloadFileContent:(id<DIMFileContent>)content
                             key:password
                         message:sMsg];
    }
    return content;
}

@end

@implementation DIMMessenger (Send)

- (BOOL)sendContent:(id<DKDContent>)content
           receiver:(id<MKMID>)receiver
           callback:(nullable DIMMessengerCallback)callback {
    
    // Application Layer should make sure user is already login before it send message to server.
    // Application layer should put message into queue so that it will send automatically after user login
    MKMUser *user = self.facebook.currentUser;
    NSAssert(user, @"current user not found");
    /*
    if ([receiver isGroup]) {
        if (content.group) {
            NSAssert([receiver isEqual:content.group], @"group ID not match: %@, %@", receiver, content);
        } else {
            content.group = receiver;
        }
    }
     */
    id<DKDEnvelope> env = DKDEnvelopeCreate(user.ID, receiver, nil);
    id<DKDInstantMessage> iMsg = DKDInstantMessageCreate(env, content);
    return [self sendInstantMessage:iMsg
                           callback:callback];
}

- (BOOL)sendInstantMessage:(id<DKDInstantMessage>)iMsg
                  callback:(nullable DIMMessengerCallback)callback {
    
    // Send message (secured + certified) to target station
    id<DKDSecureMessage> sMsg = [self.processor encryptMessage:iMsg];
    if (!sMsg) {
        // public key not found?
        NSAssert(false, @"failed to encrypt message: %@", iMsg);
        return NO;
    }
    id<DKDReliableMessage> rMsg = [self.processor signMessage:sMsg];
    if (!rMsg) {
        NSAssert(false, @"failed to sign message: %@", sMsg);
        DKDContent *content = iMsg.content;
        content.state = DIMMessageState_Error;
        content.error = @"Encryption failed.";
        return NO;
    }
    
    BOOL OK = [self sendReliableMessage:rMsg callback:callback];
    // sending status
    if (OK) {
        DKDContent *content = iMsg.content;
        content.state = DIMMessageState_Sending;
    } else {
        NSLog(@"cannot send message now, put in waiting queue: %@", iMsg);
        DKDContent *content = iMsg.content;
        content.state = DIMMessageState_Waiting;
    }
    
    if (![self saveMessage:iMsg]) {
        return NO;
    }
    return OK;
}

- (BOOL)sendReliableMessage:(id<DKDReliableMessage>)rMsg
                   callback:(nullable DIMMessengerCallback)callback {
    
    NSData *data = [self.processor serializeMessage:rMsg];
    NSAssert(self.delegate, @"transceiver delegate not set");
    return [self.delegate sendPackage:data
                    completionHandler:^(NSError * _Nullable error) {
                        !callback ?: callback(rMsg, error);
                    }];
}

@end

@implementation DIMMessenger (Process)

- (NSData *)processData:(NSData *)data {
    return [self.processor processData:data];
}

@end

@implementation DIMMessenger (Storage)

- (BOOL)saveMessage:(id<DKDInstantMessage>)iMsg {
    NSAssert(false, @"implement me!");
    return NO;
}

- (BOOL)suspendMessage:(id<DKDMessage>)msg {
    NSAssert(false, @"implement me!");
    return NO;
}

@end
