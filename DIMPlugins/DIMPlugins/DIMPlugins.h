// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2023 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2023 Albert Moky
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
//  DIMPlugins.h
//  DIMPlugins
//
//  Created by Albert Moky on 2023/5/17.
//

#import <Foundation/Foundation.h>

//! Project version number for DIMPlugins.
FOUNDATION_EXPORT double DIMPluginsVersionNumber;

//! Project version string for DIMPlugins.
FOUNDATION_EXPORT const unsigned char DIMPluginsVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DIMPlugins/PublicHeader.h>

// MKM
//#import <MingKeMing/MingKeMing.h>

// DKD
//#import <DaoKeDao/DaoKeDao.h>

// Core
//#import <DIMCore/DIMCore.h>

#if !defined(__DIM_SDK__)
#define __DIM_SDK__ 1

// Crypto
#import <DIMPlugins/MKMAESKey.h>
#import <DIMPlugins/MKMSecKeyHelper.h>
#import <DIMPlugins/MKMECCPublicKey.h>
#import <DIMPlugins/MKMECCPrivateKey.h>
#import <DIMPlugins/MKMRSAPublicKey.h>
#import <DIMPlugins/MKMRSAPrivateKey.h>
#import <DIMPlugins/MKMPrivateKey+Store.h>

// Data
#import <DIMPlugins/DIMDataDigesters.h>
#import <DIMPlugins/DIMDataCoders.h>
#import <DIMPlugins/DIMDataParsers.h>
#import <DIMPlugins/DIMBaseDataFactory.h>
#import <DIMPlugins/DIMBaseFileFactory.h>

// MingKeMing
#import <DIMPlugins/DIMAddressFactory.h>
#import <DIMPlugins/DIMIDFactory.h>
#import <DIMPlugins/DIMMetaFactory.h>
#import <DIMPlugins/DIMDocumentFactory.h>
#import <DIMPlugins/MKMAddressBTC.h>
#import <DIMPlugins/MKMAddressETH.h>
#import <DIMPlugins/MKMMetaDefault.h>
#import <DIMPlugins/MKMMetaBTC.h>
#import <DIMPlugins/MKMMetaETH.h>

#import <DIMPlugins/MKMPlugins.h>

#endif /* ! __DIM_SDK__== */
