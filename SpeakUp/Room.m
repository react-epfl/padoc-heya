//
//  Room.m
//  SpeakUp
//
//  Created by Adrian Holzer on 02.04.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "Room.h"

@implementation Room

@synthesize roomID, name, location, messages, distance, latitude, longitude, lifetime, range, isOfficial, subscriptionID, subscription, subscriptionRequest, publicationID;


- (id)init{
    self = [super init];
    if(self){
        subscription=nil;
        subscriptionID=nil;
        publicationID=nil;
        messages = [NSMutableArray array];
        isOfficial=NO;
    }
    return self;
}



@end
