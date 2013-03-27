//
//  Room.h
//  SpeakUp
//
//  Created by Adrian Holzer on 02.04.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import <iWall/iWall.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface Room : NSObject

@property (strong, nonatomic) NSString* roomID;
@property (nonatomic) float distance;
@property (strong, nonatomic) NSString  *name;
@property (strong, nonatomic) CLLocation  *location;
@property (nonatomic) double  latitude;
@property (nonatomic) double  longitude;
@property (nonatomic) int  lifetime;
@property (nonatomic) int  range;
@property (nonatomic) BOOL  isOfficial;
@property ( nonatomic) BOOL isVisible;

@property (strong, nonatomic) NSMutableArray  *messages;


@property (strong, nonatomic) Request* subscriptionRequest;
@property (strong, nonatomic) Subscription  *subscription;

@property (strong, nonatomic) NSNumber  *subscriptionID;

@property (strong, nonatomic) Request* publicationRequest;
@property (strong, nonatomic) NSNumber  *publicationID;



@end
