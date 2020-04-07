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
//  MKMImmortals.m
//  MingKeMing
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"

#import "MKMImmortals.h"

@interface MKMUser (Hacking)

@property (strong, nonatomic) MKMPrivateKey *privateKey;

@end

@interface MKMImmortals () {
    
    NSMutableDictionary<NSString *, MKMID *>      *_idTable;
    NSMutableDictionary<MKMID *, MKMPrivateKey *> *_privateTable;
    NSMutableDictionary<MKMID *, MKMMeta *>       *_metaTable;
    NSMutableDictionary<MKMID *, MKMProfile *>    *_profileTable;
    NSMutableDictionary<MKMID *, MKMUser *>       *_userTable;
}

@end

@implementation MKMImmortals

- (instancetype)init {
    if (self = [super init]) {
        _idTable      = [[NSMutableDictionary alloc] initWithCapacity:2];
        _privateTable = [[NSMutableDictionary alloc] initWithCapacity:2];
        _metaTable    = [[NSMutableDictionary alloc] initWithCapacity:2];
        _profileTable = [[NSMutableDictionary alloc] initWithCapacity:2];
        _userTable    = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        [self _loadBuiltInAccount:MKMIDFromString(MKM_IMMORTAL_HULK_ID)];
        [self _loadBuiltInAccount:MKMIDFromString(MKM_MONKEY_KING_ID)];
    }
    return self;
}

- (void)_loadBuiltInAccount:(MKMID *)ID {
    NSAssert([ID isValid], @"ID error: %@", ID);
    [_idTable setObject:ID forKey:ID];
    NSString *filename;
    
    // load meta for ID
    filename = [ID.name stringByAppendingString:@"_meta"];
    MKMMeta * meta = [self _loadMeta:filename];
    [self cacheMeta:meta forID:ID];
    
    // load private key for ID
    filename = [ID.name stringByAppendingString:@"_secret"];
    MKMPrivateKey *key = [self _loadPrivateKey:filename];
    [self cachePrivateKey:key forID:ID];
    
    // load profile for ID
    filename = [ID.name stringByAppendingString:@"_profile"];
    MKMProfile *profile = [self _loadProfile:filename];
    [self cacheProfile:profile forID:ID];
}

- (nullable NSDictionary *)_loadJSONFile:(NSString *)filename {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];//[NSBundle mainBundle];
    NSString *path = [bundle pathForResource:filename ofType:@"js"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        NSAssert(false, @"file not exists: %@", path);
        return nil;
    }
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSAssert(data.length > 0, @"failed to load JSON file: %@", path);
    return [data jsonDictionary];
}

- (nullable MKMMeta *)_loadMeta:(NSString *)filename {
    NSDictionary *dict = [self _loadJSONFile:filename];
    NSAssert(dict, @"failed to load meta file: %@", filename);
    return MKMMetaFromDictionary(dict);
}

- (nullable MKMPrivateKey *)_loadPrivateKey:(NSString *)filename {
    NSDictionary *dict = [self _loadJSONFile:filename];
    NSAssert(dict, @"failed to load secret file: %@", filename);
    return MKMPrivateKeyFromDictionary(dict);
}

- (nullable MKMProfile *)_loadProfile:(NSString *)filename {
    NSDictionary *dict = [self _loadJSONFile:filename];
    NSAssert(dict, @"failed to load profile: %@", filename);
    MKMProfile *profile = MKMProfileFromDictionary(dict);
    NSAssert(profile, @"profile error: %@", dict);
    // copy 'name'
    NSString *name = [dict objectForKey:@"name"];
    if (name) {
        [profile setProperty:name forKey:@"name"];
    } else {
        NSArray<NSString *> *array = [dict objectForKey:@"names"];
        if (array.count > 0) {
            [profile setProperty:array.firstObject forKey:@"name"];
        }
    }
    // copy 'avarar'
    NSString *avarar = [dict objectForKey:@"avarar"];
    if (avarar) {
        [profile setProperty:avarar forKey:@"avarar"];
    } else {
        NSArray<NSString *> *array = [dict objectForKey:@"photos"];
        if (array.count > 0) {
            [profile setProperty:array.firstObject forKey:@"avarar"];
        }
    }
    // sign
    [self _signProfile:profile];
    return profile;
}

- (nullable NSData *)_signProfile:(MKMProfile *)profile {
    MKMID *ID = [self IDWithString:profile.ID];
    id<MKMSignKey> key = [self privateKeyForSignature:ID];
    NSAssert(key, @"failed to get private key for signature: %@", ID);
    return [profile sign:key];
}

#pragma mark Cache

- (BOOL)cacheID:(MKMID *)ID {
    NSAssert([ID isValid], @"ID not valid: %@", ID);
    [_idTable setObject:ID forKey:ID];
    return YES;
}

- (BOOL)cacheMeta:(MKMMeta *)meta forID:(MKMID *)ID {
    NSAssert([meta matchID:ID], @"meta not match: %@, %@", ID, meta);
    [_metaTable setObject:meta forKey:ID];
    return YES;
}

- (BOOL)cachePrivateKey:(MKMPrivateKey *)SK forID:(MKMID *)ID {
    NSAssert([(MKMPublicKey *)[self metaForID:ID].key isMatch:SK], @"SK error: %@, %@", ID, SK);
    [_privateTable setObject:SK forKey:ID];
    return YES;
}

- (BOOL)cacheProfile:(MKMProfile *)profile forID:(MKMID *)ID {
    NSAssert([profile isValid], @"profile not valid: %@", profile);
    NSAssert([ID isEqual:profile.ID], @"profile not match: %@, %@", ID, profile);
    [_profileTable setObject:profile forKey:ID];
    return YES;
}

- (BOOL)cacheUser:(MKMUser *)user {
    if (user.dataSource == nil) {
        user.dataSource = self;
    }
    [_userTable setObject:user forKey:user.ID];
    return YES;
}

#pragma mark -

- (nullable MKMID *)IDWithString:(NSString *)string {
    if (!string) {
        return nil;
    } else if ([string isKindOfClass:[MKMID class]]) {
        return (MKMID *)string;
    }
    NSAssert([string isKindOfClass:[NSString class]], @"ID string error: %@", string);
    return [_idTable objectForKey:string];
}

- (nullable MKMUser *)userWithID:(MKMID *)ID {
    NSAssert([ID isUser], @"user ID error: %@", ID);
    MKMUser *user = [_userTable objectForKey:ID];
    if (!user) {
        if ([_idTable objectForKey:ID]) {
            user = [[MKMUser alloc] initWithID:ID];
            [self cacheUser:user];
        }
    }
    return user;
}

#pragma mark - Delegates

- (nullable MKMMeta *)metaForID:(MKMID *)ID {
    return [_metaTable objectForKey:ID];
}

- (nullable __kindof MKMProfile *)profileForID:(MKMID *)ID {
    return [_profileTable objectForKey:ID];
}

- (nullable NSArray<MKMID *> *)contactsOfUser:(MKMID *)user {
    NSAssert([user isUser], @"user ID error: %@", user);
    if (![_idTable objectForKey:user]) {
        return nil;
    }
    NSArray *list = [_idTable allValues];
    NSMutableArray *mArray = [list mutableCopy];
    [mArray removeObject:user];
    return mArray;
}

- (nullable id<MKMEncryptKey>)publicKeyForEncryption:(nonnull MKMID *)user {
    NSAssert([user isUser], @"user ID error: %@", user);
    // NOTICE: return nothing to use profile.key or meta.key
    return nil;
}

- (nullable NSArray<id<MKMDecryptKey>> *)privateKeysForDecryption:(MKMID *)user {
    NSAssert([user isUser], @"user ID error: %@", user);
    MKMPrivateKey *key = [_privateTable objectForKey:user];
    if ([key conformsToProtocol:@protocol(MKMDecryptKey)]) {
        return @[(id<MKMDecryptKey>)key];
    }
    return nil;
}

- (nullable id<MKMSignKey>)privateKeyForSignature:(MKMID *)user {
    NSAssert([user isUser], @"user ID error: %@", user);
    return [_privateTable objectForKey:user];
}

- (nullable NSArray<id<MKMVerifyKey>> *)publicKeysForVerification:(nonnull MKMID *)user {
    NSAssert([user isUser], @"user ID error: %@", user);
    // NOTICE: return nothing to use meta.key
    return nil;
}

@end
