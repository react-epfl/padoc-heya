//
//  SpeakUpManager.h
//  SpeakUp
//
//  Created by Adrian Holzer on 06.11.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"
#import "Room.h"
#import "SpeakUpManagerDelegate.h"
#import "MessageManagerDelegate.h"
#import "RoomManagerDelegate.h"
// socket rocket removed #import "SRWebSocket.h"
#import "SocketIO.h"

#define BOOLEAN  @"BOOLEAN"
#define STRING   @"STRING"
#define BYTE     @"BYTE"
#define SHORT    @"SHORT"
#define INT      @"INT"
#define LONG     @"LONG"
#define FLOAT    @"FLOAT"
#define DOUBLE   @"DOUBLE"

// socket rocket removed @interface SpeakUpManager : NSObject <CLLocationManagerDelegate, SRWebSocketDelegate>
@interface SpeakUpManager : NSObject <CLLocationManagerDelegate, SocketIODelegate>

+(id) sharedSpeakUpManager;




// PEER RELATED METHODS
-(void)savePeerData;

- (void)getNearbyRooms;

// MESSAGE RELATED METHODS
-(void) deleteMessage:(Message *) message;
-(void)createMessage:(Message *) message;
- (void)getMessagesInRoom:(NSString*)roomID;
//- (void)rateMessage:(NSString*)messageID inRoom:(NSString*)roomID  likes:(BOOL) liked dislikes:(BOOL) disliked;
- (void)rateMessage:(NSString*)messageID inRoom:(NSString*)roomID  yesRating:(int) yesRating noRating:(int) noRating;
// ROOM RELATED METHODS
-(NSArray*) deleteRoom:(Room *) room;
- (void)createRoom:(Room *)room;


@property (strong, nonatomic)  SocketIO *socketIO;



@property (nonatomic) BOOL connectionIsOK;
@property (nonatomic) BOOL locationIsOK;

// Peer fields
@property (strong, nonatomic)  CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation* locationAtLastReset;
@property (strong, nonatomic) CLLocation* location;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
// a superUser can create an unlimited number of official rooms
// a superUser is created by typing Warsoftheworldviews when creating a new room 
@property (nonatomic) BOOL isSuperUser;
// inputText is the user's unsent message 
@property (strong, nonatomic) NSString *inputText;
// likedMessages contains the id (NSNumber)  of the user's liked messages
@property (strong, nonatomic) NSMutableArray *likedMessages;
// dislikedMessages contains the id (NSNumber)  of the user's disliked messages
@property (strong, nonatomic) NSMutableArray *dislikedMessages;
// myMessages contains the id (NSNumber)  of the user's messages
@property (strong, nonatomic) NSMutableArray *myMessageIDs;
// myRoomIDs contains the id (NSNumber) of the user's rooms
@property (strong, nonatomic) NSMutableArray *myRoomIDs;


// roomArray is the main data element, it contains nearby room objects, which contain messages and ratings
@property (strong, nonatomic) NSMutableArray *roomArray;

// Fields used to communicate with the middleware
@property (nonatomic)  NSString  *dev_id;//device ID
@property (nonatomic)  NSString  *peer_id;// peer ID recieved from the server


@property (nonatomic,strong) NSNumber* range;


//Delegates
@property (strong, nonatomic) id<RoomManagerDelegate> roomManagerDelegate;
@property (strong, nonatomic) id<MessageManagerDelegate> messageManagerDelegate;
@property (strong, nonatomic) id<SpeakUpManagerDelegate> speakUpDelegate;

// repo where matches are stored







@end
