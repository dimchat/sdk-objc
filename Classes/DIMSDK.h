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
//  DIMSDK.h
//  DIMSDK
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 Albert Moky. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for DIMSDK.
FOUNDATION_EXPORT double DIMSDKVersionNumber;

//! Project version string for DIMSDK.
FOUNDATION_EXPORT const unsigned char DIMSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DIMSDK/PublicHeader.h>

// MKM
//#import <MingKeMing/MingKeMing.h>

// DKD
//#import <DaoKeDao/DaoKeDao.h>

// Core
//#import <DIMCore/DIMCore.h>

#if !defined(__DIM_SDK__)
#define __DIM_SDK__ 1

// Extensions
#import <DIMSDK/DKDInstantMessage+Extension.h>

// CA
#import <DIMSDK/DIMCASubject.h>
#import <DIMSDK/DIMCAValidity.h>
#import <DIMSDK/DIMCAData.h>
#import <DIMSDK/DIMCertificateAuthority.h>

// Network
#import <DIMSDK/DIMServiceProvider.h>
#import <DIMSDK/DIMStation.h>
#import <DIMSDK/DIMRobot.h>

// Group
#import <DIMSDK/DIMPolylogue.h>
#import <DIMSDK/DIMChatroom.h>

// Commands
#import <DIMSDK/DIMBlockCommand.h>
#import <DIMSDK/DIMMuteCommand.h>
#import <DIMSDK/DIMReceiptCommand.h>
#import <DIMSDK/DIMStorageCommand.h>

// CPUs
#import <DIMSDK/DIMContentProcessor.h>
#import <DIMSDK/DIMDefaultProcessor.h>
#import <DIMSDK/DIMCommandProcessor.h>
#import <DIMSDK/DIMMetaCommandProcessor.h>
#import <DIMSDK/DIMProfileCommandProcessor.h>
#import <DIMSDK/DIMHistoryProcessor.h>
// GPUs
#import <DIMSDK/DIMGroupCommandProcessor.h>
#import <DIMSDK/DIMInviteCommandProcessor.h>
#import <DIMSDK/DIMExpelCommandProcessor.h>
#import <DIMSDK/DIMQuitCommandProcessor.h>
#import <DIMSDK/DIMResetCommandProcessor.h>
#import <DIMSDK/DIMQueryCommandProcessor.h>

#import <DIMSDK/DIMAddressNameService.h>
#import <DIMSDK/DIMFacebook.h>
#import <DIMSDK/DIMKeyStore.h>
#import <DIMSDK/DIMMessenger.h>
#import <DIMSDK/DIMMessageProcessor.h>

#endif /* ! __DIM_SDK__== */
