// license: https://mit-license.org
//
//  Dao-Ke-Dao: Universal Message Module
//
//                               Written in 2018 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2018 Albert Moky
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
//  DKDMessageDelegates.h
//  DaoKeDao
//
//  Created by Albert Moky on 2018/10/20.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DIMEncryptedBundle;

@protocol DKDInstantMessageDelegate <NSObject>

/*
 *  Encrypt the Instant Message to Secure Message
 *
 *    +----------+      +----------+
 *    | sender   |      | sender   |
 *    | receiver |      | receiver |
 *    | time     |  ->  | time     |
 *    |          |      |          |
 *    | content  |      | data     |  1. data = encrypt(content, PW)
 *    +----------+      | key/keys |  2. key  = encrypt(PW, receiver.PK)
 *                      +----------+
 */

#pragma mark Encrypt Content

/**
 *  1. Serialize 'message.content' to data (JsON / ProtoBuf / ...)
 *
 * @param iMsg - instant message object
 * @param content - message.content
 * @param password - symmetric key (includes data compression algorithm)
 * @return serialized content data
 */
- (NSData *)message:(id<DKDInstantMessage>)iMsg
   serializeContent:(id<DKDContent>)content
            withKey:(id<MKSymmetricKey>)password;

/**
 *  2. Encrypt content data to 'message.data' with symmetric key
 *
 * @param iMsg - instant message object
 * @param data - serialized data of message.content
 * @param password - symmetric key
 * @return encrypted message content data
 */
- (NSData *)message:(id<DKDInstantMessage>)iMsg
     encryptContent:(NSData *)data
            withKey:(id<MKSymmetricKey>)password;

///**
// *  3. Encode 'message.data' to String (Base64)
// *
// * @param iMsg - instant message object
// * @param data - encrypted content data
// * @return String object
// */
//- (NSObject *)message:(id<DKDInstantMessage>)iMsg
//           encodeData:(NSData *)data;

#pragma mark Encrypt Key

/**
 *  4. Serialize message key to data (JsON / ProtoBuf / ...)
 *
 * @param iMsg - instant message object
 * @param password - symmetric key
 * @return serialized key data, null for reused (or broadcast message)
 */
- (nullable NSData *)message:(id<DKDInstantMessage>)iMsg
                serializeKey:(id<MKSymmetricKey>)password;

/**
 *  5. Encrypt key data to 'message.key' with receiver's public key
 *
 * @param iMsg - instant message object
 * @param data - serialized data of symmetric key
 * @param receiver - actual receiver (user, or group member)
 * @return encrypted symmetric key data and targets (ID terminals)
 */
- (nullable id<DIMEncryptedBundle>)message:(id<DKDInstantMessage>)iMsg
                                encryptKey:(NSData *)data
                               forReceiver:(id<MKMID>)receiver;

/**
 *  6. Encode 'message.key' to String (Base64)
 *
 * @param iMsg - instant message object
 * @param bundle - encrypted symmetric key data and targets (ID terminals)
 * @param receiver - actual receiver (user, or group member)
 * @return encoded key data and targets (ID + terminals)
 */
- (NSDictionary<NSString *, id> *)message:(id<DKDInstantMessage>)iMsg
                                encodeKey:(id<DIMEncryptedBundle>)bundle
                              forReceiver:(id<MKMID>)receiver;

@end

@protocol DKDSecureMessageDelegate <NSObject>

/*
 *  Decrypt the Secure Message to Instant Message
 *
 *    +----------+      +----------+
 *    | sender   |      | sender   |
 *    | receiver |      | receiver |
 *    | time     |  ->  | time     |
 *    |          |      |          |  1. PW      = decrypt(key, receiver.SK)
 *    | data     |      | content  |  2. content = decrypt(data, PW)
 *    | key/keys |      +----------+
 *    +----------+
 */

#pragma mark Decrypt Key

/**
 *  1. Decode 'message.key' to encrypted symmetric key data
 *
 * @param sMsg - secure message object
 * @param msgKeys - encoded key data and targets (ID + terminals)
 * @param receiver - actual receiver (user, or group member)
 * @return encrypted symmetric key data and targets (ID terminals)
 */
- (nullable id<DIMEncryptedBundle>)message:(id<DKDSecureMessage>)sMsg
                                 decodeKey:(NSDictionary<NSString *, id> *)msgKeys
                               forReceiver:(id<MKMID>)receiver;

/**
 *  2. Decrypt 'message.key' with receiver's private key
 *
 * @param sMsg - secure message object
 * @param bundle - encrypted symmetric key data and targets (ID terminals)
 * @param receiver - actual receiver (user, or group member)
 * @return serialized data of symmetric key
 */
- (nullable NSData *)message:(id<DKDSecureMessage>)sMsg
                  decryptKey:(id<DIMEncryptedBundle>)bundle
                 forReceiver:(id<MKMID>)receiver;

/**
 *  3. Deserialize message key from data (JsON / ProtoBuf / ...)
 *     (if key data is empty, means it should be reused, get it from key cache)
 *
 * @param sMsg - secure message object
 * @param data - serialized key data, null for reused key
 * @return symmetric key
 */
- (nullable id<MKSymmetricKey>)message:(id<DKDSecureMessage>)sMsg
                        deserializeKey:(nullable NSData *)data;

#pragma mark Decrypt Content

///**
// *  4. Decode 'message.data' to encrypted content data
// *
// * @param sMsg - secure message object
// * @param dataString - base64 string object
// * @return encrypted content data
// */
//- (nullable NSData *)message:(id<DKDSecureMessage>)sMsg
//                  decodeData:(NSObject *)dataString;

/**
 *  5. Decrypt 'message.data' with symmetric key
 *
 * @param sMsg - secure message object
 * @param data - encrypt content data
 * @param password - symmetric key
 * @return serialized data of message content
 */
- (nullable NSData *)message:(id<DKDSecureMessage>)sMsg
              decryptContent:(NSData *)data
                     withKey:(id<MKSymmetricKey>)password;

/**
 *  6. Deserialize message content from data (JsON / ProtoBuf / ...)
 *
 * @param sMsg - secure message object
 * @param data - serialized content data
 * @param password - symmetric key (includes data compression algorithm)
 * @return message content
 */
- (nullable __kindof id<DKDContent>)message:(id<DKDSecureMessage>)sMsg
                         deserializeContent:(NSData *)data
                                    withKey:(id<MKSymmetricKey>)password;

/*
 *  Sign the Secure Message to Reliable Message
 *
 *    +----------+      +----------+
 *    | sender   |      | sender   |
 *    | receiver |      | receiver |
 *    | time     |  ->  | time     |
 *    |          |      |          |
 *    | data     |      | data     |
 *    | key/keys |      | key/keys |
 *    +----------+      | signature|  1. signature = sign(data, sender.SK)
 *                      +----------+
 */

#pragma mark Signature

/**
 *  1. Sign 'message.data' with sender's private key
 *
 * @param sMsg - secure message object
 * @param data - encrypted message data
 * @return signature of encrypted message data
 */
- (NSData *)message:(id<DKDSecureMessage>)sMsg
           signData:(NSData *)data;

///**
// *  2. Encode 'message.signature' to String (Base64)
// *
// * @param sMsg - secure message object
// * @param signature - signature of message.data
// * @return String object
// */
//- (NSObject *)message:(id<DKDSecureMessage>)sMsg
//      encodeSignature:(NSData *)signature;

@end

@protocol DKDReliableMessageDelegate <NSObject>  // <DKDSecureMessageDelegate>

/*
 *  Verify the Reliable Message to Secure Message
 *
 *    +----------+      +----------+
 *    | sender   |      | sender   |
 *    | receiver |      | receiver |
 *    | time     |  ->  | time     |
 *    |          |      |          |
 *    | data     |      | data     |  1. verify(data, signature, sender.PK)
 *    | key/keys |      | key/keys |
 *    | signature|      +----------+
 *    +----------+
 */

#pragma mark Verification

///**
// *  1. Decode 'message.signature' from String (Base64)
// *
// * @param rMsg - reliable message object
// * @param signatureString - base64 string object
// * @return signature data
// */
//- (nullable NSData *)message:(id<DKDReliableMessage>)rMsg
//             decodeSignature:(NSObject *)signatureString;

/**
 *  2. Verify the message data and signature with sender's public key
 *
 * @param rMsg - reliable message object
 * @param data - message content(encrypted) data
 * @param signature - signature for message content(encrypted) data
 * @return YES on signature match
 */
- (BOOL)message:(id<DKDReliableMessage>)rMsg
     verifyData:(NSData *)data
  withSignature:(NSData *)signature;

@end

NS_ASSUME_NONNULL_END
