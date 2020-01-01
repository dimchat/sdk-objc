# Decentralized Instant Messaging (Objective-C SDK)

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/dimchat/sdk-objc/blob/master/LICENSE)
[![Version](https://img.shields.io/badge/alpha-0.1.0-red.svg)](https://github.com/dimchat/sdk-objc/archive/master.zip)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/dimchat/sdk-objc/pulls)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20OSX%20%7C%20watchOS%20%7C%20tvOS-brightgreen.svg)](https://github.com/dimchat/sdk-objc/wiki)

### Dependencies

- [DIM Core (core-objc)](https://github.com/dimchat/core-objc) Decentralized Instant Messaging Protocol
	- [Message Module (dkd-objc)](https://github.com/dimchat/dkd-objc)
	- [Account Module (mkm-objc)](https://github.com/dimchat/mkm-objc)


```shell
cd GitHub/
mkdir dimchat; cd dimchat/

git clone https://github.com/dimchat/sdk-objc.git
git clone https://github.com/dimchat/core-objc.git
git clone https://github.com/dimchat/dkd-objc.git
git clone https://github.com/dimchat/mkm-objc.git
```


## Account

User private key, ID, meta, and profile are generated in client,
and broadcast only ```meta``` & ```profile``` onto DIM station.

### Register User Account

_Step 1_. generate private key (with asymmetric algorithm)

```objective-c
DIMPrivateKey *SK = MKMPrivateKeyWithAlgorithm(ACAlgorithmRSA);
```

**NOTICE**: After registered, the client should save the private key in secret storage.

_Step 2_. generate meta with private key (and meta seed)

```objective-c
NSString *seed = @"username";
DIMMeta *meta = [DIMMeta generateWithVersion:MKMMetaDefaultVersion
                                  privateKey:SK
                                        seed:seed];
```

_Step 3_. generate ID with meta (and network type)

```objective-c
DIMID *ID = [meta generateID:MKMNetwork_Main];
```

### Create and upload User Profile

_Step 4_. create profile with ID and sign with private key

```objective-c
DIMProfile *profile = [[DIMProfile alloc] initWithID:ID];
// set nickname and avatar URL
[profile setName:@"Albert Moky"];
[profile setAvatar:@"https://secure.gravatar.com/avatar/34aa0026f924d017dcc7a771f495c086"];
// sign
[profile sign:SK];
```

_Step 5_. send meta & profile to station

```objective-c
DIMCommand *cmd = [[DIMProfileCommand alloc] initWithID:ID meta:meta profile:profile];
DIMMessenger *messenger = [DIMMessenger sharedInstance];
[messenger sendCommand:cmd];
```

The profile should be sent to station after connected
and handshake accepted, details are provided in later chapters

## Connect and Handshake

_Step 1_. connect to DIM station (TCP)

_Step 2_. prepare for receiving message data package

```objective-c
- (void)onReceive:(NSData *)data {
    DIMMessenger *messenger = [DIMMessenger sharedInstance];
    NSData *response = [messenger onReceivePackage:data];
    if ([response length] > 0) {
        // send processing result back to the station
        [self send:response];
    }
}
```

_Step 3_. send first **handshake** command

(1) create handshake command

```objective-c
// first handshake will have no session key
NSString *session = nil;
DIMHandshakeCommand *cmd;
cmd = [[DIMHandshakeCommand alloc] initWithSessionKey:session];
```

(2) pack, encrypt and sign

```objective-c
DIMInstantMessage *iMsg = DKDInstantMessageCreate(cmd, user.ID, station.ID, nil);
DIMSecureMessage *sMsg = [messenger encryptMessage:iMsg];
DIMReliableMessage *rMsg = [messenger signMessage:sMsg];
```

(3) Meta protocol

Attaching meta in the first message package is to make sure the station can find it,
particularly when it's first time the user connect to this station.

```objective-c
if (cmd.state == DIMHandshake_Start) {
    rMsg.meta = user.meta;
}
```

(4) send out serialized message data package

```objective-c
NSData *data = [messenger serializeMessage:rMsg];
[self send:data];
```

_Step 4_. waiting handshake response

The CPU (Command Processing Units) will catch the handshake command response from station, and CPU will process them automatically, so just wait untill handshake success or network error.

## Message

### Content

* Text message

```objective-c
DIMContent *content = [[DIMTextContent alloc] initWithText:@"Hey, girl!"];
```

* Image message

```objective-c
content = [[DIMImageContent alloc] initWithImageData:data
                                            filename:@"image.png"];
```

* Voice message

```objective-c
content = [[DIMAudioContent alloc] initWithAudioData:data
                                            filename:@"voice.mp3"];
```

**NOTICE**: file message content (Image, Audio, Video)
will be sent out only includes the filename and a URL
where the file data (encrypted with the same symmetric key) be stored.

### Command

* Query meta with contact ID

```objective-c
DIMCommand *cmd = [[DIMMetaCommand alloc] initWithID:ID];
```

* Query profile with contact ID

```objective-c
DIMCommand *cmd = [[DIMProfileCommand alloc] initWithID:ID];
```

### Send command

```objective-c
@implementation DIMMessenger (Extension)

- (BOOL)sendCommand:(DIMCommand *)cmd {
    DIMStation *server = [self currentServer];
    NSAssert(server, @"server not connected yet");
    return [self sendContent:cmd receiver:server.ID];
}

@end
```

MetaCommand or ProfileCommand with only ID means querying, and the CPUs will catch and process all the response automatically.

## Command Processing Units

You can send a customized command (such as **search command**) and prepare a processor to handle the response.

### Search command processor

```objective-c
@interface DIMSearchCommandProcessor : DIMCommandProcessor

@end
```

```objective-c
NSString * const kNotificationName_SearchUsersUpdated = @"SearchUsersUpdated";

@implementation DIMSearchCommandProcessor

- (void)_parse:(DIMSearchCommand *)cmd {
    NSDictionary *result = cmd.results;
    // TODO: processing results
}

- (nullable DIMContent *)processContent:(DIMContent *)content
                                 sender:(DIMID *)sender
                                message:(DIMInstantMessage *)iMsg {
    NSAssert([content isKindOfClass:[DIMSearchCommand class]], @"search command error: %@", content);
    [self _parse:(DIMSearchCommand *)content];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:kNotificationName_SearchUsersUpdated
                      object:self
                    userInfo:content];
    // response nothing to the station
    return nil;
}

@end
```

### Handshake command processor

```objective-c
@interface DIMHandshakeCommandProcessor : DIMCommandProcessor

@end
```

```objective-c

@implementation DIMHandshakeCommandProcessor

- (nullable DIMContent *)_success {
    NSString *sessionKey = [self valueForContextName:@"session_key"];
    DIMServer *server = [self valueForContextName:@"server"];
    [server handshakeAccepted:YES session:sessionKey];
    return nil;
}

- (nullable DIMContent *)_ask:(NSString *)sessionKey {
    [self setContextValue:sessionKey forName:@"session_key"];
    return [[DIMHandshakeCommand alloc] initWithSessionKey:sessionKey];
}

- (nullable DIMContent *)processContent:(DIMContent *)content
                                 sender:(DIMID *)sender
                                message:(DIMInstantMessage *)iMsg {
    NSAssert([content isKindOfClass:[DIMHandshakeCommand class]], @"handshake error: %@", content);
    DIMHandshakeCommand *cmd = (DIMHandshakeCommand *)content;
    NSString *message = cmd.message;
    if ([message isEqualToString:@"DIM!"]) {
        // S -> C
        return [self _success];
    } else if ([message isEqualToString:@"DIM?"]) {
        // S -> C
        return [self _ask:cmd.sessionKey];
    } else {
        // C -> S: Hello world!
        NSAssert(false, @"handshake command error: %@", cmd);
        return nil;
    }
}

@end
```

And don't forget to register them.

```objective-c
[DIMCommandProcessor registerClass:[DIMHandshakeCommandProcessor class]
                        forCommand:DIMCommand_Handshake];
[DIMCommandProcessor registerClass:[DIMSearchCommandProcessor class]
                        forCommand:DIMCommand_Search];
```

## Save instant message

Override interface ```saveMessage:``` in DIMMessenger to store instant message:

```objective-c
- (BOOL)saveMessage:(DIMInstantMessage *)iMsg {
    DIMContent *content = iMsg.content;
    // TODO: check message type
    //       only save normal message and group commands
    //       ignore 'Handshake', ...
    //       return true to allow responding
    
    if ([content isKindOfClass:[DIMHandshakeCommand class]]) {
        // handshake command will be processed by CPUs
        // no need to save handshake command here
        return YES;
    }
    if ([content isKindOfClass:[DIMMetaCommand class]]) {
        // meta & profile command will be checked and saved by CPUs
        // no need to save meta & profile command here
        return YES;
    }
    if ([content isKindOfClass:[DIMMuteCommand class]] ||
        [content isKindOfClass:[DIMBlockCommand class]]) {
        // TODO: create CPUs for mute & block command
        // no need to save mute & block command here
        return YES;
    }
    if ([content isKindOfClass:[DIMSearchCommand class]]) {
        // search result will be parsed by CPUs
        // no need to save search command here
        return YES;
    }
    
    DIMAmanuensis *clerk = [DIMAmanuensis sharedInstance];
    
    if ([content isKindOfClass:[DIMReceiptCommand class]]) {
        return [clerk saveReceipt:iMsg];
    } else {
        return [clerk saveMessage:iMsg];
    }
}
```

Copyright &copy; 2018-2019 Albert Moky
