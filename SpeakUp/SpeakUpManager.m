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



@implementation SpeakUpManager

@synthesize peer_id, dev_id, likedMessages, speakUpDelegate,dislikedMessages,deletedRoomIDs,inputText, isSuperUser, messageManagerDelegate, roomManagerDelegate, roomArray, locationIsOK, connectionIsOK,unlockedRoomKeyArray, deletedMessageIDs, locationAtLastReset, avatarCacheByPeerID, socketIO, connectionDelegate, currentRoomID, currentRoom,inputRoomIDText,unlockedRoomArray, likeType;

static SpeakUpManager   *sharedSpeakUpManager = nil;

// creates the sharedSpeakUpManager singleton
+(id) sharedSpeakUpManager{
    @synchronized(self) {
        if (sharedSpeakUpManager == nil){
            sharedSpeakUpManager.avatarCacheByPeerID = [[NSCache alloc] init];
            sharedSpeakUpManager = [[self alloc] init];
            sharedSpeakUpManager.roomArray= [[NSMutableArray alloc] init];// initializes the room array, containing all nearby rooms
            sharedSpeakUpManager.unlockedRoomArray= [[NSMutableArray alloc] init];// initializes the room array, containing all nearby rooms
            sharedSpeakUpManager.connectionDelegate=nil;
            [sharedSpeakUpManager initPeerData];// assign values to the fields, either by retriving it from storage or by initializing them
            sharedSpeakUpManager.connectionIsOK=NO;
            sharedSpeakUpManager.locationIsOK=NO;
            sharedSpeakUpManager.currentRoomID=nil;
            // sets up the local location manager, this triggers the didUpdateToLocation callback
            sharedSpeakUpManager.peerLocation=nil;
            sharedSpeakUpManager.locationManager = [[CLLocationManager alloc] init];
            [sharedSpeakUpManager.locationManager requestWhenInUseAuthorization];
            sharedSpeakUpManager.locationManager.delegate = sharedSpeakUpManager;
            sharedSpeakUpManager.locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
            sharedSpeakUpManager.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
            [sharedSpeakUpManager.locationManager startUpdatingLocation];
            [sharedSpeakUpManager connect];
            //A/B TESTING THUMB STYLES
            sharedSpeakUpManager.likeType= THUMB;
            //sharedSpeakUpManager.likeType= ARROW;
            //sharedSpeakUpManager.likeType= PLUS;
        }
    }
    return sharedSpeakUpManager;
}

// SOCKET DID RECEIVE MESSAGE
- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet{
    [self stopNetworking];
    NSLog(@"webSocket received a message: %@", packet.args );
    NSString* type = packet.name;
    if ([type isEqual:@"peer_welcome"]) {
        NSDictionary *data = [packet.args objectAtIndex:0];
        peer_id = [data objectForKey:@"peer_id"];
        connectionIsOK=YES;
        [connectionDelegate connectionHasRecovered];
        // VERSION CHECKING
        NSNumber* minVersion = [data objectForKey:@"min_v"];
        NSNumber* maxVersion = [data objectForKey:@"max_v"];
        if(minVersion && maxVersion){
            if ([minVersion intValue]> [API_VERSION intValue] || [maxVersion intValue] < [API_VERSION intValue]) {
                NSLog(@"Problem the API does not match, display message to go to the app store");
            }
        }
        // if the current view is nearby rooms, then get new rooms, otherwise get the messages in the current room
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UINavigationController *myNavController = (UINavigationController*) window.rootViewController;;
        if([myNavController.visibleViewController isKindOfClass:[RoomTableViewController class]]){
            [self getNearbyRooms];
        }else{
            [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID: [[SpeakUpManager sharedSpeakUpManager] currentRoomID] orRoomHash:nil];
        }
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
    }else{
        NSLog(@"got something else");
    }
    [self savePeerData];
    [speakUpDelegate updateData];
}

// RECEIVED ROOMS
-(void)receivedRooms:(NSArray*)roomDictionaries{
    [roomArray removeAllObjects];
    self.locationAtLastReset=self.peerLocation;
    NSLog(@"ALL OBJECT ARE REMOVED FROM NEARBY ROOMS");
    for (NSDictionary *roomDictionary in roomDictionaries) {
        [self receivedRoom:roomDictionary];
    }
    // needs to refresh view if there was no room in the list
    [roomManagerDelegate updateRooms:[NSMutableArray arrayWithArray:roomArray] unlockedRooms:unlockedRoomArray];
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
    if ([unlockedRoomKeyArray containsObject:room.key]) {
        [unlockedRoomArray addObject:room];
    }else{
        [roomArray addObject:room];
    }
    roomArray = [[self sortArrayByDistance:roomArray] mutableCopy];
    [roomManagerDelegate updateRooms:[NSMutableArray arrayWithArray:roomArray] unlockedRooms:unlockedRoomArray];
    return room.roomID;
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
}

-(void)addMessage:(Message*) message toRoom:(Room*) room{
    if ([room.roomID isEqual:message.roomID]) {
        Message* messageToRemove=nil;
        for(Message *msg in room.messages){
            if ([msg.messageID isEqual:message.messageID]) {
                // update received, therefore the message must be deleted
                messageToRemove=msg;
            }
        }
        if (messageToRemove) {
            [room.messages removeObject:messageToRemove];
        }
        // add new message unless it has been hidden by the user
        if (![deletedMessageIDs containsObject:message.messageID]&& !message.deleted) {
            [room.messages addObject:message];
        }
    }
}

// HANDSHAKE SOCKET.IO
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
    [socketIO sendEvent:@"peer" withData:myData];
    [self startNetworking];
}

// SOCKET CONNECT
- (void)connect{
    socketIO = [[SocketIO alloc] initWithDelegate:self];
    [socketIO connectToHost:SERVER_URL onPort:SERVER_PORT];
    [self startNetworking];
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
    //[self connect];
    NSLog(@"socket did close with error %@ ",[error description]);
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
        [myData setValue:self.unlockedRoomKeyArray forKey:@"keys"];// UNLOCKED KEYS
        [socketIO sendEvent:@"getrooms" withData:myData];
        [self startNetworking];
    }
}

// GET MESSAGES SOCKET.IO NOW CALLED GET ROOM
-(void)getMessagesInRoomID:(NSString*)room_id  orRoomHash:(NSString*) key{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:room_id forKey:@"room_id"];
    [myData setValue:key forKey:@"key"];
    [socketIO sendEvent:@"getroom" withData:myData];
    [self startNetworking];
}

// CREATE MSG SOCKET.IO
-(void) createMessage:(Message *) message{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:message.roomID forKey:@"room_id"];
    NSMutableDictionary* messageData = [[NSMutableDictionary alloc] init];
    [messageData setValue:message.content forKey:@"body"];
    [myData setValue:messageData forKey:@"message"];
    [socketIO sendEvent:@"createmessage" withData:myData];
    [self startNetworking];
}

// CREATE ROOM SOCKET.IO
- (void)createRoom:(Room *)room{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.peer_id forKey:@"creator_id"];
    [myData setValue:room.name forKey:@"name"];
    [myData setValue:room.id_type forKey:@"id_type"];
    [myData setValue:[NSNumber numberWithBool:room.isOfficial] forKey:@"official"];
    NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
    [myLoc setValue:[NSNumber numberWithDouble:self.peerLocation.coordinate.latitude] forKey:@"lat"];
    [myLoc setValue:[NSNumber numberWithDouble:self.peerLocation.coordinate.longitude] forKey:@"lng"];
    [myData setValue:myLoc forKey:@"loc"];
    [myData setValue:[NSNumber numberWithDouble:self.peerLocation.horizontalAccuracy] forKey:@"accu"];
    [socketIO sendEvent:@"createroom" withData:myData];
    [self startNetworking];
    [self savePeerData];
}

// RATE MESSAGE
- (void)rateMessage:(NSString*)messageID inRoom:(NSString*)roomID  yesRating:(int) yesRating noRating:(int) noRating{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:API_VERSION forKey:@"api_v"];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:roomID forKey:@"room_id"];
    NSMutableDictionary* messageDict = [[NSMutableDictionary alloc] init];
    [messageDict setValue:messageID forKey:@"msg_id"];
    [messageDict setValue:[NSNumber numberWithInt:yesRating] forKey:@"liked"];
    [messageDict setValue:[NSNumber numberWithInt: noRating] forKey:@"disliked"];
    [myData setValue:messageDict forKey:@"message"];
    [socketIO sendEvent:@"updatemessage" withData:myData];
    [self startNetworking];
    [self savePeerData];
}

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
    [roomManagerDelegate updateRooms:[NSMutableArray arrayWithArray:roomArray] unlockedRooms:unlockedRoomArray];
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
    if([defaults objectForKey:@"isSuperUser"]){
        NSNumber* booleanNumber;
        booleanNumber = [defaults objectForKey:@"isSuperUser"];
        isSuperUser = [booleanNumber boolValue];
    }else {
        isSuperUser= NO;
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
    [defaults setObject:dislikedMessages forKey:@"dislikedMessages"];
    [defaults setObject:deletedMessageIDs forKey:@"deletedMessageIDs"];
    [defaults setObject:deletedRoomIDs forKey:@"deletedRoomIDs"];
    [defaults setObject:[NSNumber numberWithBool:self.isSuperUser] forKey:@"isSuperUser"];
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

// DELETE ROOM
-(void) deleteRoom:(Room *) room{
    [deletedRoomIDs addObject:room.roomID];
    // should inform the server if the room was the peer's rooms
}

// DELETE MESSAGE
-(void) deleteMessage:(Message *) message{
    [deletedMessageIDs addObject:message.messageID];
    // should inform the server if the message was the peer's message
}

-(void) markMessageAsSpam:(Message *) message{
    //ADER need to send a message to the server
}

-(void) showDisconnectionView{
    
}

-(Room*) currentRoom{
    for(Room *room in roomArray){
        if([room.roomID isEqual:self.currentRoomID]){
            return room;
        }
    }
    for(Room *room in unlockedRoomArray){
        if([room.roomID isEqual:self.currentRoomID]){
            return room;
        }
    }
    return nil;
}

@end
