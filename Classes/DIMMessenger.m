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

- (BOOL)saveMessage:(id<DKDInstantMessage>)iMsg {
    NSAssert(false, @"override me!");
    return NO;
}

- (BOOL)suspendMessage:(id<DKDMessage>)msg {
    NSAssert(false, @"override me!");
    return NO;
}

@end

@implementation DIMMessenger (MessageDelegate)

#pragma mark DKDInstantMessageDelegate

- (nullable NSData *)message:(id<DKDInstantMessage>)iMsg
            serializeContent:(id<DKDContent>)content
                     withKey:(id<MKMSymmetricKey>)password {
    
    // check attachment for File/Image/Audio/Video message content
    if ([content isKindOfClass:[DIMFileContent class]]) {
        DIMFileContent *file = (DIMFileContent *)content;
        NSAssert(file.fileData != nil, @"content.fileData should not be empty");
        NSAssert(file.URL == nil, @"content.URL exists, already uploaded?");
        // encrypt and upload file data onto CDN and save the URL in message content
        NSData *CT = [password encrypt:file.fileData];
        NSURL *url = [_delegate uploadData:CT forMessage:iMsg];
        if (url) {
            // replace 'data' with 'URL'
            file.URL = url;
            file.fileData = nil;
        }
        //[iMsg setObject:file forKey:@"content"];
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
        id<MKMMeta> meta = [self.facebook metaForID:receiver];
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

- (nullable id<DKDContent>)message:(id<DKDSecureMessage>)sMsg
              deserializeContent:(NSData *)data
                         withKey:(id<MKMSymmetricKey>)password {
    
    id<DKDContent>content = [super message:sMsg deserializeContent:data withKey:password];
    if (!content) {
        return nil;
    }
    
    // check attachment for File/Image/Audio/Video message content
    if ([content isKindOfClass:[DIMFileContent class]]) {
        DIMFileContent *file = (DIMFileContent *)content;
        NSAssert(file.URL != nil, @"content.URL should not be empty");
        NSAssert(file.fileData == nil, @"content.fileData already download");
        id<DKDInstantMessage> iMsg = DKDInstantMessageCreate(sMsg.envelope, content);
        // download from CDN
        NSData *fileData = [_delegate downloadData:file.URL forMessage:iMsg];
        if (fileData) {
            // decrypt file data
            file.fileData = [password decrypt:fileData];
            file.URL = nil;
        } else {
            // save the symmetric key for decrypte file data later
            file.password = password;
        }
        //content = file;
    }
    
    return content;
}

@end
