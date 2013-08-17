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

@synthesize roomID, name, location, messages, distance, latitude, longitude, lifetime, range, isOfficial, deleted, messagesSortedBy, creatorID ;


- (id)init{
    self = [super init];
    if(self){
        messages = [NSMutableArray array];
        isOfficial=NO;
        messagesSortedBy=MOST_RECENT;
        deleted=NO;
    }
    return self;
}



- (id)initWithDictionary:(NSDictionary*) dict{
    self = [super init];
    if(self){
        messagesSortedBy=MOST_RECENT;
        [self setRoomID: [dict objectForKey:@"_id"]];
        [self setDeleted:[[dict objectForKey:@"deleted"] boolValue]];
        NSDictionary* loc = [dict objectForKey:@"loc"];
        [self setLatitude: [[loc objectForKey:@"lat"] doubleValue]];
        [self setLongitude: [[loc objectForKey:@"lng"] doubleValue]];
        [self setName: [[dict objectForKey:@"name"] lowercaseString]] ; // LOWER CASE
        [self setCreatorID: [dict objectForKey:@"creator_id"]];
        [self setIsOfficial:[[dict objectForKey:@"official"] boolValue]];
        CLLocation * peerlocation = [[SpeakUpManager sharedSpeakUpManager] location];
        CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[self latitude] longitude: [self longitude]];
        self.distance = [peerlocation distanceFromLocation:roomlocation];
        self.messages = [NSMutableArray array];
    }
    return self;
}



@end
