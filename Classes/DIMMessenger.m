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
//  DIMSDK
//
//  Created by Albert Moky on 2019/8/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMMessenger.h"

@implementation DIMMessenger

- (id<DIMCipherKeyDelegate>)keyCache {
    NSAssert(false, @"implement me!");
    return nil;
}

- (id<DIMPacker>)packer {
    NSAssert(false, @"implement me!");
    return nil;
}

- (id<DIMProcessor>)processor {
    NSAssert(false, @"implement me!");
    return nil;
}

#pragma mark SecureMessageDelegate

// Override
- (id<MKSymmetricKey>)message:(id<DKDSecureMessage>)sMsg
               deserializeKey:(NSData *)data {
    if ([data length] == 0) {
        // get key from cache with direction: sender -> receiver(group)
        return [self decryptKeyForMessage:sMsg];
    }
    id<MKSymmetricKey> password = [super message:sMsg deserializeKey:data];
    // cache decrypt key when success
    if (password) {
        // cache the key with direction: sender -> receiver(group)
        [self cacheDecryptKey:password forMessage:sMsg];
    }
    return password;
}

//
//  Interfaces for Packing Message
//

// Override
- (id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg {
    id<DIMPacker> packer = [self packer];
    return [packer encryptMessage:iMsg];
}

// Override
- (id<DKDReliableMessage>)signMessage:(id<DKDSecureMessage>)sMsg {
    id<DIMPacker> packer = [self packer];
    return [packer signMessage:sMsg];
}

//// Override
//- (NSData *)serializeMessage:(id<DKDReliableMessage>)rMsg {
//    id<DIMPacker> packer = [self packer];
//    return [packer serializeMessage:rMsg];
//}
//
//// Override
//- (id<DKDReliableMessage>)deserializeMessage:(NSData *)data {
//    id<DIMPacker> packer = [self packer];
//    return [packer deserializeMessage:data];
//}

// Override
- (id<DKDSecureMessage>)verifyMessage:(id<DKDReliableMessage>)rMsg {
    id<DIMPacker> packer = [self packer];
    return [packer verifyMessage:rMsg];
}

// Override
- (id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg {
    id<DIMPacker> packer = [self packer];
    return [packer decryptMessage:sMsg];
}

//
//  Interfaces for Processing Message
//

// Override
- (NSArray<NSData *> *)processPackage:(NSData *)data {
    id<DIMProcessor> processor = [self processor];
    return [processor processPackage:data];
}

// Override
- (NSArray<id<DKDReliableMessage>> *)processReliableMessage:(id<DKDReliableMessage>)rMsg {
    id<DIMProcessor> processor = [self processor];
    return [processor processReliableMessage:rMsg];
}

// Override
- (NSArray<id<DKDSecureMessage>> *)processSecureMessage:(id<DKDSecureMessage>)sMsg
                             withReliableMessageMessage:(id<DKDReliableMessage>)rMsg {
    id<DIMProcessor> processor = [self processor];
    return [processor processSecureMessage:sMsg withReliableMessageMessage:rMsg];
}

// Override
- (NSArray<id<DKDInstantMessage>> *)processInstantMessage:(id<DKDInstantMessage>)iMsg
                               withReliableMessageMessage:(id<DKDReliableMessage>)rMsg {
    id<DIMProcessor> processor = [self processor];
    return [processor processInstantMessage:iMsg withReliableMessageMessage:rMsg];
}

// Override
- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                 withReliableMessageMessage:(id<DKDReliableMessage>)rMsg {
    id<DIMProcessor> processor = [self processor];
    return [processor processContent:content withReliableMessageMessage:rMsg];
}

@end

@implementation DIMMessenger (CipherKey)

//
//  Interfaces for Cipher Key
//

- (nullable id<MKSymmetricKey>)encryptKeyForMessage:(id<DKDInstantMessage>)iMsg {
    id<MKMID> sender = [iMsg sender];
    id<MKMID> target = [DIMCipherKeyDelegate destinationOfMessage:iMsg];
    id<DIMCipherKeyDelegate> db = [self keyCache];
    return [db cipherKeyWithSender:sender receiver:target generate:YES];
}

- (nullable id<MKSymmetricKey>)decryptKeyForMessage:(id<DKDSecureMessage>)sMsg {
    id<MKMID> sender = [sMsg sender];
    id<MKMID> target = [DIMCipherKeyDelegate destinationOfMessage:sMsg];
    id<DIMCipherKeyDelegate> db = [self keyCache];
    return [db cipherKeyWithSender:sender receiver:target generate:NO];
}

- (void)cacheDecryptKey:(id<MKSymmetricKey>)password
             forMessage:(id<DKDSecureMessage>)sMsg {
    id<MKMID> sender = [sMsg sender];
    id<MKMID> target = [DIMCipherKeyDelegate destinationOfMessage:sMsg];
    id<DIMCipherKeyDelegate> db = [self keyCache];
    [db cacheCipherKey:password withSender:sender receiver:target];
}

@end
