//
//  sharedSpeakUpManager.m
//
//  Created by Adrian Holzer on 06.11.12.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//
#import "SpeakUpManager.h"
#import "SocketIOPacket.h"
#import "ConnectionDelegate.h"
#import "RoomTableViewController.h"
#import "AppDelegate.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

#import "PacketContent.h"

#define GLOBAL @"global"


@implementation SpeakUpManager

@synthesize peer_id, dev_id, likedMessages, speakUpDelegate,dislikedMessages,deletedRoomIDs,inputText, messageManagerDelegate, roomManagerDelegate, roomArray, locationIsOK, connectionIsOK,unlockedRoomKeyArray, deletedMessageIDs, locationAtLastReset, avatarCacheByPeerID, socket, connectionDelegate, currentRoomID, currentRoom,inputRoomIDText,unlockedRoomArray, likeType, etiquetteType, etiquetteWasShown, myOwnRoomKeyArray, myOwnRoomArray;

static SpeakUpManager   *sharedSpeakUpManager = nil;

// creates the sharedSpeakUpManager singleton
+(id) sharedSpeakUpManager{
    @synchronized(self) {
        if (sharedSpeakUpManager == nil){
            sharedSpeakUpManager.avatarCacheByPeerID = [[NSCache alloc] init];
            sharedSpeakUpManager = [[self alloc] init];
            sharedSpeakUpManager.roomArray= [[NSMutableArray alloc] init];
            sharedSpeakUpManager.unlockedRoomArray= [[NSMutableArray alloc] init];
            sharedSpeakUpManager.myOwnRoomArray= [[NSMutableArray alloc] init];
            sharedSpeakUpManager.connectionDelegate=nil;
            [sharedSpeakUpManager initPeerData];// assign values to the fields, either by retriving it from storage or by initializing them
            sharedSpeakUpManager.connectionIsOK=YES;
            sharedSpeakUpManager.locationIsOK=NO;
            sharedSpeakUpManager.currentRoomID=nil;
            sharedSpeakUpManager.peerLocation=nil;
            sharedSpeakUpManager.locationManager = [[CLLocationManager alloc] init];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
                [sharedSpeakUpManager.locationManager requestWhenInUseAuthorization];
            }
            sharedSpeakUpManager.locationManager.delegate = sharedSpeakUpManager;
            sharedSpeakUpManager.locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
            sharedSpeakUpManager.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
            [sharedSpeakUpManager.locationManager startUpdatingLocation];// sets up the local location manager, this triggers the didUpdateToLocation callback
            [sharedSpeakUpManager connect];
            sharedSpeakUpManager.likeType= THUMB;
            sharedSpeakUpManager.etiquetteType = NO_ETIQUETTE;
            sharedSpeakUpManager.etiquetteWasShown = NO;
            
//            // Set up the socket and the groups
//            sharedSpeakUpManager.socket = [[MHMulticastSocket alloc] initWithServiceType:@"speakup"];
//            sharedSpeakUpManager.socket.delegate = sharedSpeakUpManager;
//            // For background mode
//            //    [speakUpDelegate setSocket:self.socket];
//            // Join the groups
//            [sharedSpeakUpManager.socket joinGroup:GLOBAL];
//            [sharedSpeakUpManager.socket joinGroup:[sharedSpeakUpManager.socket getOwnPeer]];
        }
    }
    return sharedSpeakUpManager;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CALLBACKS OF MHMULTICAST - INCOMING MESSAGES

// SOCKET DID RECEIVE MESSAGE
- (void)mhSocket:(MHSocket *)mhSocket
        didReceiveMessage:(NSData *)message
                 fromPeer:(NSString *)peer
            withTraceInfo:(NSArray *)traceInfo {
    NSLog(@"########## Packet received");
    
    [self stopNetworking];
    
    PacketContent* packetContent = [NSKeyedUnarchiver unarchiveObjectWithData:message];
    
//    NSLog(@"webSocket received a message: %@", packet.args );
    NSString* type = packetContent.type;
    if ([type isEqual:@"peer_welcome"]) {
        NSDictionary *data = packetContent.content;
        [self receivedWelcome:data];
        
    } else if ([type isEqual:@"rooms"]) {
        [self receivedRoomsObjects: packetContent.content];
//        self.locationAtLastReset=self.peerLocation;
        
    } else if ([type isEqual:@"room"]) {
        Room *room = packetContent.content;
        if (room) {
            NSString* roomID=[self receivedRoomObject: room];
            [messageManagerDelegate updateMessagesInRoom:roomID];
        }
        
    } else if ([type isEqual:@"roomcreated"] || [type isEqual:@"createroom"]) {
        [self receivedRoomObject: packetContent.content];
        
    } else if ([type isEqual:@"roommessages"]) {
        NSMutableDictionary* dict = packetContent.content;
        [self receivedMessages:[dict objectForKey:@"messages"] roomID:[dict objectForKey:@"room_id"]];
        [messageManagerDelegate updateMessagesInRoom:[dict objectForKey:@"room_id"]];
        
    } else if ([type isEqual:@"messagecreated"] || [type isEqual:@"createmessage"]) {
        Message *message = packetContent.content;
        [self receivedMessage:message];
        [messageManagerDelegate updateMessagesInRoom:message.roomID];
        
    } else if ([type isEqual:@"messageupdated"] || [type isEqual:@"updatemessage"]) {
        Message *message = packetContent.content;
        [self receivedMessage:message];
        [messageManagerDelegate updateMessagesInRoom:message.roomID];
        
    } else if ([type isEqual:@"roomdeleted"] || [type isEqual:@"deleteroom"]) {
        NSMutableDictionary* dict = packetContent.content;
        //remove room with roomID [dict objectForKey:@"room_id"]
        [self receivedRoomToDelete:[dict objectForKey:@"room_id"]];
        [messageManagerDelegate updateMessagesInRoom:[dict objectForKey:@"room_id"]];
        [roomManagerDelegate updateRooms];
        [messageManagerDelegate notifyThatRoomHasBeenDeleted:[dict objectForKey:@"room_id"]];
        
    } else if ([type isEqual:@"messagedeleted"] || [type isEqual:@"deletemessage"]) {
        NSMutableDictionary* dict = packetContent.content;
        [self receivedMessageToDelete:[dict objectForKey:@"msg_id"] inRoom:[dict objectForKey:@"room_id"] withParent:[dict objectForKey:@"parent_id"]];
        [messageManagerDelegate updateMessagesInRoom:[dict objectForKey:@"room_id"]];
        
    } else if ([type isEqual:@"getrooms"]) {
        // Send our list of rooms to the requesting peer
        PacketContent* msg = [[PacketContent alloc] initWithType:@"rooms" withContent:roomArray];
        NSError *error;
        [socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
             toDestinations:[[NSArray alloc] initWithObjects:peer, nil]
                      error:&error];
        
    } else if ([type isEqual:@"getroom"]) {
        // Send the requested room to the requesting peer
        NSMutableDictionary* dict = packetContent.content;
        
        Room* myData = nil;
        for (Room *room in roomArray) {
            if (room.roomID == [dict objectForKey:@"room_id"]) {
                myData = room;
                break;
            }
        }
        if (!myData) {
            for (Room *room in unlockedRoomArray) {
                if (room.roomID == [dict objectForKey:@"room_id"]) {
                    myData = room;
                    break;
                }
            }
        }
        if (!myData) {
            for (Room *room in myOwnRoomArray) {
                if (room.roomID == [dict objectForKey:@"room_id"]) {
                    myData = room;
                    break;
                }
            }
        }
        
        PacketContent* msg = [[PacketContent alloc] initWithType:@"room" withContent:myData];
        NSError *error;
        [socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
             toDestinations:[[NSArray alloc] initWithObjects:peer, nil]
                      error:&error];
        
    } else if ([type isEqual:@"tag_message"]) {
        // Tag the specified message
        
    } else {
        NSLog(@"got something else");
    }
    
    [self savePeerData];
    [speakUpDelegate updateData];
}

- (void)mhSocket:(MHSocket *)mhSocket
          failedToConnect:(NSError *)error {
    
}

// WELCOME
-(void)receivedWelcome:(NSDictionary*)data{
    peer_id = [data objectForKey:@"peer_id"];
    connectionIsOK=YES;
    [connectionDelegate connectionHasRecovered];
//    NSNumber* minVersion = [data objectForKey:@"min_v"];
//    NSNumber* maxVersion = [data objectForKey:@"max_v"];
//    if(minVersion && maxVersion){
//        if ([minVersion intValue]> [API_VERSION intValue] || [maxVersion intValue] < [API_VERSION intValue]) {
//            NSLog(@"Problem the API does not match, display message to go to the app store");
//        }
//    }
    [self handle_AB_testing:[data objectForKey:@"user_tags"]];
    // if the current view is nearby rooms, then get new rooms, otherwise get the messages in the current room
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UINavigationController *myNavController = (UINavigationController*) window.rootViewController;;
    if([myNavController.visibleViewController isKindOfClass:[RoomTableViewController class]]){
        [self getNearbyRooms];
    }else{
        [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID: [[SpeakUpManager sharedSpeakUpManager] currentRoomID] orRoomHash:nil withHandler:^(NSDictionary* handler){
            NSLog(@"got nearby rooms in the callback");
        }];
    }
}

// RECEIVED ROOMS
-(void)receivedRooms:(NSArray*)roomDictionaries{
    [roomArray removeAllObjects];
    self.locationAtLastReset=self.peerLocation;
    for (NSMutableDictionary *roomDictionary in roomDictionaries) {
        [self receivedRoom:roomDictionary];
    }
    [roomManagerDelegate updateRooms];
}
-(void)receivedRoomsObjects:(NSArray*)rooms{
    [roomArray removeAllObjects];
    self.locationAtLastReset=self.peerLocation;
    for (Room *room in rooms) {
        [self receivedRoomObject:room];
    }
    [roomManagerDelegate updateRooms];
}

// RECEIVED ROOM
-(NSString*)receivedRoom:(NSMutableDictionary*)roomDictionary {
    Room *room = [[Room alloc] initWithDictionary:roomDictionary];
    // when a room is received it is added if it was not already in the list, unless the user has hidden the room before
    NSMutableArray* roomsToRemove = [NSMutableArray array];
    for (Room *r in roomArray) {
        if ([r.roomID isEqual:room.roomID]) {
            [roomsToRemove addObject:r];
        }
    }
    [roomArray removeObjectsInArray:roomsToRemove];
    [roomsToRemove removeAllObjects];
    for (Room *r in unlockedRoomArray) {
        if ([r.roomID isEqual:room.roomID]) {
            [roomsToRemove addObject:r];
        }
    }
    [unlockedRoomArray removeObjectsInArray:roomsToRemove];
    [roomsToRemove removeAllObjects];
    for (Room *r in myOwnRoomArray) {
        if ([r.roomID isEqual:room.roomID]) {
            [roomsToRemove addObject:r];
        }
    }
    [myOwnRoomArray removeObjectsInArray:roomsToRemove];
    
    if ([room.creatorID isEqualToString:self.peer_id]) {
        if (![myOwnRoomKeyArray containsObject:room.key]) {
            [myOwnRoomKeyArray addObject:room.key];
        }
        [myOwnRoomArray addObject:room];
        [unlockedRoomKeyArray removeObject:room.key];
    } else if ([unlockedRoomKeyArray containsObject:room.key]) {
        [unlockedRoomArray addObject:room];
    }
//    CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[room latitude] longitude: [room longitude]];
//    room.distance = [self.peerLocation distanceFromLocation:roomlocation];
//    if (room.distance<200.0){
        [roomArray addObject:room];
//    }
    roomArray = [[self sortArrayByDistance:roomArray] mutableCopy];
    [roomManagerDelegate updateRooms];
    return room.roomID;
}

// RECEIVED ROOM
-(NSString*)receivedRoomObject:(Room *)room {
    // when a room is received it is added if it was not already in the list, unless the user has hidden the room before
    NSMutableArray* roomsToRemove = [NSMutableArray array];
    for (Room *r in roomArray) {
        if ([r.roomID isEqual:room.roomID]) {
            [roomsToRemove addObject:r];
        }
    }
    [roomArray removeObjectsInArray:roomsToRemove];
    [roomsToRemove removeAllObjects];
    for (Room *r in unlockedRoomArray) {
        if ([r.roomID isEqual:room.roomID]) {
            [roomsToRemove addObject:r];
        }
    }
    [unlockedRoomArray removeObjectsInArray:roomsToRemove];
    [roomsToRemove removeAllObjects];
    for (Room *r in myOwnRoomArray) {
        if ([r.roomID isEqual:room.roomID]) {
            [roomsToRemove addObject:r];
        }
    }
    [myOwnRoomArray removeObjectsInArray:roomsToRemove];
    
    if ([room.creatorID isEqualToString:self.peer_id]) {
        if (![myOwnRoomKeyArray containsObject:room.key]) {
            [myOwnRoomKeyArray addObject:room.key];
        }
        [myOwnRoomArray addObject:room];
        [unlockedRoomKeyArray removeObject:room.key];
    } else if ([unlockedRoomKeyArray containsObject:room.key]) {
        [unlockedRoomArray addObject:room];
    }
    //    CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[room latitude] longitude: [room longitude]];
    //    room.distance = [self.peerLocation distanceFromLocation:roomlocation];
    //    if (room.distance<200.0){
    [roomArray addObject:room];
    //    }
    roomArray = [[self sortArrayByDistance:roomArray] mutableCopy];
    [roomManagerDelegate updateRooms];
    return room.roomID;
}

// RECEIVED ROOM TO DELETE
-(void)receivedRoomToDelete:(NSString*)room_id{
    Room *roomToDelete=nil;
    for(Room *r in roomArray){
        if ([r.roomID isEqual:room_id]) {
            roomToDelete=r;
        }
    }
    if (roomToDelete) {
        [roomArray removeObject:roomToDelete];
        roomToDelete=nil;
    }
    for(Room *r in unlockedRoomArray){
        if ([r.roomID isEqual:room_id]) {
            roomToDelete=r;
        }
    }
    if (roomToDelete) {
        [unlockedRoomArray removeObject:roomToDelete];
        roomToDelete=nil;
    }
    for(Room *r in myOwnRoomArray){
        if ([r.roomID isEqual:room_id]) {
            roomToDelete=r;
        }
    }
    if (roomToDelete) {
        [myOwnRoomArray removeObject:roomToDelete];
        roomToDelete=nil;
    }
}

// RECEIVED MESSAGES
-(void)receivedMessages:(NSArray*)messageDictionaries roomID:(NSString*)roomID{
    for (NSDictionary *messageDictionary in messageDictionaries) {
        [self receivedMessage:messageDictionary roomID:roomID];
    }
}

// RECEIVED MESSAGE
-(void)receivedMessage:(NSDictionary*)messageDictionary roomID:(NSString*)roomID{
    Message* message = [[Message alloc] initWithDictionary:messageDictionary roomID: roomID];
    for(Room *room in roomArray){
        [self addMessage:message toRoom:room];
    }
    for(Room *room in unlockedRoomArray){
        [self addMessage:message toRoom:room];
    }
    for(Room *room in myOwnRoomArray){
        [self addMessage:message toRoom:room];
    }
}

-(void)receivedMessage:(Message *)message {
    for(Room *room in roomArray){
        [self addMessage:message toRoom:room];
    }
    for(Room *room in unlockedRoomArray){
        [self addMessage:message toRoom:room];
    }
    for(Room *room in myOwnRoomArray){
        [self addMessage:message toRoom:room];
    }
}

-(void)addMessage:(Message*) message toRoom:(Room*) room {
    if ([room.roomID isEqual:message.roomID]) {
        BOOL messageUpdate=NO;
        for (Message *msg in room.messages) {
            if ([msg.messageID isEqual:message.messageID]) {
                // update received, therefore just update the vote fields
                msg.score = message.score;
                msg.numberOfYes = message.numberOfYes;
                msg.numberOfNo = message.numberOfNo;
                messageUpdate = YES;
            }
            if ([msg.messageID isEqual:message.parentMessageID]) {
                for (Message *reply in msg.replies) {
                    if ([reply.messageID isEqual:message.messageID]) {
                        reply.score = message.score;
                        reply.numberOfYes = message.numberOfYes;
                        reply.numberOfNo = message.numberOfNo;
                        messageUpdate = YES;
                    }
                }
                if (![deletedMessageIDs containsObject:message.messageID]&& !message.deleted && !messageUpdate) {
                    [msg.replies addObject:message];
                }
            }
            if (messageUpdate) {
                break;
            }
        }
        if (!message.parentMessageID && ![deletedMessageIDs containsObject:message.messageID]&& !message.deleted && !messageUpdate) {
            [room.messages addObject:message];
        }
    }
}

-(void)receivedMessageToDelete:(NSString*) m_id inRoom:(NSString*) room_id withParent:(NSString*) parent_id{
    for(Room *room in roomArray){
        [self deleteMessage:m_id inRoom:room withRoomID:room_id withParent:parent_id];
    }
    for(Room *room in unlockedRoomArray){
        [self deleteMessage:m_id inRoom:room withRoomID:room_id withParent:parent_id];
    }
    for(Room *room in myOwnRoomArray){
        [self deleteMessage:m_id inRoom:room withRoomID:room_id withParent:parent_id];
    }
}

-(void)deleteMessage:(NSString*) m_id inRoom:(Room*) room  withRoomID:(NSString*) room_id withParent:(NSString*) parent_id {
    if ([room_id isEqual:room_id]) {
        Message* messageToDelete=nil;
        for (Message *msg in room.messages) {
            if ([msg.messageID isEqual:m_id]) {
                messageToDelete=msg;
            }
            if ([msg.messageID isEqual:parent_id]) {
                Message* replyToDelete=nil;
                for (Message *reply in msg.replies){
                    if ([reply.messageID isEqual:m_id]) {
                        replyToDelete=reply;
                    }
                }
                if (replyToDelete) {
                    [msg.replies removeObject:replyToDelete];
                    replyToDelete=nil;
                }
            }
        }
        if (messageToDelete) {
            [room.messages removeObject:messageToDelete];
        }
    }
}

//- (void) socketIODidConnect:(SocketIO *)socket{
//    [self stopNetworking];
//    NSLog(@"socket is now open");
//    [self handshake];
//}
//
//- (void) socketIO:(SocketIO *)socket onError:(NSError *)error{
//    [self stopNetworking];
//    connectionIsOK=NO;
//    [connectionDelegate connectionWasLost];
//    [self performSelector:@selector(connect) withObject:nil afterDelay:arc4random() % 4];
//    NSLog(@"socket did fail with error: %@",[error description]);
//}
//
//- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error{
//    [self stopNetworking];
//    connectionIsOK=NO;
//    [ connectionDelegate connectionWasLost];
//    [self performSelector:@selector(connect)  withObject:nil afterDelay:arc4random() % 4];
//    NSLog(@"socket did close with error %@ ",[error description]);
//}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// OUTGOING MESSAGES

// CONNECT
- (void)connect{
    if (socket == nil) {
        // Set up the socket and the groups
        socket = [[MHMulticastSocket alloc] initWithServiceType:@"chat"];
        socket.delegate = self;
    
        // For background mode
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate setSocket:self.socket];
    
        // Join the groups
        [socket joinGroup:GLOBAL];
        [socket joinGroup:[socket getOwnPeer]];
    }
    
    connectionIsOK = YES;
}

// 2 - HANDSHAKE
- (void)handshake{
//    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
//    [myData setValue:API_VERSION forKey:@"api_v"];
//    [myData setValue:self.dev_id forKey:@"dev_id"];
//    if (peer_id) {
//        [myData setValue:self.peer_id forKey:@"peer_id"];
//    }
//    [myData setValue:[NSNumber numberWithInt:RANGE] forKey:@"range"];
//    NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
//    [myLoc setValue:[NSNumber numberWithDouble:self.peerLocation.coordinate.latitude] forKey:@"lat"];
//    [myLoc setValue:[NSNumber numberWithDouble:self.peerLocation.coordinate.longitude] forKey:@"lng"];
//    [myData setValue:myLoc forKey:@"loc"];
//    [myData setValue:[NSNumber numberWithDouble:self.peerLocation.horizontalAccuracy] forKey:@"accu"];
//    [socketIO sendEvent:@"peer" withData:myData andAcknowledge:^(NSDictionary *data) {
//        NSLog(@"Hanshake response received: %@", data  );
//        [self receivedWelcome:data];
//    }];
//    [self startNetworking];
    
    
    [self startNetworking];
}

// GET ROOMS SOCKET.IO
-(void)getNearbyRooms{
    if (!connectionIsOK) {
        [self connect];
    } else {
//        NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
//        [myData setValue:API_VERSION forKey:@"api_v"];
//        [myData setValue:self.peer_id forKey:@"peer_id"];
//        NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
//        [myLoc setValue:[NSNumber numberWithDouble:self.peerLocation.coordinate.latitude] forKey:@"lat"];
//        [myLoc setValue:[NSNumber numberWithDouble:self.peerLocation.coordinate.longitude] forKey:@"lng"];
//        [myData setValue:myLoc forKey:@"loc"];
//        [myData setValue:[NSNumber numberWithDouble:self.peerLocation.horizontalAccuracy] forKey:@"accu"];
//        [myData setValue:[NSNumber numberWithInt:RANGE] forKey:@"range"];
//        NSArray* unlockedAndMyOwnRoomKeyArray = [[self.unlockedRoomKeyArray mutableCopy] arrayByAddingObjectsFromArray:[self.myOwnRoomKeyArray mutableCopy]];
        //        [myData setValue:unlockedAndMyOwnRoomKeyArray forKey:@"keys"];// UNLOCKED KEYS AND OWN ROOMS
//        [socketIO sendEvent:@"getrooms" withData:myData andAcknowledge:^(NSArray *data) {
//            NSLog(@"Received nearby rooms: %@", data  );
//            [self receivedRooms:data];
//        }];
    
        PacketContent* msg = [[PacketContent alloc] initWithType:@"getrooms" withContent:nil];
        NSError *error;
        [socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
             toDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                      error:&error];
    }
}

// CALL FOR MESSAGES IN A ROOM EITHER UPON UNLOCK OR ENTERING A ROOM
-(void) getMessagesInRoomID:(NSString*)room_id  orRoomHash:(NSString*) key withHandler:(void (^)(NSDictionary*))handler{
//    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
//    [myData setValue:API_VERSION forKey:@"api_v"];
//    [myData setValue:self.peer_id forKey:@"peer_id"];
//    [myData setValue:room_id forKey:@"room_id"];
//    [myData setValue:key forKey:@"key"];
//    [self startNetworking];
//    [self.socketIO sendEvent:@"getroom" withData:myData andAcknowledge:^(NSDictionary *data) {
//        NSLog(@"Received messages of a room: %@", data  );
//        // ADER NEEDS TO CHECK WHETHER IT IS A CORRECT ROOM OR NOT
//        [self receivedMessages: [data objectForKey:@"messages"] roomID:[data objectForKey:@"room_id"]];
//        [messageManagerDelegate updateMessagesInRoom:[data objectForKey:@"room_id"]];
//        handler(data);
//    }];
    
    
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:room_id forKey:@"room_id"];
    [myData setValue:key forKey:@"key"];
    
    PacketContent* msg = [[PacketContent alloc] initWithType:@"getroom" withContent:myData];
    NSError *error;
    [socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
         toDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                  error:&error];
}
// CREATE MSG SOCKET.IO
-(void) createMessage:(Message *) message {
//    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
//    [myData setValue:API_VERSION forKey:@"api_v"];
//    [myData setValue:self.peer_id forKey:@"peer_id"];
//    [myData setValue:message.roomID forKey:@"room_id"];
//    [myData setValue:message.parentMessageID forKey:@"parent_id"];
//    NSMutableDictionary* messageData = [[NSMutableDictionary alloc] init];
//    [messageData setValue:message.content forKey:@"body"];
//    [myData setValue:messageData forKey:@"message"];
//    [socketIO sendEvent:@"createmessage" withData:myData];
//    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"send" value:nil] build]];
    
    
//    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
//    [myData setValue:peer_id forKey:@"peer_id"];
//    [myData setValue:message.roomID forKey:@"room_id"];
//    [myData setValue:message.parentMessageID forKey:@"parent_id"];
//    NSMutableDictionary* messageData = [[NSMutableDictionary alloc] init];
//    [messageData setValue:message.content forKey:@"body"];
//    [myData setValue:messageData forKey:@"message"];
    
    // Broadcast the message
    PacketContent* msg = [[PacketContent alloc] initWithType:@"createmessage" withContent:message];
    NSError *error;
    [socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
         toDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                  error:&error];
    
    // Add the message locally
    [self receivedMessage:message];
    [messageManagerDelegate updateMessagesInRoom:message.roomID];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"send" value:nil] build]];
}

// CREATE ROOM
- (void)createRoom:(Room *)room withHandler:(void (^)(NSDictionary*))handler{
//    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
//    [myData setValue:API_VERSION forKey:@"api_v"];
//    [myData setValue:self.peer_id forKey:@"creator_id"];
//    [myData setValue:room.name forKey:@"name"];
//    [myData setValue:room.id_type forKey:@"id_type"];
//    [myData setValue:[NSNumber numberWithBool:room.isOfficial] forKey:@"official"];
//    if (room.latitude!=-1 && room.longitude!=-1) {
//        NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
//        [myLoc setValue:[NSNumber numberWithDouble:room.latitude] forKey:@"lat"];
//        [myLoc setValue:[NSNumber numberWithDouble:room.longitude] forKey:@"lng"];
//        [myData setValue:myLoc forKey:@"loc"];
//        [myData setValue:[NSNumber numberWithDouble:self.peerLocation.horizontalAccuracy] forKey:@"accu"];
//    }
//    [socketIO sendEvent:@"createroom" withData:myData andAcknowledge:^(NSDictionary *data) {
//        NSString* roomID=[self receivedRoom: data];
//        [messageManagerDelegate updateMessagesInRoom:roomID];
//        [myOwnRoomKeyArray addObject:roomID];
//        NSLog(@"Received newly created room: %@", data );
//        handler(data);
//    }];
//    [self savePeerData];
//    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"create_room" value:nil] build]];
    
    PacketContent* msg = [[PacketContent alloc] initWithType:@"createroom" withContent:room];
    NSError *error;
    [socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
         toDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                  error:&error];
    
    NSString* roomID=[self receivedRoomObject:room];
    [messageManagerDelegate updateMessagesInRoom:roomID];
    [myOwnRoomKeyArray addObject:roomID];
    
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:room.name forKey:@"name"];
    [myData setValue:room.id_type forKey:@"id_type"];
    [myData setValue:[NSNumber numberWithBool:room.isOfficial] forKey:@"official"];
    
    // Let us generate a random string for the room ID
    [myData setValue:room.roomID forKey:@"room_id"];
    [myData setValue:room.key forKey:@"key"];
    
    [myData setValue:room.creatorID forKey:@"creator_id"];
    
    handler(myData);
    
    [self savePeerData];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"create_room" value:nil] build]];
}

// RATE MESSAGE
- (void)rateMessage:(Message*)message  inRoom:(NSString*)roomID  yesRating:(int) yesRating noRating:(int) noRating{
//    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
//    [myData setValue:API_VERSION forKey:@"api_v"];
//    [myData setValue:self.peer_id forKey:@"peer_id"];
//    [myData setValue:roomID forKey:@"room_id"];
//    [myData setValue:message.parentMessageID forKey:@"parent_id"];
//    NSMutableDictionary* messageDict = [[NSMutableDictionary alloc] init];
//    [messageDict setValue:message.messageID forKey:@"msg_id"];
//    [messageDict setValue:[NSNumber numberWithInt:yesRating] forKey:@"liked"];
//    [messageDict setValue:[NSNumber numberWithInt: noRating] forKey:@"disliked"];
//    [myData setValue:messageDict forKey:@"message"];
//    [socketIO sendEvent:@"updatemessage" withData:myData];
//    [self savePeerData];
    
//    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
//    [myData setValue:roomID forKey:@"room_id"];
//    NSMutableDictionary* messageDict = [[NSMutableDictionary alloc] init];
//    [messageDict setValue:message.messageID forKey:@"msg_id"];
//    [messageDict setValue:[NSNumber numberWithInt:yesRating] forKey:@"liked"];
//    [messageDict setValue:[NSNumber numberWithInt: noRating] forKey:@"disliked"];
//    [myData setValue:messageDict forKey:@"message"];
    
    PacketContent* msg = [[PacketContent alloc] initWithType:@"updatemessage" withContent:message];
    NSError *error;
    [socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
         toDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                  error:&error];
    
    // Update the message locally
    [self receivedMessage:message];
    
    [self savePeerData];
}

// DELETE ROOM
-(void) deleteRoom:(Room *) room{
//    [deletedRoomIDs addObject:room.roomID];
//    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
//    [myData setValue:API_VERSION forKey:@"api_v"];
//    [myData setValue:self.peer_id forKey:@"peer_id"];
//    [myData setValue:room.roomID forKey:@"room_id"];
//    [socketIO sendEvent:@"deleteroom" withData:myData];
//    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"delete_room" value:nil] build]];
//    [self receivedRoomToDelete:room.roomID];
//    [messageManagerDelegate updateMessagesInRoom:room.roomID];
//    [roomManagerDelegate updateRooms];
    
    
    [deletedRoomIDs addObject:room.roomID];
    
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:room.roomID forKey:@"room_id"];
    
    PacketContent* msg = [[PacketContent alloc] initWithType:@"deleteroom" withContent:myData];
    NSError *error;
    [socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
         toDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                  error:&error];
    
    // Delete the room locally
    [self receivedRoomToDelete:room.roomID];
    [messageManagerDelegate updateMessagesInRoom:room.roomID];
    [roomManagerDelegate updateRooms];
}

// DELETE MESSAGE
-(void) deleteMessage:(Message *) message{
//    [deletedMessageIDs addObject:message.messageID];
//    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
//    [myData setValue:API_VERSION forKey:@"api_v"];
//    [myData setValue:self.peer_id forKey:@"peer_id"];
//    [myData setValue:message.roomID forKey:@"room_id"];
//    [myData setValue:message.messageID forKey:@"msg_id"];
//    [socketIO sendEvent:@"deletemessage" withData:myData];
//    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"delete_message" value:nil] build]];
    
    
    [deletedMessageIDs addObject:message.messageID];
    
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:message.roomID forKey:@"room_id"];
    [myData setValue:message.messageID forKey:@"msg_id"];
    
    PacketContent* msg = [[PacketContent alloc] initWithType:@"deletemessage" withContent:myData];
    NSError *error;
    [socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
         toDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                  error:&error];
    
    // Delete the message locally
    [self receivedMessageToDelete:message.messageID inRoom:message.roomID withParent:message.parentMessageID];
    [messageManagerDelegate updateMessagesInRoom:message.roomID];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"delete_message" value:nil] build]];
}

// SPAM MESSAGE
-(void) markMessageAsSpam:(Message *) message{
//    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
//    [myData setValue:API_VERSION forKey:@"api_v"];
//    [myData setValue:self.peer_id forKey:@"peer_id"];
//    [myData setValue:message.roomID forKey:@"room_id"];
//    [myData setValue:message.messageID forKey:@"msg_id"];
//    NSArray* tags = @[SPAM];
//    [myData setValue:tags forKey:@"new_tags"];
//    [socketIO sendEvent:@"tag_message" withData:myData];
//    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"mark_spam_message" value:nil] build]];
    
    
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:message.roomID forKey:@"room_id"];
    [myData setValue:message.messageID forKey:@"msg_id"];
    NSArray* tags = @[SPAM];
    [myData setValue:tags forKey:@"new_tags"];

    PacketContent* msg = [[PacketContent alloc] initWithType:@"tag_message" withContent:myData];
    NSError *error;
    [socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
         toDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                  error:&error];
    
    // Update the message locally
    [self receivedMessage:message];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"mark_spam_message" value:nil] build]];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LOCATION MANAGER CALLBACK

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    self.peerLocation = newLocation;
    if (!locationIsOK){
        locationIsOK=YES;
        [sharedSpeakUpManager getNearbyRooms];
    }
}
-(void)updateRoomLocations{
    for(Room *room in roomArray){
        CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[room latitude] longitude: [room longitude]];
        room.distance = [self.peerLocation distanceFromLocation:roomlocation];
    }
    self.roomArray = [[self sortArrayByDistance:roomArray] mutableCopy];
    [roomManagerDelegate updateRooms];
}
// LOCATION FAILED
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"location FAILED %@", [error description]);
}
// SAVING DATA
-(void)initPeerData{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:@"dev_id"]){
        dev_id= [defaults objectForKey:@"dev_id"];
    }else {
        dev_id = [UIDevice currentDevice].identifierForVendor.UUIDString;
    }
    if([defaults objectForKey:@"peer_id"]){
        peer_id= [defaults objectForKey:@"peer_id"];
    }else {
        peer_id= nil;
    }
    if([defaults objectForKey:@"inputRoomIDText"]){
        inputRoomIDText= [defaults objectForKey:@"inputRoomIDText"];
    }else {
        inputRoomIDText= nil;
    }
    if([defaults objectForKey:@"likedMessages"]){
        likedMessages= [[defaults objectForKey:@"likedMessages"]mutableCopy];
    }else {
        likedMessages= [[NSMutableArray alloc] init];
    }
    if([defaults objectForKey:@"dislikedMessages"]){
        dislikedMessages= [[defaults objectForKey:@"dislikedMessages"]mutableCopy];
    }else {
        dislikedMessages= [[NSMutableArray alloc] init];
    }
    if([defaults objectForKey:@"deletedMessageIDs"]){
        deletedMessageIDs= [[defaults objectForKey:@"deletedMessageIDs"]mutableCopy];
    }else {
        deletedMessageIDs= [[NSMutableArray alloc] init];
    }
    if([defaults objectForKey:@"deletedRoomIDs"]){
        deletedRoomIDs= [[defaults objectForKey:@"deletedRoomIDs"]mutableCopy];
    }else {
        deletedRoomIDs= [[NSMutableArray alloc] init];
    }
    if([defaults objectForKey:@"unlockedRoomKeyArray"]){
        unlockedRoomKeyArray= [[defaults objectForKey:@"unlockedRoomKeyArray"]mutableCopy];
    }else {
        unlockedRoomKeyArray= [[NSMutableArray alloc] init];
    }
    if([defaults objectForKey:@"myOwnRoomKeyArray"]){
        myOwnRoomKeyArray= [[defaults objectForKey:@"myOwnRoomKeyArray"]mutableCopy];
    }else {
        myOwnRoomKeyArray= [[NSMutableArray alloc] init];
    }
    inputText=@"";
    sharedSpeakUpManager.locationAtLastReset = nil;
    sharedSpeakUpManager.peerLocation = nil;
}
-(void)savePeerData{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:dev_id forKey:@"dev_id"];
    [defaults setObject:peer_id forKey:@"peer_id"];
    [defaults setObject:inputRoomIDText forKey:@"inputRoomIDText"];
    [defaults setObject:likedMessages forKey:@"likedMessages"];
    [defaults setObject:unlockedRoomKeyArray forKey:@"unlockedRoomKeyArray"];
    [defaults setObject:myOwnRoomKeyArray forKey:@"myOwnRoomKeyArray"];
    [defaults setObject:dislikedMessages forKey:@"dislikedMessages"];
    [defaults setObject:deletedMessageIDs forKey:@"deletedMessageIDs"];
    [defaults setObject:deletedRoomIDs forKey:@"deletedRoomIDs"];
    [defaults synchronize];
}
// UTILITIES
-(NSArray*) sortArrayByDistance:(NSArray*) unsortedRooms{
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES];
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [unsortedRooms sortedArrayUsingDescriptors:sortDescriptors];
    return sortedArray;
}
// METHODS RELATED TO NETWORKING
-(void)startNetworking{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}
-(void)stopNetworking{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}
-(Room*) currentRoom{
    for(Room *room in myOwnRoomArray){
        if([room.roomID isEqual:self.currentRoomID]){
            return room;
        }
    }
    for(Room *room in unlockedRoomArray){
        if([room.roomID isEqual:self.currentRoomID]){
            return room;
        }
    }
    for(Room *room in roomArray){
        if([room.roomID isEqual:self.currentRoomID]){
            return room;
        }
    }
    return nil;
}
// AB TESTING
-(void)handle_AB_testing:(NSArray*)ab_testing_flags{
    if ([ab_testing_flags containsObject:THUMB]) {
        self.likeType=THUMB;
    }else if ([ab_testing_flags containsObject:ARROW]) {
        self.likeType=ARROW;
    }else if    ([ab_testing_flags containsObject:PLUS]) {
        self.likeType=PLUS;
    }
    if ([ab_testing_flags containsObject:ETIQUETTE_PRESENT]) {
        self.etiquetteType=ETIQUETTE_PRESENT;
    }else if ([ab_testing_flags containsObject:ETIQUETTE_FUTURE]) {
        self.etiquetteType=ETIQUETTE_FUTURE;
    }else if ([ab_testing_flags containsObject:NO_ETIQUETTE]) {
        self.etiquetteType=NO_ETIQUETTE;
    }
}

@end
