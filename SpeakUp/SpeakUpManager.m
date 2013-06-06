//
//  sharedSpeakUpManager.m
//
//  Created by Adrian Holzer on 06.11.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "SpeakUpManager.h"
#import "SocketIOPacket.h"



@implementation SpeakUpManager

@synthesize peer_id, dev_id, likedMessages, speakUpDelegate,dislikedMessages,myRoomIDs,inputText, isSuperUser, messageManagerDelegate, roomManagerDelegate, roomArray, locationIsOK, connectionIsOK, myMessageIDs, locationAtLastReset, socketIO, range;

static SpeakUpManager   *sharedSpeakUpManager = nil;

// creates the sharedSpeakUpManager singleton
+(id) sharedSpeakUpManager{
    @synchronized(self) {
        if (sharedSpeakUpManager == nil){
            sharedSpeakUpManager = [[self alloc] init];
            sharedSpeakUpManager.roomArray= [[NSMutableArray alloc] init];// initializes the room array, containing all nearby rooms
            [sharedSpeakUpManager initPeerData];// assign values to the fields, either by retriving it from storage or by initializing them
            sharedSpeakUpManager.connectionIsOK=NO;
            sharedSpeakUpManager.locationIsOK=NO;
            
            // sets up the local location manager, this triggers the didUpdateToLocation callback
            // If Location Services are disabled, restricted or denied.
            if ((![CLLocationManager locationServicesEnabled])
                || ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
                || ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied))
            {
                // Send the user to the location settings preferences
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"prefs:root=LOCATION_SERVICES"]];
            }
            sharedSpeakUpManager.locationManager = [[CLLocationManager alloc] init];
            sharedSpeakUpManager.locationManager.delegate = sharedSpeakUpManager;
            sharedSpeakUpManager.locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
            sharedSpeakUpManager.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
            [sharedSpeakUpManager.locationManager startUpdatingLocation];
            
        }
    }
    return sharedSpeakUpManager;
}
//===========================
// SOCKET DID RECEIVE MESSAGE
//===========================
- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet{
    [self stopNetworking];
    NSLog(@"webSocket received a message: %@", packet.args );
    
    NSString* type = packet.name;
    if ([type isEqual:@"peer_welcome"]) {
        NSDictionary *data = [packet.args objectAtIndex:0];
        peer_id = [data objectForKey:@"peer_id"];
        connectionIsOK=YES;
        [self getNearbyRooms];
    }else if ([type isEqual:@"rooms"]) {
        [self receivedRooms: [packet.args objectAtIndex:0]];
        self.locationAtLastReset=self.location;
    } else if ([type isEqual:@"roomcreated"]) {
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
//================
// RECEIVED ROOMS
//================
-(void)receivedRooms:(NSArray*)roomDictionaries{
    [roomArray removeAllObjects];
    self.locationAtLastReset=self.location;
    NSLog(@"ALL OBJECT ARE REMOVED FROM NEARBY ROOMS");
    for (NSDictionary *roomDictionary in roomDictionaries) {
        [self receivedRoom:roomDictionary];
    }
}
//==============
// RECEIVED ROOM
//==============
-(void)receivedRoom:(NSDictionary*)roomDictionary{
    Room *room = [[Room alloc] initWithDictionary:roomDictionary];
    // IF room too far, do nothing
    if([self.location distanceFromLocation:[[CLLocation alloc] initWithLatitude:[room latitude] longitude: [room longitude]]]<=RANGE){
        BOOL roomAlreadyInArray = NO;
        for(Room *r in roomArray){
            if ([r.roomID isEqual:room.roomID]) {
                roomAlreadyInArray= YES;
            }
        }
        if (!roomAlreadyInArray) {
            [roomArray addObject:room];
            roomArray = [[self sortArrayByDistance:roomArray] mutableCopy];
            [roomManagerDelegate updateRooms:[NSArray arrayWithArray:roomArray]];
        }
    }else{
        //NSLog(@"room is too far");
       // [messageManagerDelegate notifyThatRoomIsTooFar:room];
    }
}
//==================
// RECEIVED MESSAGES
//==================
-(void)receivedMessages:(NSArray*)messageDictionaries roomID:(NSString*)roomID{
    for (NSDictionary *messageDictionary in messageDictionaries) {
        [self receivedMessage:messageDictionary roomID:roomID];
    }
}
//=================
// RECEIVED MESSAGE
//=================
-(void)receivedMessage:(NSDictionary*)messageDictionary roomID:(NSString*)roomID{
    Message* message = [[Message alloc] initWithDictionary:messageDictionary roomID: roomID];
    for(Room *room in roomArray){
        if ([room.roomID isEqual:message.roomID]) {
            Message* messageToRemove=nil;
            for(Message *msg in room.messages){
                if ([msg.messageID isEqual:message.messageID]) {
                    messageToRemove=msg;
                }
            }
            if (messageToRemove) {
                [room.messages removeObject:messageToRemove];
            }
            [room.messages addObject:message];
        }
    }
}
//========================
// HANDSHAKE SOCKET.IO
//========================
- (void)handshake{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.dev_id forKey:@"dev_id"];
    if (peer_id) {
        [myData setValue:self.peer_id forKey:@"peer_id"];
    }
    [myData setValue:self.range forKey:@"range"];
    NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
    [myLoc setValue:[NSNumber numberWithDouble:self.latitude] forKey:@"lat"];
    [myLoc setValue:[NSNumber numberWithDouble:self.longitude] forKey:@"lng"];
    [myData setValue:myLoc forKey:@"loc"];
    [myData setValue:[NSNumber numberWithDouble:self.location.horizontalAccuracy] forKey:@"accu"];
    
    [socketIO sendEvent:@"peer" withData:myData];
    [self startNetworking];
}
//========================
// SOCKET CONNECT
//========================
- (void)connect{
    if (locationIsOK) {
        socketIO = [[SocketIO alloc] initWithDelegate:self];
        [socketIO connectToHost:SERVER_URL onPort:1337];
    [self startNetworking];
    }
}
- (void) socketIODidConnect:(SocketIO *)socket{
    [self stopNetworking];
    NSLog(@"socket is now open");
    [self handshake];
}
- (void) socketIO:(SocketIO *)socket onError:(NSError *)error{
    [self stopNetworking];
    NSLog(@"socket did fail with error: %@",[error description]);
}
- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error{
    [self stopNetworking];
    connectionIsOK=NO;
    NSLog(@"socket did close with error %@ ",[error description]);
}
//========================
// GET ROOMS SOCKET.IO
//========================
-(void)getNearbyRooms{
    if (connectionIsOK) {
        NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
        [myData setValue:self.peer_id forKey:@"peer_id"];
        NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
        [myLoc setValue:[NSNumber numberWithDouble:self.latitude] forKey:@"lat"];
        [myLoc setValue:[NSNumber numberWithDouble:self.longitude] forKey:@"lng"];
        [myData setValue:myLoc forKey:@"loc"];
        [myData setValue:[NSNumber numberWithDouble:self.location.horizontalAccuracy] forKey:@"accu"];
        [myData setValue:self.range forKey:@"range"];
        [socketIO sendEvent:@"getrooms" withData:myData];
        [self startNetworking];
    }else if(locationIsOK){
        [self connect];
    }
}
//========================
// GET MESSAGES SOCKET.IO
//========================
-(void)getMessagesInRoom:(NSString*)room_id{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:room_id forKey:@"room_id"];
    
    [socketIO sendEvent:@"getmessages" withData:myData];
    [self startNetworking];
}
//========================
// CREATE MSG SOCKET.IO
//========================
-(void) createMessage:(Message *) message{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:message.roomID forKey:@"room_id"];
    NSMutableDictionary* messageData = [[NSMutableDictionary alloc] init];
    [messageData setValue:message.content forKey:@"body"];
    [myData setValue:messageData forKey:@"message"];
    
    [socketIO sendEvent:@"createmessage" withData:myData];
    [self startNetworking];
    
}
//========================
// CREATE ROOM SOCKET.IO
//========================
- (void)createRoom:(Room *)room{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.peer_id forKey:@"creator_id"];
    [myData setValue:room.name forKey:@"name"];
    [myData setValue:[NSNumber numberWithDouble:room.isOfficial] forKey:@"official"];
    NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
    [myLoc setValue:[NSNumber numberWithDouble:self.latitude] forKey:@"lat"];
    [myLoc setValue:[NSNumber numberWithDouble:self.longitude] forKey:@"lng"];
    [myData setValue:myLoc forKey:@"loc"];
    [myData setValue:[NSNumber numberWithDouble:self.location.horizontalAccuracy] forKey:@"accu"];
    
    [socketIO sendEvent:@"createroom" withData:myData];
    [self startNetworking];
    
    [self savePeerData];
}
//==============
// RATE MESSAGE
//==============
- (void)rateMessage:(NSString*)messageID inRoom:(NSString*)roomID  yesRating:(int) yesRating noRating:(int) noRating{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
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
//============================
// LOCATION MANAGER CALLBACK
//============================
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    self.location = newLocation;
    self.latitude = newLocation.coordinate.latitude;
    self.longitude = newLocation.coordinate.longitude;
    //NSLog(@"location update");
    if (!locationIsOK ||!connectionIsOK){
        locationIsOK=YES;
        [sharedSpeakUpManager connect];
    }
   // NSMutableArray* roomsToRemove = [NSMutableArray array];
    for(Room *room in roomArray){
        CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[room latitude] longitude: [room longitude]];
        room.distance = [self.location distanceFromLocation:roomlocation];
       // if (room.distance>RANGE) {
            //[roomsToRemove addObject:room];
            //[messageManagerDelegate notifyThatRoomIsTooFar:room];
        //}
    }
    //if location is too far from last refresh, need to reload
    if (!locationAtLastReset ||  [self.locationAtLastReset distanceFromLocation:self.location] >RANGE*2) {
        self.locationAtLastReset=self.location;
        [self getNearbyRooms];
    }
    self.roomArray = [[self sortArrayByDistance:roomArray] mutableCopy];
    [roomManagerDelegate updateRooms:[NSArray arrayWithArray:roomArray]];
}
//========================
// LOCATION FAILED
//========================
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    self.latitude=-1;
    self.longitude=-1;
}
//========================
// SAVING DATA
//========================
-(void)initPeerData{
    range=[NSNumber numberWithInt:RANGE];
    
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
    if([defaults objectForKey:@"likedMessages"]){
        likedMessages= [defaults objectForKey:@"likedMessages"];
    }else {
        likedMessages= [[NSMutableArray alloc] init];
    }
    if([defaults objectForKey:@"dislikedMessages"]){
        dislikedMessages= [defaults objectForKey:@"dislikedMessages"];
    }else {
        dislikedMessages= [[NSMutableArray alloc] init];
    }
    if([defaults objectForKey:@"myMessageIDs"]){
        myMessageIDs= [defaults objectForKey:@"myMessageIDs"];
    }else {
        myMessageIDs= [[NSMutableArray alloc] init];
    }
    if([defaults objectForKey:@"myRoomIDs"]){
        myRoomIDs= [defaults objectForKey:@"myRoomIDs"];
    }else {
        myRoomIDs= [[NSMutableArray alloc] init];
    }
    if([defaults objectForKey:@"isSuperUser"]){
        NSNumber* booleanNumber;
        booleanNumber = [defaults objectForKey:@"isSuperUser"] ;
        isSuperUser = [booleanNumber boolValue];
    }else {
        isSuperUser= NO;
    }
    inputText=@"";
    sharedSpeakUpManager.locationAtLastReset = nil;
    sharedSpeakUpManager.location = nil;
    sharedSpeakUpManager.latitude = -1;
    sharedSpeakUpManager.longitude =-1;
}
-(void)savePeerData{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:dev_id forKey:@"dev_id"];
    [defaults setObject:peer_id forKey:@"peer_id"];
    [defaults setObject:likedMessages forKey:@"likedMessages"];
    [defaults setObject:dislikedMessages forKey:@"dislikedMessages"];
    [defaults setObject:myMessageIDs forKey:@"myMessageIDs"];
    [defaults setObject:myRoomIDs forKey:@"myRoomIDs"];
    [defaults setObject:[NSNumber numberWithBool:self.isSuperUser] forKey:@"isSuperUser"];
    [defaults synchronize];
}
//========================
// UTILITIES
//========================
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

//========================
//========================



// DELETE ROOM
//------------
-(NSArray*) deleteRoom:(Room *) room{
    //NSNumber* publicationID = [myRoomPublicationIDs objectForKey:room.roomID];
    //if(publicationID){
    //        [event setStringProperty:@"eventType" to:@"deleteRoom"];
    //        [event setStringProperty:@"roomID" to:room.roomID];
    //        // create a publication to indicate that the message is not visible any longer
    // }
    // NSMutableArray* rooms = [[NSMutableArray alloc] initWithArray:roomArray];
    // [rooms removeObject:room];
    // roomArray=rooms;
    return roomArray;
}

// DELETE MESSAGE
//---------------
-(void) deleteMessage:(Message *) message{
    //  NSNumber* publicationID = [myMessagePublicationIDs objectForKey:message.messageID];
    // if(publicationID){
    //        [event setStringProperty:@"eventType" to:@"deleteMessage"];
    //        [event setStringProperty:@"messageID" to:message.messageID];
    //        [event setStringProperty:@"roomID" to:message.roomID];
    // [self startNetworking];
    // }
}






@end

// DELIVER EVENTS
//-(void)retrieveMatchesForSucceededWithResponse{
//            // NEW RATING RECEIVED
//        } else if([eventType isEqual:@"messageRating"]){
//            NSString* roomID = [match.event getStringProperty:@"roomID" ];
//            NSString* peerStringID = [match.event getStringProperty:@"peerID" ];
//            NSString* messageID = [match.event getStringProperty:@"messageID" ];
//            NSNumber* yesRating = [match.event getIntProperty:@"yesRating"];
//            NSNumber* noRating = [match.event getIntProperty:@"noRating"];
//            [self assignRatingToMessage:messageID inRoom: roomID byPeer:peerStringID  yesRating: [yesRating intValue] noRating: [noRating intValue]];
//            NSLog(@"RECEIVED RATING: y %d n %d, FOR MESSAGE %@ IN ROOM %@", [yesRating intValue], [noRating intValue], messageID, roomID);
//        } else if([eventType isEqual:@"deleteMessage"]){
//            NSString* messageID = [match.event getStringProperty:@"messageID" ];
//            NSString* roomID = [match.event getStringProperty:@"roomID" ];
//            for(Room *room in roomArray){
//                if ([room.roomID isEqual:roomID]) {
//                    Message* messageToRemove = nil;
//                    for (Message* message in room.messages) {
//                        if([message.messageID isEqual:messageID]){
//                            messageToRemove=message;
//                        }
//                    }
//                    [room.messages removeObject:messageToRemove];
//                    NSLog(@"Received notification to delete message %@ %@ ", messageToRemove.content, messageID);
//                    [messageManagerDelegate updateMessages:room.messages inRoom:room];
//                }
//            }
//        }else if([eventType isEqual:@"deleteRoom"]){
//
//            NSString* roomID = [match.event getStringProperty:@"roomID" ];
//            Room* roomToRemove = nil;
//            for(Room *room in roomArray){
//                if ([room.roomID isEqual:roomID]) {
//                    roomToRemove=room;
//                }
//            }
//            NSMutableArray* rooms = [[NSMutableArray alloc] initWithArray:roomArray];
//            [rooms removeObject:roomToRemove];
//            roomArray=rooms;
//            [messageManagerDelegate notifyThatRoomHasBeenDeleted:roomToRemove];
//            NSLog(@"Received notification to delete room %@ %@ ", roomToRemove.name, roomID);
//            [roomManagerDelegate updateRooms:roomArray];
//            // ADER DO SOETHING TO MAKE SOMEONE LEAVE THE ROOM IF SHE IS INSIDE
//        }
//    }
//}
