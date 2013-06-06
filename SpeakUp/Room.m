//
//  Room.m
//  SpeakUp
//
//  Created by Adrian Holzer on 02.04.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "Room.h"
#import "SpeakUpManager.h"

@implementation Room

@synthesize roomID, name, location, messages, distance, latitude, longitude, lifetime, range, isOfficial, isVisible, messagesSortedBy ;


- (id)init{
    self = [super init];
    if(self){
        messages = [NSMutableArray array];
        isOfficial=NO;
        messagesSortedBy=BEST_RATING;
    }
    return self;
}



- (id)initWithDictionary:(NSDictionary*) dict{
    self = [super init];
    if(self){
        messagesSortedBy=BEST_RATING;
        [self setRoomID: [dict objectForKey:@"_id"]];
        NSDictionary* loc = [dict objectForKey:@"loc"];
        [self setLatitude: [[loc objectForKey:@"lat"] doubleValue]];
        [self setLongitude: [[loc objectForKey:@"lng"] doubleValue]];
        [self setName: [dict objectForKey:@"name"]];
        [self setIsOfficial:[[dict objectForKey:@"official"] boolValue]];
        CLLocation * peerlocation = [[SpeakUpManager sharedSpeakUpManager] location];
        CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[self latitude] longitude: [self longitude]];
        self.distance = [peerlocation distanceFromLocation:roomlocation];
        self.messages = [NSMutableArray array];
    }
    return self;
}



@end
