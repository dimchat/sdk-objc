// license: https://mit-license.org
//
//  Ming-Ke-Ming : Decentralized User Identity Authentication
//
//                               Written in 2020 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2020 Albert Moky
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
//  MKMECCHelper.m
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/15.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import "MKMECCHelper.h"

static inline NSString *ECCKeyContentFromNSString(NSString *content,
                                                  NSString *tag) {
    NSString *sTag, *eTag;
    NSRange spos, epos;
    NSString *key = content;
    
    sTag = [NSString stringWithFormat:@"-----BEGIN ECC %@ KEY-----", tag];
    eTag = [NSString stringWithFormat:@"-----END ECC %@ KEY-----", tag];
    spos = [key rangeOfString:sTag];
    if (spos.length > 0) {
        epos = [key rangeOfString:eTag];
    } else {
        sTag = [NSString stringWithFormat:@"-----BEGIN %@ KEY-----", tag];
        eTag = [NSString stringWithFormat:@"-----END %@ KEY-----", tag];
        spos = [key rangeOfString:sTag];
        epos = [key rangeOfString:eTag];
    }
    
    if (spos.location != NSNotFound && epos.location != NSNotFound) {
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e - s);
        key = [key substringWithRange:range];
    }
    
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    return key;
}

NSString *ECCPublicKeyContentFromNSString(NSString *content) {
    return ECCKeyContentFromNSString(content, @"PUBLIC");
}

NSString *ECCPrivateKeyContentFromNSString(NSString *content) {
    return ECCKeyContentFromNSString(content, @"PRIVATE");
}

NSString *NSStringFromECCPublicKeyContent(NSString *content) {
    NSMutableString *mString = [[NSMutableString alloc] init];
    [mString appendString:@"-----BEGIN PUBLIC KEY-----\n"];
    NSUInteger pos1, pos2, len = content.length;
    NSString *substr;
    for (pos1 = 0, pos2 = 64; pos1 < len; pos1 = pos2, pos2 += 64) {
        if (pos2 > len) {
            pos2 = len;
        }
        substr = [content substringWithRange:NSMakeRange(pos1, pos2 - pos1)];
        [mString appendString:substr];
        [mString appendString:@"\n"];
    }
    [mString appendString:@"-----END PUBLIC KEY-----\n"];
    return mString;
}

NSString *NSStringFromECCPrivateKeyContent(NSString *content) {
    NSMutableString *mString = [[NSMutableString alloc] init];
    [mString appendString:@"-----BEGIN EC PRIVATE KEY-----\n"];
    NSUInteger pos1, pos2, len = content.length;
    NSString *substr;
    for (pos1 = 0, pos2 = 64; pos1 < len; pos1 = pos2, pos2 += 64) {
        if (pos2 > len) {
            pos2 = len;
        }
        substr = [content substringWithRange:NSMakeRange(pos1, pos2 - pos1)];
        [mString appendString:substr];
        [mString appendString:@"\n"];
    }
    [mString appendString:@"-----END EC PRIVATE KEY-----\n"];
    return mString;
}
