//
//  Message.h
//  Heya
//
//  Created by Adrian Holzer on 16.12.11.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//
#include <CommonCrypto/CommonDigest.h>
#import <Foundation/Foundation.h>
#import "Room.h"

@interface Message : NSObject<NSCoding>

- (id)initWithDictionary:(NSDictionary*) dict roomID:(NSString*) roomID;

@property (strong, nonatomic) NSString* messageID;
@property (strong, nonatomic) NSString* parentMessageID;
@property (strong, nonatomic) NSString* pseudo;
@property (nonatomic)NSString*  authorPeerID;
@property (strong, nonatomic) NSString* roomID;
@property (strong, nonatomic) Room  *room;
@property (strong, nonatomic) NSString  *avatarURL;
@property (strong, nonatomic) NSString  *content;
@property (strong, nonatomic) NSString  *creationTime;
@property (strong, nonatomic) NSString  *lastModified;
@property ( nonatomic) int secondsSinceCreation;
@property ( nonatomic) BOOL deleted;
@property ( nonatomic) int numberOfYes;
@property ( nonatomic) int numberOfNo;
@property ( nonatomic) int score;
@property ( nonatomic) double hotScore;
@property (nonatomic) BOOL  yesIsPressed;
@property (nonatomic) BOOL  noIsPressed;
@property (strong, nonatomic) NSMutableArray  *replies;

@end
