//
//  sharedSpeakUpManager.m
//
//  Created by Adrian Holzer on 06.11.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "SpeakUpManager.h"
#import "SocketIOPacket.h"

#define DURATION 43200 // a month in minutes

#define iWallMiddlewareUnknownPeerException  @"net.headfirst.iwall.UnknownPeerException"

@implementation SpeakUpManager

@synthesize matches, publicationRadius, peer_id, dev_id,subscriptionRadius, likedMessages, sharedTopic, timer, messageLifetime, roomLifetime, speakUpDelegate,dislikedMessages,myMessagePublicationIDs,myRoomIDs,inputText, isSuperUser, messageManagerDelegate, roomManagerDelegate, roomCounter, messageCounter, roomArray, locationIsOK, connectionIsOK,myRoomPublicationIDs, myMessageIDs, locationAtLastReset, socketIO, range;

static SpeakUpManager   *sharedSpeakUpManager = nil;

// creates the sharedSpeakUpManager singleton
+(id) sharedSpeakUpManager{
    @synchronized(self) {
        if (sharedSpeakUpManager == nil){
            sharedSpeakUpManager = [[self alloc] init];
            sharedSpeakUpManager.roomArray= [[NSMutableArray alloc] init];// initializes the room array, containing all nearby rooms
            [sharedSpeakUpManager initPeerData];// assign values to the fields, either by retriving it from storage or by initializing them
            sharedSpeakUpManager.connectionIsOK=YES;
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
    
    NSLog(@"webSocket received a message: %@", packet.args );
    
    
    NSString* type = packet.name;
    if ([type isEqual:@"rooms"]) {
        // ANDRII: Probably we need to clean the list of rooms before inserting recently received rooms there? Imagine when the room is not anymore in the list of visible rooms I might be wrong and not understanding something :)
        [self receivedRooms: [packet.args objectAtIndex:0]];
    } else if ([type isEqual:@"roomcreated"]) {
        [self receivedRoom: [packet.args objectAtIndex:0]];
    } else if ([type isEqual:@"roommessages"]) {
        NSLog(@"got messages");
        NSArray *argsArray = packet.args;
        NSMutableDictionary* dict = [argsArray objectAtIndex:0];
        [self receivedMessages: [dict objectForKey:@"messages"] roomID:[dict objectForKey:@"room_id"]];
    } else if ([type isEqual:@"messagecreated"]) {
        NSMutableDictionary* dict = [packet.args objectAtIndex:0];
        [self receivedMessage: [dict objectForKey:@"message"] roomID:[dict objectForKey:@"room_id"]];
        
    }else if ([type isEqual:@"peer_welcome"]) {
        NSDictionary *data = [packet.args objectAtIndex:0];
        peer_id = [data objectForKey:@"peer_id"];
        NSLog(@"welcome peer %@",peer_id);
        [self getNearbyRooms];
    }else{
        NSLog(@"got something else");
    }
}


//================
// RECEIVED ROOMS
//================
-(void)receivedRooms:(NSArray*)roomDictionaries{
    for (NSDictionary *roomDictionary in roomDictionaries) {
        [self receivedRoom:roomDictionary];
    }
}
//==============
// RECEIVED ROOM
//==============
-(void)receivedRoom:(NSDictionary*)roomDictionary{
    Room *room = [[Room alloc] initWithDictionary:roomDictionary];
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
            BOOL msgAlreadyInRoom = NO;
            for(Message *msg in room.messages){
                if ([msg.messageID isEqual:message.messageID]) {
                    msgAlreadyInRoom= YES;
                }
            }
            if (!msgAlreadyInRoom) {
                [room.messages addObject:message];
                [messageManagerDelegate updateMessages:room.messages inRoom: room];
            }
        }
    }
}

//========================
// SOCKET CONNECT
//========================
- (void)connect{
    socketIO = [[SocketIO alloc] initWithDelegate:self];
    [socketIO connectToHost:@"localhost" onPort:1337];
}


- (void) socketIODidConnect:(SocketIO *)socket{
    NSLog(@"socket is now open");
    [self handshake];
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error{
    NSLog(@"socket did fail with error: %@",[error description]);
}

- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error{
    NSLog(@"socket did close with error %@ ",[error description]);
}


//========================
// GET ROOMS SOCKET.IO
//========================
// {type: 'getrooms', data: {peer_id, loc: {lat, lng}, accu, range}}
-(void)getNearbyRooms{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
    [myLoc setValue:[NSNumber numberWithDouble:self.latitude] forKey:@"lat"];
    [myLoc setValue:[NSNumber numberWithDouble:self.longitude] forKey:@"lng"];
    [myData setValue:myLoc forKey:@"loc"];
    [myData setValue:[NSNumber numberWithDouble:self.location.horizontalAccuracy] forKey:@"accu"];
    [myData setValue:self.range forKey:@"range"];
    
    [socketIO sendEvent:@"getrooms" withData:myData];
}


//========================
// GET MESSAGES SOCKET.IO
//========================
-(void)getMessagesInRoom:(NSString*)room_id{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:room_id forKey:@"room_id"];
    
    [socketIO sendEvent:@"getmessages" withData:myData];
}

//========================
// CREATE MSG SOCKET.IO
//========================
-(void) createMessage:(Message *) message{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    [myData setValue:message.content forKey:@"body"];
    [myData setValue:message.roomID forKey:@"room_id"];
    
    [socketIO sendEvent:@"createmessage" withData:myData];
    // [myMessageIDs addObject:message.messageID];
    [self savePeerData];
    [self assignMessage:message];
}

//========================
// CREATE ROOM SOCKET.IO
//========================
// {type: 'createroom', data: {creator_id, name, loc: {lat, lng}, accu}}
- (void)createRoom:(Room *)room{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.peer_id forKey:@"creator_id"];
    [myData setValue:room.name forKey:@"name"];
    NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
    [myLoc setValue:[NSNumber numberWithDouble:self.latitude] forKey:@"lat"];
    [myLoc setValue:[NSNumber numberWithDouble:self.longitude] forKey:@"lng"];
    [myData setValue:myLoc forKey:@"loc"];
    [myData setValue:[NSNumber numberWithDouble:self.location.horizontalAccuracy] forKey:@"accu"];
    
    [socketIO sendEvent:@"createroom" withData:myData];
    
    [self savePeerData];
}

//========================
// HANDSHAKE SOCKET.IO
//========================
- (void)handshake{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.dev_id forKey:@"dev_id"];
    [myData setValue:self.range forKey:@"range"];
    NSMutableDictionary* myLoc = [[NSMutableDictionary alloc] init];
    [myLoc setValue:[NSNumber numberWithDouble:self.latitude] forKey:@"lat"];
    [myLoc setValue:[NSNumber numberWithDouble:self.longitude] forKey:@"lng"];
    [myData setValue:myLoc forKey:@"loc"];
    [myData setValue:[NSNumber numberWithDouble:self.location.horizontalAccuracy] forKey:@"accu"];
    
    [socketIO sendEvent:@"peer" withData:myData];
}

// RESET PROCEDURES (called asynchronously)
// called when opened through the speakup://reset url
- (void)resetPeerID{
    [self savePeerData];
   // [self resetData];
}

//called by appdelegate
//- (void)resetData{
//    locationIsOK=NO;
//    [self.locationManager startUpdatingLocation];
//    //once the right location is retrieved, the reset process starts
//}

//target method is called every time the timer wakes up and queries the repository for matches
-(void) targetMethod: (NSTimer*) theTimer{
    // here we might want to get rooms or something else... not sure yet how and what
}

// DELIVER EVENTS
-(void)retrieveMatchesForSucceededWithResponse{
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
}


// RATE MESSAGE
//-------------
- (void)rateMessage:(NSString*)messageID inRoom:(NSString*)roomID  likes:(BOOL) liked dislkies:(BOOL) disliked{
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.peer_id forKey:@"peer_id"];
    NSMutableDictionary* messageDict = [[NSMutableDictionary alloc] init];
    [messageDict setValue:messageID forKey:@"msg_id"];
    [messageDict setValue:[NSNumber numberWithBool:liked] forKey:@"liked"];
    [messageDict setValue:[NSNumber numberWithBool:disliked] forKey:@"disliked"];
    [myData setValue:messageDict forKey:@"message"];
    
    [socketIO sendEvent:@"messageupdate" withData:myData];
    [self savePeerData];
}

//- (void)assignRatingToMessage:(NSString*)messageID inRoom:(NSString*)roomID byPeer:(NSString*)peerStringID  yesRating:(int)yesRating noRating:(int) noRating{
//    for(Room *room in roomArray){
//        if ([room.roomID isEqual:roomID]) {
//            for(Message *msg in room.messages){
//                if ([msg.messageID isEqual:messageID]) {
//                    NSNumber* peerRating = [msg.ratingPerPeer objectForKey:peerStringID];
//                    if(!peerRating){
//                        peerRating= [NSNumber numberWithInt:0];
//                    }
//                    int value = [peerRating intValue];
//                    if(yesRating ==1){
//                        value++;
//                    }
//                    if(yesRating ==-1){
//                        value--;
//                    }
//                    if(noRating ==1){
//                        value--;
//                    }
//                    if(noRating ==-1){
//                        value++;
//                    }
//                    peerRating = [NSNumber numberWithInt:value];
//                    [msg.ratingPerPeer setObject:peerRating forKey:peerStringID];
//                    //update the score for the message
//                    int numberOfYes=0;
//                    int numberOfNo=0;
//                    for(NSString* key in msg.ratingPerPeer) {
//                        NSNumber* ratingInNumber = [msg.ratingPerPeer objectForKey:key];
//                        int rating = [ratingInNumber intValue];
//                        if(rating==-1){
//                            numberOfNo++;
//                        }if (rating==1) {
//                            numberOfYes++;
//                        }if(rating*rating > 1){
//                            NSLog(@"something went wrong with the ratings a peer %@ has the following rating %d", key, rating);
//                        }
//                    }
//                    msg.numberOfNo=numberOfNo;
//                    msg.numberOfYes= numberOfYes;
//                    msg.score=msg.numberOfYes-msg.numberOfNo;
//                    [messageManagerDelegate updateMessages:room.messages inRoom: room];
//                }
//            }
//        }
//    }
//}

-(void) assignMessage:(Message *) message{
    for(Room *room in roomArray){
        if ([room.roomID isEqual:message.roomID]) {
            BOOL msgAlreadyInRoom = NO;
            for(Message *msg in room.messages){
                if ([msg.messageID isEqual:message.messageID]) {
                    msgAlreadyInRoom= YES;
                }
            }
            if (!msgAlreadyInRoom) {
                [room.messages addObject:message];
                [messageManagerDelegate updateMessages:room.messages inRoom: room];
            }
        }
    }
}
// DELETE ROOM
//------------
-(NSArray*) deleteRoom:(Room *) room{
    NSNumber* publicationID = [myRoomPublicationIDs objectForKey:room.roomID];
    if(publicationID){
        //        [event setStringProperty:@"eventType" to:@"deleteRoom"];
        //        [event setStringProperty:@"roomID" to:room.roomID];
        //        // create a publication to indicate that the message is not visible any longer
    }
    NSMutableArray* rooms = [[NSMutableArray alloc] initWithArray:roomArray];
    [rooms removeObject:room];
    roomArray=rooms;
    return roomArray;
}

// DELETE MESSAGE
//---------------
-(void) deleteMessage:(Message *) message{
    NSNumber* publicationID = [myMessagePublicationIDs objectForKey:message.messageID];
    if(publicationID){
        //        [event setStringProperty:@"eventType" to:@"deleteMessage"];
        //        [event setStringProperty:@"messageID" to:message.messageID];
        //        [event setStringProperty:@"roomID" to:message.roomID];
        // [self startNetworking];
    }
}

//============================
// LOCATION MANAGER CALLBACK
//============================
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    self.location = newLocation;
    self.latitude = newLocation.coordinate.latitude;
    self.longitude = newLocation.coordinate.longitude;
    
    if (!locationIsOK ){
        [sharedSpeakUpManager connect];
        [speakUpDelegate updateData];
        locationIsOK=YES;
    }
    
    //    BOOL reset = NO;
    //    self.location = newLocation;
    //    self.latitude = newLocation.coordinate.latitude;
    //    self.longitude = newLocation.coordinate.longitude;
    //    if([roomArray count]>0){
    //        for(Room *room in roomArray){
    //            CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[room latitude] longitude: [room longitude]];
    //            room.distance = [self.location distanceFromLocation:roomlocation];
    //            if (room.distance>250.0) {
    //                reset=YES;
    //            }
    //        }
    //        if(!reset){
    //            [roomManagerDelegate updateRooms:roomArray];
    //        }
    //    }
    //    if (!locationIsOK && oldLocation){
    //        double distance = [oldLocation distanceFromLocation:self.location];
    //        locationIsOK=YES;
    //        [speakUpDelegate updateData];
    //        if(distance>250.0){
    //            reset=YES;
    //        }
    //    }
    //    if (!locationAtLastReset ||  [self.locationAtLastReset distanceFromLocation:self.location] >250.0) {
    //        reset = YES;
    //    }
    //    if(reset){
    //        self.locationAtLastReset=self.location;
    //        locationIsOK=YES;
    //        [speakUpDelegate updateData];
    //        [messageManagerDelegate notifyThatLocationHasChangedSignificantly];
    //        // [self getNearbyRooms];
    //    }
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
    // ID of the device
    if  ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending){
        dev_id = [UIDevice currentDevice].identifierForVendor.UUIDString;
    }else{
        dev_id = [UIDevice currentDevice].uniqueIdentifier;
    }
    range=[NSNumber numberWithInt:500000000];
    
    sharedTopic=@"SpeakUp";
    subscriptionRadius=[NSNumber numberWithInt:0];
    publicationRadius=[NSNumber numberWithInt:200];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
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
    if([defaults objectForKey:@"myMessagePublicationIDs"]){
        myMessagePublicationIDs= [defaults objectForKey:@"myMessagePublicationIDs"];
    }else {
        myMessagePublicationIDs= [[NSMutableDictionary alloc] init];
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
    if([defaults objectForKey:@"myRoomPublicationIDs"]){
        myRoomPublicationIDs= [defaults objectForKey:@"myRoomPublicationIDs"];
    }else {
        myRoomPublicationIDs= [[NSMutableDictionary alloc] init];
    }
    if([defaults objectForKey:@"isSuperUser"]){
        NSNumber* booleanNumber;
        booleanNumber = [defaults objectForKey:@"isSuperUser"] ;
        isSuperUser = [booleanNumber boolValue];
    }else {
        isSuperUser= NO;
    }
    roomCounter = [NSNumber numberWithInt:[defaults integerForKey:@"roomCounter"]];
    messageCounter = [NSNumber numberWithInt:[defaults integerForKey:@"messageCounter"]];
    
    inputText=@"";
    sharedSpeakUpManager.locationAtLastReset = nil;
    sharedSpeakUpManager.location = nil;
    sharedSpeakUpManager.latitude = -1;
    sharedSpeakUpManager.longitude =-1;
}
-(void)savePeerData{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[roomCounter intValue] forKey:@"roomCounter"];
    [defaults setInteger:[messageCounter intValue] forKey:@"messageCounter"];
    [defaults setObject:likedMessages forKey:@"likedMessages"];
    [defaults setObject:dislikedMessages forKey:@"dislikedMessages"];
    [defaults setObject:myMessagePublicationIDs forKey:@"myMessagePublicationIDs"];
    [defaults setObject:myMessageIDs forKey:@"myMessageIDs"];
    [defaults setObject:myRoomIDs forKey:@"myRoomIDs"];
    [defaults setObject:myRoomPublicationIDs  forKey:@"myRoomPublicationIDs"];
    [defaults setObject:[NSNumber numberWithBool:self.isSuperUser] forKey:@"isSuperUser"];
    [defaults synchronize];
}

//========================
// UTILS
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
    // [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}
-(void)stopNetworking{
    //  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}
@end