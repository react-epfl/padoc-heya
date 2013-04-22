//
//  sharedSpeakUpManager.m
//
//  Created by Adrian Holzer on 06.11.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "SpeakUpManager.h"

#define DURATION 43200 // a month in minutes

#define iWallMiddlewareUnknownPeerException  @"net.headfirst.iwall.UnknownPeerException"

@implementation SpeakUpManager

@synthesize matches, publicationRadius, peerID,subscriptionRadius, likedMessages, sharedTopic, timer, messageLifetime, roomLifetime, speakUpDelegate,dislikedMessages,myMessagePublicationIDs,myRoomIDs,inputText, isSuperUser, messageManagerDelegate, roomManagerDelegate, roomCounter, messageCounter, roomArray, locationIsOK, connectionIsOK,myRoomPublicationIDs, myMessageIDs, locationAtLastReset, myWebSocket;

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
            // connection to the middleware
            //sharedSpeakUpManager.matchRepository =  [[MatchRepository alloc] initWithRepositoryURI:@"http://isi02.unil.ch:8080/iWall-Middleware-TEST-Bridging/MatchRepository"];
            // sets up the local location manager, this triggers the didUpdateToLocation callback
            sharedSpeakUpManager.locationManager = [[CLLocationManager alloc] init];
            sharedSpeakUpManager.locationManager.delegate = sharedSpeakUpManager;
            sharedSpeakUpManager.locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
            sharedSpeakUpManager.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
            
            
            [sharedSpeakUpManager reconnect];
            
        }
    }
    return sharedSpeakUpManager;
}

// WS did receive a message
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
    NSLog(@"webSocket received a message: %@", [message description]);
    
    
    NSError* error;
    NSData *jsonData = [[message description] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];//breaks
    NSLog(@"JSON DIct: %@", json);
    
    NSString* type = [json objectForKey:@"type"];
    if ([type isEqual:@"rooms"]) {
         NSLog(@"got rooms");
        NSArray *rooms = [json objectForKey:@"data"];
        for (NSDictionary *roomData in rooms) {
           [self processReceivedRoom:[[Room alloc] initWithDictionary:roomData]];
        }
    } else if ([type isEqual:@"room"]) {
        NSLog(@"got a room");
        [self processReceivedRoom:[[Room alloc] initWithDictionary:json]];
    } else if ([type isEqual:@"messages"]) {
        NSLog(@"got messages");
    } else if ([type isEqual:@"message"]) {
        NSLog(@"got a message");
    }else{
        NSLog(@"got something else");
    }
}

-(void)processReceivedRoom:(Room*)room{
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

// WS connection
- (void)reconnect;
{
    myWebSocket.delegate = nil;
    [myWebSocket close];
    myWebSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"ws://localhost:1337"]]];
    myWebSocket.delegate = self;
    [myWebSocket open];
}

// WS call to get nearby rooms
-(void)getNearbyRooms{
    
    NSMutableDictionary* myDict = [[NSMutableDictionary alloc] init];
    [myDict setValue:@"peer" forKey:@"type"];
    
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    [myData setValue:self.peerID forKey:@"id"];
    [myData setValue:[NSNumber numberWithDouble:self.latitude] forKey:@"lat"];
    [myData setValue:[NSNumber numberWithDouble:self.longitude] forKey:@"lng"];
    [myData setValue:[NSNumber numberWithDouble:self.location.horizontalAccuracy] forKey:@"accu"];
    [myData setValue:[NSNumber numberWithDouble:2000000.0] forKey:@"range"];
    [myDict setValue:myData forKey:@"data"];
    
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:myDict options:kNilOptions error:nil];
    NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [myWebSocket send:jsonString];
    NSLog(@"getNearbyRooms sends: %@", jsonString);
}


// WS call to create a new message
-(void) createMessage:(Message *) message{
    NSMutableDictionary* myDict = [[NSMutableDictionary alloc] init];
    [myDict setValue:@"createmessage" forKey:@"type"];
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    
    
    
    [myData setValue:self.peerID forKey:@"id"];
    [myData setValue:message.content forKey:@"message_content"];
    [myData setValue:message.roomID forKey:@"room_id"];
    [myDict setValue:myData forKey:@"data"];
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:myDict options:kNilOptions error:nil];
    [myWebSocket send:jsonData];
    NSLog(@"createMessage sends %@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    [myMessageIDs addObject:message.messageID];
    [self savePeerData];
    [self assignMessage:message];
}



// CREATE ROOMS
//-------------
- (void)createRoom:(Room *)room{    
    NSMutableDictionary* myDict = [[NSMutableDictionary alloc] init];
    [myDict setValue:@"createroom" forKey:@"type"];
    NSMutableDictionary* myData = [[NSMutableDictionary alloc] init];
    
    [myData setValue:self.peerID forKey:@"creator_id"];
    [myData setValue:room.name forKey:@"name"];
    [myData setValue:[NSNumber numberWithDouble:self.latitude] forKey:@"lat"];
    [myData setValue:[NSNumber numberWithDouble:self.longitude] forKey:@"lng"];
    [myData setValue:[NSNumber numberWithDouble:self.location.horizontalAccuracy] forKey:@"accu"];
    [myDict setValue:myData forKey:@"data"];
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:myDict options:kNilOptions error:nil];
    NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [myWebSocket send:jsonString];
    NSLog(@"createroom sends %@", jsonString);

    [self savePeerData];
}


































// RESET PROCEDURES (called asynchronously)
// called when opened through the speakup://reset url
- (void)resetPeerID{
    [self savePeerData];
    [self resetData];
}

//called by appdelegate
- (void)resetData{
    locationIsOK=NO;
    [self.locationManager startUpdatingLocation];
    //once the right location is retrieved, the reset process starts
}
// called when a correct location is found
//-(void)resetProcedureStepOne{
//    NSLog(@"resetData Step 1");
//    // clear roomArray
//    roomArray= [[NSMutableArray alloc] init];// initializes the room array, containing all nearby rooms
//    [roomManagerDelegate updateRooms:[NSArray arrayWithArray:roomArray]]; // notify the room table view controller
//    // open session
//    if([peerID intValue]>0){
//        NSLog(@"openSession is called for peer ID: %d", [peerID intValue] );
//       // [me openSession:[sharedSpeakUpManager.peerID intValue] delegate:self];
//    }else{
//        NSLog(@"openSessionAndCreatePeer is called");
//       // [me openSessionAndCreatePeer:@"SpeakUp" delegate:self];
//    }
//    [speakUpDelegate updateData];
//}
// called when a session is opened successfully
//-(void)resetProcedureStepTwo{
//    NSLog(@"resetData Step 2");
//    roomArray= [[NSMutableArray alloc] init];// initializes the room array, containing all nearby rooms
//    [roomManagerDelegate updateRooms:[NSArray arrayWithArray:roomArray]]; // notify the room table view controller
//    connectionIsOK=YES;
//    [speakUpDelegate updateData];
//    //[sharedSpeakUpManager.me setUpdateLocationMode:NORMAL_MODE];
//    NSLog(@"calling getAllSubscriptions");
//    //[me getAllSubscriptions:self];
//    [self startNetworking];
//}
// called when getAllSubscriptions returns successfully
//-(void)resetProcedureStepThree{
//    NSLog(@"resetData Step 3");
//    //unsubscribe to all subscriptions
//    //for (Subscription* sub in response.allSubscriptions) {
//      //  [me unsubscribe:sub.ID delegate:self];
//    //}
//    [[SpeakUpManager sharedSpeakUpManager] subscribeToNearbyRooms];
//    //subscribe to all rooms currently around (this is a one shot subscription, it could also be longer)
//
//    // start timer that will query the repo
//    sharedSpeakUpManager.timer = [NSTimer scheduledTimerWithTimeInterval: 5.0 target:sharedSpeakUpManager selector:@selector(targetMethod:) userInfo:nil repeats: YES];
//    [self startNetworking];
//    [speakUpDelegate updateData];
//}







// RESET PROCEDURES END

//target method is called every time the timer wakes up and queries the repository for matches
-(void) targetMethod: (NSTimer*) theTimer{
    // NSLog(@"timer ticks");
    // if ([roomArray count] ==0) {
    //   [self subscribeToNearbyRooms];
    //}
    
    // if the list of rooms is empty, then res
    //    if([peerID intValue]>0){
    //        [matchRepository retrieveMatchesFor:(NSNumber*)peerID delegate:self];
    //    }
}

// DELIVER EVENTS
-(void)retrieveMatchesForSucceededWithResponse{
    //    if ([response.latestMatches count] > 0) {
    //        [matches addObjectsFromArray:response.latestMatches];
    //        NSLog(@"Received %d new matches from the repo, now we have %d matches",[response.latestMatches count], [matches count]);
    //    }
    //    for(Match* match in response.latestMatches){
    //        NSString* eventType = [match.event getStringProperty:@"eventType"];
    //        // NEW ROOM RECEIVED
    //        if([eventType isEqual:@"room"]){
    //            Room* newRoom = [[Room alloc] init];
    //            [newRoom setRoomID: [match.event getStringProperty:@"roomID"]];
    //            [newRoom setLatitude: [[match.event getDoubleProperty:@"roomLatitude"] doubleValue]];
    //            [newRoom setLongitude: [[match.event getDoubleProperty:@"roomLongitude"] doubleValue]];
    //            [newRoom setName: [match.event getStringProperty:@"roomName"]];
    //            [newRoom setIsOfficial:[[match.event getBooleanProperty:@"isOfficial"] boolValue]];
    //            CLLocation * peerlocation = self.location;
    //            CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[newRoom latitude] longitude: [newRoom longitude]];
    //            newRoom.distance = [peerlocation distanceFromLocation:roomlocation];
    //            BOOL roomAlreadyInArray = NO;
    //            for(Room *room in roomArray){
    //                if ([room.roomID isEqual:newRoom.roomID]) {
    //                    roomAlreadyInArray= YES;
    //                }
    //            }
    //            if (!roomAlreadyInArray) {
    //                [roomArray addObject:newRoom];
    //                roomArray = [[self sortArrayByDistance:roomArray] mutableCopy];
    //                //if (!newRoom.subscriptionRequest) {
    //                   // [[SpeakUpManager sharedSpeakUpManager] subscribeToAllMessagesInRoom:newRoom.roomID];
    //               // }
    //                [roomManagerDelegate updateRooms:[NSArray arrayWithArray:roomArray]];
    //            }
    //            // NEW MESSAGE RECEIVED
    //        } else if([eventType isEqual:@"message"]){
    //            Message* newMessage = [[Message alloc] init];
    //            [newMessage setContent: [match.event getStringProperty:@"content"]];
    //            [newMessage setRoomID: [match.event getStringProperty:@"roomID" ]];
    //            [newMessage setLastModified: [match.event getStringProperty:@"content"]];
    //            [newMessage setMessageID: [match.event getStringProperty:@"messageID"]];
    //            [newMessage setCreationTime: [match.event getStringProperty:@"creationTime"]];
    //            NSLog(@"RECEIVED NEW MESSAGE: %@, IN ROOM %@", newMessage.content, newMessage.roomID);
    //            [self assignMessage:newMessage];
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




// SUBSCRIBE TO MESSAGES IN A ROOM
//---------------------------------
- (void)subscribeToAllMessagesInRoom:(NSString*)roomID{
    // here we might want to unsubscribe to
    for(Room *room in roomArray){
        //        if ([roomID isEqual:room.roomID] && room.subscriptionID==nil) {
        //            NSString* roomSelector = [NSString stringWithFormat:@"eventType LIKE 'message' AND roomID LIKE '%@'",roomID];
        //           // Request *subscriptionRequest = [me subscribe:roomSelector onTopic:sharedTopic inRange:[subscriptionRadius doubleValue] isOutward:NO  forDuration:eternity isMobile:NO delegate:self];
        //            [self startNetworking];
        //            //room.subscriptionRequest=subscriptionRequest;
        //            // also subscribe to deletedRoom
        //            NSString* deleteRoomSelector = [NSString stringWithFormat:@"eventType LIKE 'deleteRoom' AND roomID LIKE '%@'",roomID];
        // [me subscribe:deleteRoomSelector onTopic:sharedTopic inRange:[subscriptionRadius doubleValue] isOutward:NO  forDuration:eternity isMobile:NO delegate:self];
        //        }
    }
}

// SUBSCRIBE TO MESSAGE RATINGS OF MESSAGE MSGID IN ROOM
//---------------------------------
- (void)subscribeToInfoOfMessage: (NSString*)messageID inRoom:(NSString*)roomID{
    // here we might want to unsubscribe to
    for(Room *room in roomArray){
        if ([roomID isEqual:room.roomID]) {
            for(Message *message in room.messages){
                // if ([messageID isEqual:message.messageID] && message.subscriptionID==nil) {
                //   NSString* selector = [NSString stringWithFormat:@"eventType LIKE 'messageRating' AND messageID LIKE '%@'",messageID];
                //Request *subscriptionRequest = [me subscribe:selector onTopic:sharedTopic inRange:[subscriptionRadius doubleValue] isOutward:NO  forDuration:eternity isMobile:NO delegate:self];
                // [self startNetworking];
                // message.subscriptionRequest=subscriptionRequest;
                // also subscribe to deletedMessage
                // NSString* deleteMessageSelector = [NSString stringWithFormat:@"eventType LIKE 'deleteMessage' AND messageID LIKE '%@'",messageID];
                //  [me subscribe:deleteMessageSelector onTopic:sharedTopic inRange:[subscriptionRadius doubleValue] isOutward:NO  forDuration:eternity isMobile:NO delegate:self];
                //}
            }
        }
    }
}

// RATE MESSAGE
//-------------
- (void)rateMessage:(NSString*)messageID inRoom:(NSString*)roomID  yesRating:(int) yesRating noRating:(int) noRating{
    //    Event *event = [[Event alloc] init];
    //    [event setStringProperty:@"eventType" to:@"messageRating"];
    //    [event setStringProperty:@"messageID" to:messageID];
    //    [event setStringProperty:@"roomID" to:roomID];
    //    [event setStringProperty:@"peerID" to:[NSString stringWithFormat:@"peer%d",[peerID intValue]]];
    //    [event setIntProperty:@"yesRating" to:yesRating];
    //    [event setIntProperty:@"noRating" to:noRating];
    // create a publication that represents a rating of a message
    //[me publish:event onTopic:sharedTopic inRange:[publicationRadius doubleValue] isOutward:NO forDuration:DURATION isMobile:NO  delegate:self];
    [self startNetworking];
}

- (void)assignRatingToMessage:(NSString*)messageID inRoom:(NSString*)roomID byPeer:(NSString*)peerStringID  yesRating:(int)yesRating noRating:(int) noRating{
    for(Room *room in roomArray){
        if ([room.roomID isEqual:roomID]) {
            for(Message *msg in room.messages){
                if ([msg.messageID isEqual:messageID]) {
                    NSNumber* peerRating = [msg.ratingPerPeer objectForKey:peerStringID];
                    if(!peerRating){
                        peerRating= [NSNumber numberWithInt:0];
                    }
                    int value = [peerRating intValue];
                    if(yesRating ==1){
                        value++;
                    }
                    if(yesRating ==-1){
                        value--;
                    }
                    if(noRating ==1){
                        value--;
                    }
                    if(noRating ==-1){
                        value++;
                    }
                    peerRating = [NSNumber numberWithInt:value];
                    [msg.ratingPerPeer setObject:peerRating forKey:peerStringID];
                    //update the score for the message
                    int numberOfYes=0;
                    int numberOfNo=0;
                    for(NSString* key in msg.ratingPerPeer) {
                        NSNumber* ratingInNumber = [msg.ratingPerPeer objectForKey:key];
                        int rating = [ratingInNumber intValue];
                        if(rating==-1){
                            numberOfNo++;
                        }if (rating==1) {
                            numberOfYes++;
                        }if(rating*rating > 1){
                            NSLog(@"something went wrong with the ratings a peer %@ has the following rating %d", key, rating);
                        }
                    }
                    msg.numberOfNo=numberOfNo;
                    msg.numberOfYes= numberOfYes;
                    msg.score=msg.numberOfYes-msg.numberOfNo;
                    [messageManagerDelegate updateMessages:room.messages inRoom: room];
                }
            }
        }
    }
}



// CREATE MESSAGE
//---------------


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
                //[self subscribeToInfoOfMessage: message.messageID inRoom:room.roomID]; // SUBSCRIBE TO INFO OF MESSAGE
                [messageManagerDelegate updateMessages:room.messages inRoom: room];
            }
        }
    }
}




// DELETE ROOM
//------------
-(NSArray*) deleteRoom:(Room *) room{
    //do something about unsubscription
    
    NSNumber* publicationID = [myRoomPublicationIDs objectForKey:room.roomID];
    if(publicationID){
        //        Event *event = [[Event alloc] init];
        //        [event setStringProperty:@"eventType" to:@"deleteRoom"];
        //        [event setStringProperty:@"roomID" to:room.roomID];
        //        // create a publication to indicate that the message is not visible any longer
        //        //[me publish:event onTopic:sharedTopic inRange:[publicationRadius doubleValue] isOutward:NO forDuration:DURATION isMobile:NO  delegate:self];
        //        //[me unpublish:publicationID delegate:self];
        //        [self startNetworking];
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
        //        Event *event = [[Event alloc] init];
        //        [event setStringProperty:@"eventType" to:@"deleteMessage"];
        //        [event setStringProperty:@"messageID" to:message.messageID];
        //        [event setStringProperty:@"roomID" to:message.roomID];
        // create a publication to indicate that the message is not visible any longer
        //[me publish:event onTopic:sharedTopic inRange:[publicationRadius doubleValue] isOutward:NO forDuration:DURATION isMobile:NO  delegate:self];
        // unpublish the message
        //[me unpublish:publicationID delegate:self];
        [self startNetworking];
    }
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
// CALLBACKS
//-----------
//required methods from MobilePeerDelegate
//-(void)invocationFailedWithError:(NSError*)error forRequest:(Request*)request{
//    NSLog(@"adrian: invocationFailedWithError");
//    NSLog(@"Error %@ from request %@", [error description], [request description]);
//    if ([request.operation isEqualToString:openSessionOperation] &&
//        [error.iWallResponse.exception isEqualToString:iWallMiddlewareUnknownPeerException]) {
//        NSLog(@"adrian: we experienced an iWallMiddlewareUnknownPeerException, lets reopen a sesison and create a peer");
//        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"peerID"];
//        [self createMobilePeer];
//        NSLog(@"adrian: about to call openSessionAndCreatePeer");
////        [me openSessionAndCreatePeer:@"SpeakUp" delegate:self];
//    }else if ([request.operation isEqualToString:openSessionOperation]){
//        sleep(5);
//        NSLog(@"openSession is called for peer ID: %d", [peerID intValue] );
////        [me openSession:[sharedSpeakUpManager.peerID intValue] delegate:self];
//    }
//}
////optional methods from MobilePeerDelegate
//-(void)openSessionSucceededWithResponse:(Response*)response forRequest:(Request*)request{
//    NSLog(@"openSucceededWithResponse - Response %@ from request %@", [response description], [request description]);
//    [self resetProcedureStepTwo];
//    [self stopNetworking];
//}
//-(void)openSessionAndCreatePeerSucceededWithResponse:(Response*)response forRequest:(Request*)request{
//    NSLog(@"openSessionAndCreatePeerSucceededWithResponse - Response %@ from request %@", [response description], [request description]);
//    peerID= [response peerID];
//    [self savePeerData];
//    [self resetProcedureStepTwo];
//    [self stopNetworking];
//}
//-(void)publishSucceededWithResponse:(Response*)response forRequest:(Request*)request{
//    NSLog(@"Publish succeeded - Response %@ from request %@", [response description], [request description]);
//    [self stopNetworking];
//    if([[request.event getStringProperty:@"eventType"] isEqual:@"room"] && [myRoomIDs containsObject:[request.event getStringProperty:@"roomID"]]){
//        [myRoomPublicationIDs setValue:[response publicationID] forKey:[request.event getStringProperty:@"roomID"]];
//    }
//    if([[request.event getStringProperty:@"eventType"] isEqual:@"message"] && [myMessageIDs containsObject:[request.event getStringProperty:@"messageID"]]){
//        [myMessagePublicationIDs setValue:[response publicationID] forKey:[request.event getStringProperty:@"messageID"]];
//    }
//
//}
//-(void)unpublishSucceededWithResponse:(Response*)response forRequest:(Request*)request{
//    NSLog(@"unpublish succeeded - Response %@ from request %@", [response description], [request description]);
//    [self stopNetworking];
//}
//-(void)subscribeSucceededWithResponse:(Response*)response forRequest:(Request*)request{
//    NSLog(@"Subscription succeeded - Response %@ from request %@", [response description], [request description]);
//    // assigns the subscriptionID to the room
//    for(Room *room in roomArray){
//        if ([request isEqual:room.subscriptionRequest]) {
//            room.subscriptionID = [response subscriptionID];
//        }
//        for(Message *message in room.messages){
//            if ([request isEqual:message.subscriptionRequest]) {
//                message.subscriptionID = [response subscriptionID];
//            }
//        }
//    }
//    [self stopNetworking];
//}
//-(void)unsubscribeSucceededWithResponse:(Response*)response forRequest:(Request*)request{
//    NSLog(@"Unsubscription succeeded - Response %@ from request %@", [response description], [request description]);
//    [self stopNetworking];
//}
//-(void)updateLocationSucceededWithResponse:(Response*)response forRequest:(Request*)request{
//    NSLog(@"Response %@ from request %@", [response description], [request description]);
//    [self stopNetworking];
//}
//-(void)getAllSubscriptionsSucceededWithResponse:(Response*)response forRequest:(Request*)request{
//    NSLog(@"Response %@ from request %@", [response description], [request description]);
//    [self resetProcedureStepThree:response];  // used to unsubscribe all pending subscriptions
//}


// METHODS RELATED TO LOCATION
//----------------------------
// location succeeded
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    
    BOOL reset = NO;
    self.location = newLocation;
    self.latitude = newLocation.coordinate.latitude;
    self.longitude = newLocation.coordinate.longitude;
    
    if([roomArray count]>0){
        for(Room *room in roomArray){
            CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[room latitude] longitude: [room longitude]];
            room.distance = [self.location distanceFromLocation:roomlocation];
            if (room.distance>250.0) {
                reset=YES;
            }
        }
        if(!reset){
            [roomManagerDelegate updateRooms:roomArray];
        }
    }
    
    
    if (!locationIsOK && oldLocation){
        double distance = [oldLocation distanceFromLocation:self.location];
        locationIsOK=YES;
        [speakUpDelegate updateData];
        if(distance>250.0){
            reset=YES;
        }
    }
    
    if (!locationAtLastReset ||  [self.locationAtLastReset distanceFromLocation:self.location] >250.0) {
        reset = YES;
    }
    
    if(reset){
        self.locationAtLastReset=self.location;
        locationIsOK=YES;
        [speakUpDelegate updateData];
        [messageManagerDelegate notifyThatLocationHasChangedSignificantly];
       // [self getNearbyRooms];
    }
}
// location failed
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    self.latitude=-1;
    self.longitude=-1;
}
// METHODS RELATED TO SAVING AND INITIALIZING DATA
//------------------------------------------------
-(void)initPeerData{
    // ID of the device
    if  ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending){
        peerID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    }else{
        peerID = [UIDevice currentDevice].uniqueIdentifier;
    }
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
// Get Unique room and message IDs
-(int)getNextMessageNumber{
    int value = [self.messageCounter intValue];
    self.messageCounter = [NSNumber numberWithInt:value + 1];
    [self savePeerData];
    return [self.messageCounter intValue];
}

-(int)getNextRoomNumber{
    int value = [self.roomCounter intValue];
    self.roomCounter = [NSNumber numberWithInt:value + 1];
    [self savePeerData];
    return [self.roomCounter intValue];
}

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

@end