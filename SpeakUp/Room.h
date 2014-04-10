//
//  Room.h
//  SpeakUp
//
//  Created by Adrian Holzer on 02.04.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#define ANON 

@interface Room : NSObject


- (id)initWithDictionary:(NSDictionary*) dict;

@property (strong, nonatomic) NSString* roomID;
@property (strong, nonatomic) NSString* creatorID;
@property (nonatomic) float distance;
@property (strong, nonatomic) NSString  *name;
@property (strong, nonatomic) NSString* key;
@property (strong, nonatomic) CLLocation  *location;
@property (nonatomic) double  latitude;
@property (nonatomic) double  longitude;
@property (nonatomic) int  lifetime;
@property (nonatomic) int  range;
@property (nonatomic) BOOL  isOfficial;
@property (nonatomic) BOOL  isUnlocked;
@property (nonatomic, strong) NSString* id_type;// "ANONYMOUS" or "AVATAR"
@property ( nonatomic) BOOL deleted;
@property ( nonatomic) int messagesSortedBy;
@property (strong, nonatomic) NSCache* avatarCacheByPeerID;

@property (strong, nonatomic) NSString  *lastUpdateTime;

@property (strong, nonatomic) NSMutableArray  *messages;





@end
