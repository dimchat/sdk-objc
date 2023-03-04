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

User private key, ID, meta, and visa document are generated in client,
and broadcast only ```meta``` & ```document``` onto DIM station.

### Register User Account

_Step 1_. generate private key (with asymmetric algorithm)

```objective-c
id<MKMPrivateKey> SK = MKMPrivateKeyGenerate(ACAlgorithmRSA);
```

**NOTICE**: After registered, the client should save the private key in secret storage.

_Step 2_. generate meta with private key (and meta seed)

```objective-c
NSString *seed = @"username";
id<MKMMeta> meta = MKMMetaGenerate(MKMMetaDefaultVersion, SK, seed);
```

_Step 3_. generate ID with meta (and network type)

```objective-c
NSString *terminal = nil;
id<MKMID> ID = MKMIDGenerate(meta, MKMEntityType_User, terminal);
```

### Create and upload User Document

_Step 4_. create document with ID and sign with private key

```objective-c
id<MKMVisa> doc = MKMDocumentNew(MKMDocument_Visa, ID);
// set nickname and avatar URL
[doc setName:@"Albert Moky"];
[doc setAvatar:@"https://secure.gravatar.com/avatar/34aa0026f924d017dcc7a771f495c086"];
// sign
[doc sign:SK];
```

_Step 5_. send meta & document to station

```objective-c
id<MKMID> gid = MKMEveryone();
id<MKMID> sid = MKMIDParse(@"station@anywhere");
id<DKDContent> cmd = [[DIMDocumentCommand alloc] initWithID:ID meta:meta document:doc];
[cmd setGroup:gid];
[messenger sendContent:cmd sender:nil receiver:sid priority:0];
```

The visa document should be sent to station after connected
and handshake accepted, details are provided in later chapters

## Connect and Handshake

_Step 1_. connect to DIM station (TCP)

_Step 2_. prepare for receiving message data package

```objective-c
- (void)onReceive:(NSData *)data {
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
cmd = [[DIMHandshakeCommand alloc] initWithSessionKey:session];
```

(2) pack, encrypt and sign

```objective-c
NSDate *now = nil;
id<DKDEnvelope> env = DKDEnvelopeCreate(sender, receiver, now);
id<DKDInstantMessage> iMsg = DKDInstantMessageCreate(env, cmd);
id<DKDSecureMessage>  sMsg = [messenger encryptMessage:iMsg];
id<DKDReliableMessage rMsg = [messenger signMessage:sMsg];
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
id<DKDContent> content = [[DIMTextContent alloc] initWithText:@"Hey, girl!"];
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

* Video message

```objective-c
content = [[DIMVideoContent alloc] initWithVideoData:data
                                            filename:@"movie.mp4"];
```


**NOTICE**: file message content (Image, Audio, Video)
will be sent out only includes the filename and a URL
where the file data (encrypted with the same symmetric key) be stored.

### Command

* Query meta with contact ID

```objective-c
id<DKDCommand> cmd = [[DIMMetaCommand alloc] initWithID:ID];
```

* Query document with contact ID

```objective-c
id<DKDCommand> cmd = [[DIMDocumentCommand alloc] initWithID:ID];
```

### Send command

```objective-c
@implementation DIMMessenger (Extension)

- (BOOL)sendCommand:(id<DKDCommand>)cmd {
    DIMStation *server = [self currentServer];
    NSAssert(server, @"server not connected yet");
    return [self sendContent:cmd receiver:server.ID];
}

@end
```

MetaCommand or DocumentCommand with only ID means querying, and the CPUs will catch and process all the response automatically.

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

- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content isKindOfClass:[DIMSearchCommand class]], @"search command error: %@", content);
    DIMSearchCommand *command = (DIMSearchCommand *)content;
    NSString *cmd = command.cmd;
    
    NSString *notificationName;
    if ([cmd isEqualToString:DIMCommand_Search]) {
        notificationName = kNotificationName_SearchUsersUpdated;
    } else if ([cmd isEqualToString:DIMCommand_OnlineUsers]) {
        notificationName = kNotificationName_OnlineUsersUpdated;
    } else {
        NSAssert(false, @"search command error: %@", cmd);
        return nil;
    }
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:notificationName
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

- (NSArray<id<DKDContent>> *)success {
    DIMServer *server = (DIMServer *)[self.messenger currentServer];
    [server handshakeAccepted:YES];
    return nil;
}

- (NSArray<id<DKDContent>> *)ask:(NSString *)sessionKey {
    DIMServer *server = (DIMServer *)[self.messenger currentServer];
    [server handshakeWithSession:sessionKey];
    return nil;
}

- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content isKindOfClass:[DIMHandshakeCommand class]], @"handshake error: %@", content);
    DIMHandshakeCommand *command = (DIMHandshakeCommand *)content;
    NSString *title = command.title;
    if ([title isEqualToString:@"DIM!"]) {
        // S -> C
        return [self success];
    } else if ([title isEqualToString:@"DIM?"]) {
        // S -> C
        return [self ask:command.sessionKey];
    } else {
        // C -> S: Hello world!
        NSAssert(false, @"handshake command error: %@", command);
        return nil;
    }
}

@end
```

And don't forget to register them.

```objective-c
@implementation DIMClientContentProcessorCreator

- (id<DIMContentProcessor>)createCommandProcessor:(NSString *)name type:(DKDContentType)msgType {
    // handshake
    if ([name isEqualToString:DIMCommand_Handshake]) {
        return CREATE_CPU(DIMHandshakeCommandProcessor);
    }
    // search
    if ([name isEqualToString:DIMCommand_Search]) {
        return CREATE_CPU(DIMSearchCommandProcessor);
    } else if ([name isEqualToString:DIMCommand_OnlineUsers]) {
        // TODO: shared the same processor with 'search'?
        return CREATE_CPU(DIMSearchCommandProcessor);
    }

    // others
    return [super createCommandProcessor:name type:msgType];
}

@end
```

## Save instant message

Override interface ```saveMessage:``` in DIMMessenger to store instant message:

```objective-c
- (BOOL)saveMessage:(id<DKDInstantMessage>)iMsg {
    id<DKDContent> content = iMsg.content;
    // TODO: check message type
    //       only save normal message and group commands
    //       ignore 'Handshake', ...
    //       return true to allow responding
    
    if ([content conformsToProtocol:@protocol(DKDHandshakeCommand)]) {
        // handshake command will be processed by CPUs
        // no need to save handshake command here
        return YES;
    }
    if ([content conformsToProtocol:@protocol(DKDMetaCommand)]) {
        // meta & document command will be checked and saved by CPUs
        // no need to save meta & document command here
        return YES;
    }
    if ([content conformsToProtocol:@protocol(DKDSearchCommand)]) {
        // search result will be parsed by CPUs
        // no need to save search command here
        return YES;
    }
    
    DIMAmanuensis *clerk = [DIMAmanuensis sharedInstance];
    
    if ([content conformsToProtocol:@protocol(DKDReceiptCommand)]) {
        return [clerk saveReceipt:iMsg];
    } else {
        return [clerk saveMessage:iMsg];
    }
}
```

Copyright &copy; 2018-2023 Albert Moky
