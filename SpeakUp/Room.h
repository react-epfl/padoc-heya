//
//  Room.h
//  SpeakUp
//
//  Created by Adrian Holzer on 02.04.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface Room : NSObject


- (id)initWithDictionary:(NSDictionary*) dict;

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





@end