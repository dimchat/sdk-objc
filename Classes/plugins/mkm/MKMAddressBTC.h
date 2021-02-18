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
//  MKMAddressBTC.h
//  DIMSDK
//
//  Created by Albert Moky on 2020/12/12.
//  Copyright © 2020 Albert Moky. All rights reserved.
//

#import <MingKeMing/MingKeMing.h>

NS_ASSUME_NONNULL_BEGIN

/*
 *  Address like BitCoin
 *
 *      data format: "network+digest+code"
 *          network    --  1 byte
 *          digest     -- 20 bytes
 *          code       --  4 bytes
 *
 *      algorithm:
 *          fingerprint = sign(seed, SK);  // public key data
 *          digest      = ripemd160(sha256(fingerprint));
 *          code        = sha256(sha256(network + digest)).prefix(4);
 *          address     = base58_encode(network + digest + code);
 */
@interface MKMAddressBTC : MKMAddress

/**
 *  Generate address with fingerprint and network ID
 *
 * @param fingerprint = meta.fingerprint or key.data
 * @param type - address type
 * @return Address object
 */
+ (instancetype)generate:(NSData *)fingerprint network:(UInt8)type;

/**
 *  Parse a string for BTC address
 *
 * @param string - address string
 * @return null on error
 */
+ (instancetype)parse:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
