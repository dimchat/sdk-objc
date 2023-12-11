// license: https://mit-license.org
//
//  Ming-Ke-Ming : Decentralized User Identity Authentication
//
//                               Written in 2018 by Moky <albert.moky@gmail.com>
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
//  MKMRSAPrivateKey+Store.m
//  MingKeMing
//
//  Created by Albert Moky on 2018/11/25.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "MKMSecKeyHelper.h"

#import "MKMRSAPrivateKey.h"

@interface MKMRSAPrivateKey (Hacking)

@property (nonatomic) SecKeyRef privateKeyRef;

@end

@implementation MKMRSAPrivateKey (PersistentStore)

static NSString *s_application_tag = @"chat.dim.rsa.private";

+ (nullable instancetype)loadKeyWithIdentifier:(NSString *)identifier {
    MKMRSAPrivateKey *SK = nil;
    
    NSString *label = identifier;
    NSData *tag = MKMUTF8Encode(s_application_tag);
    
    NSDictionary *query;
    query = @{(id)kSecClass               :(id)kSecClassKey,
              (id)kSecAttrApplicationLabel:label,
              (id)kSecAttrApplicationTag  :tag,
              (id)kSecAttrKeyType         :(id)kSecAttrKeyTypeRSA,
              (id)kSecAttrKeyClass        :(id)kSecAttrKeyClassPrivate,
              (id)kSecAttrSynchronizable  :(id)kCFBooleanTrue,
              
              (id)kSecMatchLimit          :(id)kSecMatchLimitOne,
              (id)kSecReturnRef           :(id)kCFBooleanTrue,

              // FIXME: 'Status = -25308'
              (id)kSecAttrAccessible      :(id)kSecAttrAccessibleWhenUnlocked,
              };
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, &result);
    if (status == errSecSuccess) { // noErr
        // private key
        SecKeyRef privateKeyRef = (SecKeyRef)result;
        NSString *skc = [MKMSecKeyHelper serializePrivateKey:privateKeyRef algorithm:MKMAlgorithm_RSA];
        // public key
        SecKeyRef publicKeyRef = SecKeyCopyPublicKey(privateKeyRef);
        NSString *pkc = [MKMSecKeyHelper serializePublicKey:publicKeyRef algorithm:MKMAlgorithm_RSA];
        // key content
        NSString *content = [NSString stringWithFormat:@"%@%@", pkc, skc];
        NSString *algorithm = MKMAlgorithm_RSA;
        NSDictionary *keyInfo = @{@"algorithm":algorithm,
                                  @"data"     :content,
                                  };
        SK = [[MKMRSAPrivateKey alloc] initWithDictionary:keyInfo];
    } else {
        // sec key item not found
        NSAssert(status == errSecItemNotFound, @"RSA item status error: %d", status);
    }
    if (result) {
        CFRelease(result);
        result = NULL;
    }
    
    return SK;
}

- (BOOL)saveKeyWithIdentifier:(NSString *)identifier {
    if (!self.privateKeyRef) {
        NSAssert(false, @"RSA privateKeyRef cannot be empty");
        return NO;
    }
    
    NSString *label = identifier;
    NSData *tag = MKMUTF8Encode(s_application_tag);
    
    NSDictionary *query;
    query = @{(id)kSecClass               :(id)kSecClassKey,
              (id)kSecAttrApplicationLabel:label,
              (id)kSecAttrApplicationTag  :tag,
              (id)kSecAttrKeyType         :(id)kSecAttrKeyTypeRSA,
              (id)kSecAttrKeyClass        :(id)kSecAttrKeyClassPrivate,
              (id)kSecAttrSynchronizable  :(id)kCFBooleanTrue,
              
              (id)kSecMatchLimit          :(id)kSecMatchLimitOne,
              (id)kSecReturnRef           :(id)kCFBooleanTrue,

              // FIXME: 'Status = -25308'
              (id)kSecAttrAccessible      :(id)kSecAttrAccessibleWhenUnlocked,
              };
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, &result);
    if (status == errSecSuccess) { // noErr
        // already exists, delete it firest
        NSMutableDictionary *mQuery = [query mutableCopy];
        [mQuery removeObjectForKey:(id)kSecMatchLimit];
        [mQuery removeObjectForKey:(id)kSecReturnRef];
        
        status = SecItemDelete((CFDictionaryRef)mQuery);
        if (status != errSecSuccess) {
            NSAssert(false, @"RSA failed to erase key: %@", mQuery);
        }
    } else {
        // sec key item not found
        NSAssert(status == errSecItemNotFound, @"RSA item status error: %d", status);
    }
    if (result) {
        CFRelease(result);
        result = NULL;
    }
    
    // add key item
    NSMutableDictionary *attributes = [query mutableCopy];
    [attributes removeObjectForKey:(id)kSecMatchLimit];
    [attributes removeObjectForKey:(id)kSecReturnRef];
    //[attributes setObject:(__bridge id)self.privateKeyRef forKey:(id)kSecValueRef];
    [attributes setObject:self.data forKey:(id)kSecValueData];
    
    status = SecItemAdd((CFDictionaryRef)attributes, &result);
    if (result) {
        CFRelease(result);
        result = NULL;
    }
    if (status == errSecSuccess) {
        return YES;
    } else {
        NSAssert(false, @"RSA failed to update key");
        return NO;
    }
}

@end
