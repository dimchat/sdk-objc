// license: https://mit-license.org
//
//  Ming-Ke-Ming : Decentralized User Identity Authentication
//
//                               Written in 2022 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2022 Albert Moky
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
//  MKMPlugins+Crypto.m
//  DIMPlugins
//
//  Created by Albert Moky on 2020/12/12.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "MKMAddressBTC.h"

#import "MKMPlugins.h"

@interface MKMEntityID : MKMID

@end

@implementation MKMEntityID

- (MKMEntityType)type {
    MKMNetworkID network = [self.address type];
    // compatible with MKM 0.9.*
    return MKMEntityTypeFromNetworkID(network);
}

@end

@interface MKMEntityIDFactory : DIMIDFactory

@end

@implementation MKMEntityIDFactory

// Override
- (id<MKMID>)newID:(NSString *)identifier name:(nullable NSString *)seed address:(id<MKMAddress>)main terminal:(nullable NSString *)loc {
    // override for customized ID
    return [[MKMEntityID alloc] initWithString:identifier name:seed address:main terminal:loc];
}

// Override
- (nullable id<MKMID>)parse:(NSString *)identifier {
    NSUInteger len = [identifier length];
    if (len == 15) {
        // "anyone@anywhere"
        NSString *lower = [identifier lowercaseString];
        if ([MKMAnyone() isEqual:lower]) {
            return MKMAnyone();
        }
    } else if (len == 19) {
        // "everyone@everywhere"
        // "stations@everywhere"
        NSString *lower = [identifier lowercaseString];
        if ([MKMEveryone() isEqual:lower]) {
            return MKMEveryone();
        }
    } else if (len == 13) {
        // "moky@anywhere"
        NSString *lower = [identifier lowercaseString];
        if ([MKMFounder() isEqual:lower]) {
            return MKMFounder();
        }
    }
    return [super parse:identifier];
}

@end

@implementation MKMPlugins (EntityID)

+ (void)registerIDFactory {
    MKMEntityIDFactory *factory = [[MKMEntityIDFactory alloc] init];
    MKMIDSetFactory(factory);
}

@end
