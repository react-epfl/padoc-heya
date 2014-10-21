//
//  SpeakUpManager.h
//  SpeakUp
//
//  Created by Adrian Holzer on 06.11.12.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"
#import "Room.h"
#import "SpeakUpManagerDelegate.h"
#import "MessageManagerDelegate.h"
#import "RoomManagerDelegate.h"
#import "ConnectionDelegate.h"
// socket rocket removed #import "SRWebSocket.h"
#import "SocketIO.h"

//#define SERVER_URL @"localhost"
#define SERVER_URL @"seance.epfl.ch"
#define SERVER_PORT 80
#define RANGE 200 
#define CREATE_TAB 1
#define UNLOCK_TAB 0

#define API_VERSION @"1"

#define ANONYMOUS @"anon" 
#define AVATAR @"avatar"

#define myPurple [UIColor colorWithRed:80.0/255.0 green:80.0/255.0 blue:210.0/255.0 alpha:1.0]
#define myGreen [UIColor colorWithRed:0.0/255.0 green:205.0/255.0 blue:0.0/255.0 alpha:1.0]
#define myGrey [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0]
#define NormalFontSize 22
#define MediumFontSize 18
#define SmallFontSize 13

#define THUMB @"THUMB"
#define PLUS @"PLUS"
#define ARROW @"ARROW"
#define ETIQUETTE @"ETIQUETTE"
#define NO_ETIQUETTE @"NO_ETIQUETTE"


#define IS_OS_7_OR_LATER   ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)


// socket rocket removed @interface SpeakUpManager : NSObject <CLLocationManagerDelegate, SRWebSocketDelegate>
@interface SpeakUpManager : NSObject <CLLocationManagerDelegate, SocketIODelegate>

+(id) sharedSpeakUpManager;


-(void)savePeerData;
- (void)getNearbyRooms;
-(void) deleteMessage:(Message *) message;
-(void) markMessageAsSpam:(Message *) message;
-(void)createMessage:(Message *) message;
- (void)getMessagesInRoomID:(NSString*)roomID orRoomHash:(NSString*) hash;
-(void) getMessagesInRoomID:(NSString*)room_id  orRoomHash:(NSString*) key withHandler:(void (^)(NSDictionary*))handler;
- (void)rateMessage:(NSString*)messageID inRoom:(NSString*)roomID  yesRating:(int) yesRating noRating:(int) noRating;
-(void) deleteRoom:(Room *) room;
- (void)createRoom:(Room *)room;
- (void)connect;

@property (strong, nonatomic)  SocketIO *socketIO;
@property (nonatomic) BOOL connectionIsOK;
@property (nonatomic) BOOL locationIsOK;
// Peer fields
@property (strong, nonatomic)  CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation* locationAtLastReset;
@property (strong, nonatomic) CLLocation* peerLocation;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
// a superUser can create an unlimited number of official rooms
// a superUser is created by typing Warsoftheworldviews when creating a new room 
@property (nonatomic) BOOL isSuperUser;
// inputText is the user's unsent message 
@property (strong, nonatomic) NSString *inputText;
@property (strong, nonatomic) NSString *inputRoomIDText;
// likedMessages contains the id (NSNumber)  of the user's liked messages
@property (strong, nonatomic) NSMutableArray *likedMessages;
// dislikedMessages contains the id (NSNumber)  of the user's disliked messages
@property (strong, nonatomic) NSMutableArray *dislikedMessages;
@property (strong, nonatomic) NSString *currentRoomID;
@property (strong, nonatomic) Room *currentRoom;//returns the room matching the currentRoomID
// contains the message ids that were deleted
@property (strong, nonatomic) NSMutableArray *deletedMessageIDs;
// contains the message ids that were deleted
@property (strong, nonatomic) NSMutableArray *deletedRoomIDs;
// roomArray is the main data element, it contains nearby room objects, which contain messages and ratings
@property (strong, nonatomic) NSMutableArray *roomArray;//nearbyRooms
@property (strong, nonatomic) NSMutableArray *unlockedRoomArray; // contains all unlocked rooms
@property (strong, nonatomic) NSMutableArray *unlockedRoomKeyArray; // contains all unlocked rooms
@property (strong, nonatomic) NSCache* avatarCacheByPeerID;
// Fields used to communicate with the middleware
@property (nonatomic)  NSString  *dev_id;//device ID
@property (nonatomic)  NSString  *peer_id;// peer ID recieved from the server
@property (strong, nonatomic) id<ConnectionDelegate> connectionDelegate;
@property (strong, nonatomic) id<RoomManagerDelegate> roomManagerDelegate;
@property (strong, nonatomic) id<MessageManagerDelegate> messageManagerDelegate;
@property (strong, nonatomic) id<SpeakUpManagerDelegate> speakUpDelegate;
@property (nonatomic)  NSString  *likeType;//type of like buttons (e.g. THUMB, PLUS, ARROW)
@property (nonatomic)  NSString  *etiquetteType;//type of etiquette (e.g. ETIQUETTE, NO_ETIQUETTE)
@property (nonatomic)  BOOL  *etiquetteWasShown;


@end
