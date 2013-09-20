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

@synthesize roomID, name, location, messages,avatarCacheByPeerID, distance, latitude, longitude, lifetime, range, isOfficial, deleted, messagesSortedBy, creatorID,key, usesPseudonyms, isUnlocked ;


- (id)init{
    self = [super init];
    if(self){
        messages = [NSMutableArray array];
        isOfficial=NO;
        messagesSortedBy=MOST_RECENT;
        deleted=NO;
        isUnlocked=NO;
    }
    return self;
}



- (id)initWithDictionary:(NSDictionary*) dict{
    self = [super init];
    if(self){
        avatarCacheByPeerID = [[NSCache alloc] init];
        messagesSortedBy=MOST_RECENT;
        [self setRoomID: [dict objectForKey:@"room_id"]];
        [self setDeleted:[[dict objectForKey:@"deleted"] boolValue]];
        NSDictionary* loc = [dict objectForKey:@"loc"];
        [self setLatitude: [[loc objectForKey:@"lat"] doubleValue]];
        [self setLongitude: [[loc objectForKey:@"lng"] doubleValue]];
        [self setName: [[dict objectForKey:@"name"] lowercaseString]] ; // LOWER CASE
        [self setKey: [dict objectForKey:@"key"]];
        [self setCreatorID: [dict objectForKey:@"creator_id"]];
        [self setUsesPseudonyms:[[dict objectForKey:@"avatar"] boolValue]];
        [self setIsOfficial:[[dict objectForKey:@"official"] boolValue]];
        [self setIsUnlocked:[[dict objectForKey:@"unlocked"] boolValue]];
        //CLLocation * peerlocation = [[SpeakUpManager sharedSpeakUpManager] location];
        CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[self latitude] longitude: [self longitude]];
        self.distance = [[[SpeakUpManager sharedSpeakUpManager] peerLocation] distanceFromLocation:roomlocation];
        // MESSAGES
        self.messages = [NSMutableArray array];
        for (NSDictionary *messageDictionary in [dict objectForKey:@"messages"]) {
                Message* message = [[Message alloc] initWithDictionary:messageDictionary roomID: roomID];
                [self.messages addObject:message];
            }
        }
        
    return self;
}



@end
