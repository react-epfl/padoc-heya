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

@implementation SpeakUpManager

@synthesize peer_id, dev_id, likedMessages, speakUpDelegate,dislikedMessages,deletedRoomIDs,inputText, messageManagerDelegate, roomManagerDelegate, roomArray, locationIsOK, connectionIsOK,unlockedRoomKeyArray, deletedMessageIDs, locationAtLastReset, avatarCacheByPeerID, socketIO, connectionDelegate, currentRoomID, currentRoom,inputRoomIDText,unlockedRoomArray, likeType, etiquetteType, etiquetteWasShown, myOwnRoomKeyArray, myOwnRoomArray;

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
            sharedSpeakUpManager.connectionIsOK=NO;
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
        }
    }
    return sharedSpeakUpManager;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// INCOMING CALLS TO THE SERVER
// SOCKET DID RECEIVE MESSAGE
- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet{
    [self stopNetworking];
    NSLog(@"webSocket received a message: %@", packet.args );
    NSString* type = packet.name;
    if ([type isEqual:@"peer_welcome"]) {
        NSDictionary *data = [packet.args objectAtIndex:0];
        [self receivedWelcome:data];
    }else if ([type isEqual:@"rooms"]) {
        [self receivedRooms: [packet.args objectAtIndex:0]];
        self.locationAtLastReset=self.peerLocation;
    } else if ([type isEqual:@"room"]) {
        NSString* roomID=[self receivedRoom: [packet.args objectAtIndex:0]];
        [messageManagerDelegate updateMessagesInRoom:roomID];
    }else if ([type isEqual:@"roomcreated"]) {
        [self receivedRoom: [packet.args objectAtIndex:0]];
    } else if ([type isEqual:@"roommessages"]) {
        NSArray *argsArray = packet.args;
        NSMutableDictionary* dict = [argsArray objectAtIndex:0];
        [self receivedMessages: [dict objectForKey:@"messages"] roomID:[dict objectForKey:@"room_id"]];
        [messageManagerDelegate updateMessagesInRoom:[dict objectForKey:@"room_id"]];
    } else if ([type isEqual:@"messagecreated"]) {
        NSMutableDictionary* dict = [packet.args objectAtIndex:0];
        [self receivedMessage: [dict objectForKey:@"message"] roomID:[dict objectForKey:@"room_id"]];
        [messageManagerDelegate updateMessagesInRoom:[dict objectForKey:@"room_id"]];
    }else if ([type isEqual:@"messageupdated"]) {
        NSMutableDictionary* dict = [packet.args objectAtIndex:0];
        [self receivedMessage: [dict objectForKey:@"message"] roomID:[dict objectForKey:@"room_id"]];
        [messageManagerDelegate updateMessagesInRoom:[dict objectForKey:@"room_id"]];
    }else if ([type isEqual:@"roomdeleted"]) {
        NSMutableDictionary* dict = [packet.args objectAtIndex:0];
        //remove room with roomID [dict objectForKey:@"room_id"]
                [messageManagerDelegate notifyThatRoomHasBeenDeleted:[dict objectForKey:@"room_id"]];
        [self receivedRoomToDelete:[dict objectForKey:@"room_id"]];
        [messageManagerDelegate updateMessagesInRoom:[dict objectForKey:@"room_id"]];
        
    }else if ([type isEqual:@"messagedeleted"]) {
        NSMutableDictionary* dict = [packet.args objectAtIndex:0];
        [self receivedMessageToDelete:[dict objectForKey:@"msg_id"] inRoom:[dict objectForKey:@"room_id"] withParent:[dict objectForKey:@"parent_id"]];
        [messageManagerDelegate updateMessagesInRoom:[dict objectForKey:@"room_id"]];
    }else{
        NSLog(@"got something else");
    }
    [self savePeerData];
    [speakUpDelegate updateData];
}
// WELCOME
-(void)receivedWelcome:(NSDictionary*)data{
    peer_id = [data objectForKey:@"peer_id"];
    connectionIsOK=YES;
    [connectionDelegate connectionHasRecovered];
    NSNumber* minVersion = [data objectForKey:@"min_v"];
    NSNumber* maxVersion = [data objectForKey:@"max_v"];
    if(minVersion && maxVersion){
        if ([minVersion intValue]> [API_VERSION intValue] || [maxVersion intValue] < [API_VERSION intValue]) {
            NSLog(@"Problem the API does not match, display message to go to the app store");
        }
    }
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
    for (NSDictionary *roomDictionary in roomDictionaries) {
        [self receivedRoom:roomDictionary];
    }
    [roomManagerDelegate updateRooms];
}
// RECEIVED ROOM
-(NSString*)receivedRoom:(NSDictionary*)roomDictionary{
    Room *room = [[Room alloc] initWithDictionary:roomDictionary];
    // when a room is received it is added if it was not already in the list, unless the user has hidden the room before
    NSMutableArray* roomsToRemove = [NSMutableArray array];
    for(Room *r in roomArray){
        if ([r.roomID isEqual:room.roomID]) {
            [roomsToRemove addObject:r];
        }
    }
    [roomArray removeObjectsInArray:roomsToRemove];
    [roomsToRemove removeAllObjects];
    for(Room *r in unlockedRoomArray){
        if ([r.roomID isEqual:room.roomID]) {
            [roomsToRemove addObject:r];
        }
    }
    [unlockedRoomArray removeObjectsInArray:roomsToRemove];
    [roomsToRemove removeAllObjects];
    for(Room *r in myOwnRoomArray){
        if ([r.roomID isEqual:room.roomID]) {
            [roomsToRemove addObject:r];
        }
    }
    [myOwnRoomArray removeObjectsInArray:roomsToRemove];
    
    if ([room.creatorID isEqualToString:self.peer_id]) {
        if(![myOwnRoomKeyArray containsObject:room.key]){
            [myOwnRoomKeyArray addObject:room.key];
        }
        [myOwnRoomArray addObject:room];
        [unlockedRoomKeyArray removeObject:room.key];
    }else if ([unlockedRoomKeyArray containsObject:room.key]) {
        [unlockedRoomArray addObject:room];
    }
    CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[room latitude] longitude: [room longitude]];
    room.distance = [self.peerLocation distanceFromLocation:roomlocation];
    if (room.distance<200.0){
        [roomArray addObject:room];
    }
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
        [roomArray removeObject:roomToDelete];
        roomToDelete=nil;
    }
    for(Room *r in myOwnRoomArray){
        if ([r.roomID isEqual:room_id]) {
            roomToDelete=r;
        }
    }
    if (roomToDelete) {
        [roomArray removeObject:roomToDelete];
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
-(void)addMessage:(Message*) message toRoom:(Room*) room{
    if ([room.roomID isEqual:message.roomID]) {
        BOOL messageUpdate=NO;
        for(Message *msg in room.messages){
            if ([msg.messageID isEqual:message.messageID]) {
                // update received, therefore just update the vote fields
                msg.score=message.score;
                msg.numberOfYes=message.numberOfYes;
                msg.numberOfNo=message.numberOfNo;
                messageUpdate=YES;
            }if ([msg.messageID isEqual:message.parentMessageID]) {
                for(Message *reply in msg.replies){
                    if ([reply.messageID isEqual:message.messageID]) {
                        reply.score=message.score;
                        reply.numberOfYes=message.numberOfYes;
                        reply.numberOfNo=message.numberOfNo;
                        messageUpdate=YES;
                    }
                }
                if (![deletedMessageIDs containsObject:message.messageID]&& !message.deleted && !messageUpdate) {
                    [msg.replies addObject:message];
                }
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
-(void)deleteMessage:(NSString*) m_id inRoom:(Room*) room  withRoomID:(NSString*) room_id withParent:(NSString*) parent_id{
    if ([room_id isEqual:room_id]) {
        Message* messageToDelete=nil;
        for(Message *msg in room.messages){
            if ([msg.messageID isEqual:m_id]) {
                // update received, therefore just update the vote fields
                messageToDelete=msg;
            }if ([msg.messageID isEqual:parent_id]) {
                for(Message *reply in msg.replies){
                    if ([reply.messageID isEqual:m_id]) {
                        messageToDelete=msg;
                    }
                }
                if (messageToDelete) {
                    [msg.replies removeObject:messageToDelete];
                    messageToDelete=nil;
                }
            }
        }
        if (messageToDelete) {
            [room.messages removeObject:messageToDelete];
        }
    }
}

- (void) socketIODidConnect:(SocketIO *)socket{
    [self stopNetworking];
    NSLog(@"socket is now open");
    [self handshake];
}
- (void) socketIO:(SocketIO *)socket onError:(NSError *)error{
    [self stopNetworking];
    connectionIsOK=NO;
    [connectionDelegate connectionWasLost];
    [self performSelector:@selector(connect) withObject:nil afterDelay:arc4random() % 4];
    NSLog(@"socket did fail with error: %@",[error description]);
}
- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error{
    [self stopNetworking];
    connectionIsOK=NO;
    [ connectionDelegate connectionWasLost];
    [self performSelector:@selector(connect)  withObject:nil afterDelay:arc4random() % 4];
    NSLog(@"socket did close with error %@ ",[error description]);
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// OUTGOING MESSAGES
// CONNECT
- (void)connect{
    socketIO = [[SocketIO alloc] initWithDelegate:self];
    [socketIO connectToHost:SERVER_URL onPort:SERVER_PORT];
}
// 2 - HANDSHAKE
- (void)handshake{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.dev_id forKey:@"dev_id"];
    if (peer_id) {
        [myData setValue:self.peer_id forKey:@"peer_id"];
    }
    [myData setValue:[NSNumber numberWithInt:RANGE] forKey:@"range"];
    NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
    [myLoc setValue:[NSNumber numberWithDouble:self.peerLocation.coordinate.latitude] forKey:@"lat"];
    [myLoc setValue:[NSNumber numberWithDouble:self.peerLocation.coordinate.longitude] forKey:@"lng"];
    [myData setValue:myLoc forKey:@"loc"];
    [myData setValue:[NSNumber numberWithDouble:self.peerLocation.horizontalAccuracy] forKey:@"accu"];
    [socketIO sendEvent:@"peer" withData:myData andAcknowledge:^(NSDictionary *data) {
        NSLog(@"Hanshake response received: %@", data  );
        [self receivedWelcome:data];
    }];
    [self startNetworking];
}
// GET ROOMS SOCKET.IO
-(void)getNearbyRooms{
    if (!connectionIsOK) {
        [self connect];
    }else{
        NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
        [myData setValue:API_VERSION forKey:@"api_v"];
        [myData setValue:self.peer_id forKey:@"peer_id"];
        NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
        [myLoc setValue:[NSNumber numberWithDouble:self.peerLocation.coordinate.latitude] forKey:@"lat"];
        [myLoc setValue:[NSNumber numberWithDouble:self.peerLocation.coordinate.longitude] forKey:@"lng"];
        [myData setValue:myLoc forKey:@"loc"];
        [myData setValue:[NSNumber numberWithDouble:self.peerLocation.horizontalAccuracy] forKey:@"accu"];
        [myData setValue:[NSNumber numberWithInt:RANGE] forKey:@"range"];
        NSArray* unlockedAndMyOwnRoomKeyArray = [[self.unlockedRoomKeyArray mutableCopy] arrayByAddingObjectsFromArray:[self.myOwnRoomKeyArray mutableCopy]];
        [myData setValue:unlockedAndMyOwnRoomKeyArray forKey:@"keys"];// UNLOCKED KEYS AND OWN ROOMS
        [socketIO sendEvent:@"getrooms" withData:myData andAcknowledge:^(NSArray *data) {
            NSLog(@"Received nearby rooms: %@", data  );
            [self receivedRooms:data];
        }];
    }
}
//CALL FOR MESSAGES IN A ROOM EITHER UPON UNLOCK OR ENTERING A ROOM
-(void) getMessagesInRoomID:(NSString*)room_id  orRoomHash:(NSString*) key withHandler:(void (^)(NSDictionary*))handler{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:room_id forKey:@"room_id"];
    [myData setValue:key forKey:@"key"];
    [self startNetworking];
    [self.socketIO sendEvent:@"getroom" withData:myData andAcknowledge:^(NSDictionary *data) {
        NSLog(@"Received messages of a room: %@", data  );
        // ADER NEEDS TO CHECK WHETHER IT IS A CORRECT ROOM OR NOT
        [self receivedMessages: [data objectForKey:@"messages"] roomID:[data objectForKey:@"room_id"]];
        [messageManagerDelegate updateMessagesInRoom:[data objectForKey:@"room_id"]];
        handler(data);
    }];
}
// CREATE MSG SOCKET.IO
-(void) createMessage:(Message *) message{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:message.roomID forKey:@"room_id"];
    [myData setValue:message.parentMessageID forKey:@"parent_id"];
    NSMutableDictionary* messageData = [[NSMutableDictionary alloc] init];
    [messageData setValue:message.content forKey:@"body"];
    [myData setValue:messageData forKey:@"message"];
    [socketIO sendEvent:@"createmessage" withData:myData];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"send" value:nil] build]];
}
// CREATE ROOM
- (void)createRoom:(Room *)room withHandler:(void (^)(NSDictionary*))handler{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.peer_id forKey:@"creator_id"];
    [myData setValue:room.name forKey:@"name"];
    [myData setValue:room.id_type forKey:@"id_type"];
    [myData setValue:[NSNumber numberWithBool:room.isOfficial] forKey:@"official"];
    if (room.latitude!=-1 && room.longitude!=-1) {
        NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
        [myLoc setValue:[NSNumber numberWithDouble:room.latitude] forKey:@"lat"];
        [myLoc setValue:[NSNumber numberWithDouble:room.longitude] forKey:@"lng"];
        [myData setValue:myLoc forKey:@"loc"];
        [myData setValue:[NSNumber numberWithDouble:self.peerLocation.horizontalAccuracy] forKey:@"accu"];
    }
    [socketIO sendEvent:@"createroom" withData:myData andAcknowledge:^(NSDictionary *data) {
        NSString* roomID=[self receivedRoom: data];
        [messageManagerDelegate updateMessagesInRoom:roomID];
        [myOwnRoomKeyArray addObject:roomID];
        NSLog(@"Received newly created room: %@", data );
        handler(data);
    }];
    [self savePeerData];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"create_room" value:nil] build]];
}
// RATE MESSAGE
- (void)rateMessage:(Message*)message  inRoom:(NSString*)roomID  yesRating:(int) yesRating noRating:(int) noRating{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:roomID forKey:@"room_id"];
    [myData setValue:message.parentMessageID forKey:@"parent_id"];
    NSMutableDictionary* messageDict = [[NSMutableDictionary alloc] init];
    [messageDict setValue:message.messageID forKey:@"msg_id"];
    [messageDict setValue:[NSNumber numberWithInt:yesRating] forKey:@"liked"];
    [messageDict setValue:[NSNumber numberWithInt: noRating] forKey:@"disliked"];
    [myData setValue:messageDict forKey:@"message"];
    [socketIO sendEvent:@"updatemessage" withData:myData];
    [self savePeerData];
}
// DELETE ROOM
-(void) deleteRoom:(Room *) room{
    [deletedRoomIDs addObject:room.roomID];
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:room.roomID forKey:@"room_id"];
    [socketIO sendEvent:@"deleteroom" withData:myData];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"delete_room" value:nil] build]];
}
// DELETE MESSAGE
-(void) deleteMessage:(Message *) message{
    [deletedMessageIDs addObject:message.messageID];
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:message.roomID forKey:@"room_id"];
    [myData setValue:message.messageID forKey:@"msg_id"];
    [socketIO sendEvent:@"deletemessage" withData:myData];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"  action:@"button_press" label:@"delete_message" value:nil] build]];
}
// SPAM MESSAGE
-(void) markMessageAsSpam:(Message *) message{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:message.roomID forKey:@"room_id"];
    [myData setValue:message.messageID forKey:@"msg_id"];
    NSArray* tags = @[SPAM];
    [myData setValue:tags forKey:@"new_tags"];
    [socketIO sendEvent:@"tag_message" withData:myData];
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
