//
//  Member.h
//  InterMix
//
//  Created by Adrian Holzer on 16.12.11.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//
#include <CommonCrypto/CommonDigest.h>
#import <Foundation/Foundation.h>
#import "Room.h"


@interface Message : NSObject

@property (strong, nonatomic) NSString* messageID;
@property (nonatomic)NSNumber  *  authorPeerID;
@property (strong, nonatomic) NSString* roomID;
@property (strong, nonatomic) Room  *room;

@property (strong, nonatomic) NSString  *content;
@property (strong, nonatomic) NSString  *creationTime;
@property (strong, nonatomic) NSString  *lastModified;
@property ( nonatomic) int secondsSinceCreation;
@property ( nonatomic) BOOL isVisible;


@property (strong, nonatomic) NSMutableArray  *peersWhoFlagged;

@property (strong, nonatomic) NSMutableDictionary  *ratingPerPeer;

@property ( nonatomic) int numberOfYes;
@property ( nonatomic) int numberOfNo;
@property ( nonatomic) int score;

@property (nonatomic) BOOL  yesIsPressed;
@property (nonatomic) BOOL  noIsPressed;

@property (strong, nonatomic) Request* publicationRequest;
@property (strong, nonatomic) Publication  *publication;
@property (strong, nonatomic) NSNumber  *publicationID;

@property (strong, nonatomic) Request* subscriptionRequest;
@property (strong, nonatomic) Subscription  *subscription;
@property (strong, nonatomic) NSNumber  *subscriptionID;






@end
