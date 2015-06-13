//
//  Room.m
//  SpeakUp
//
//  Created by Adrian Holzer on 02.04.12.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import "Room.h"
#import "SpeakUpManager.h"

@implementation Room

@synthesize roomID, name, location, messages,avatarCacheByPeerID, distance, latitude, longitude, lifetime, range, isOfficial, deleted, creatorID,key, id_type, isUnlocked, lastUpdateTime ;

- (id)init{
    self = [super init];
    if(self){
        messages = [NSMutableArray array];
        isOfficial=NO;
        deleted=NO;
        isUnlocked=NO;
        latitude=-1;
        longitude=-1;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*) dict{
    self = [super init];
    if(self){
        avatarCacheByPeerID = [[NSCache alloc] init];
        [self setRoomID: [dict objectForKey:@"room_id"]];
        [self setDeleted:[[dict objectForKey:@"deleted"] boolValue]];
//        NSDictionary* loc = [dict objectForKey:@"loc"];
//        [self setLatitude: [[loc objectForKey:@"lat"] doubleValue]];
//        [self setLongitude: [[loc objectForKey:@"lng"] doubleValue]];
        [self setName: [dict objectForKey:@"name"] ] ; // LOWER CASE
        [self setKey: [dict objectForKey:@"key"]];
        [self setCreatorID: [dict objectForKey:@"creator_id"]];
        [self setLastUpdateTime: [dict objectForKey:@"update_time"]];
        [self setId_type:[dict objectForKey:@"id_type"]];
        [self setIsOfficial:[[dict objectForKey:@"official"] boolValue]];
        [self setIsUnlocked:[[dict objectForKey:@"unlocked"] boolValue]];
        if (self.isUnlocked && ![[[SpeakUpManager sharedSpeakUpManager]unlockedRoomKeyArray] containsObject:self.key]) {
            [[[SpeakUpManager sharedSpeakUpManager] unlockedRoomKeyArray] addObject:self.key];
        }
        CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[self latitude] longitude: [self longitude]];
        self.distance = [[[SpeakUpManager sharedSpeakUpManager] peerLocation] distanceFromLocation:roomlocation];
        
        // MESSAGES
        if ([dict objectForKey:@"messages"]) { // meesages are nil if there are none
            self.messages = [NSMutableArray array];
            for (NSDictionary *messageDictionary in [dict objectForKey:@"messages"]) {
                Message* message = [[Message alloc] initWithDictionary:messageDictionary roomID: roomID];
                if (!message.deleted && !message.parentMessageID) {
                    [self.messages addObject:message];
                }
            }
        }
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        roomID = [decoder decodeObjectForKey:@"roomID"];
        creatorID = [decoder decodeObjectForKey:@"creatorID"];
        distance = [decoder decodeFloatForKey:@"distance"];
        name = [decoder decodeObjectForKey:@"name"];
        key = [decoder decodeObjectForKey:@"key"];
        location = [decoder decodeObjectForKey:@"location"];
        latitude = [decoder decodeDoubleForKey:@"latitude"];
        longitude = [decoder decodeDoubleForKey:@"longitude"];
        lifetime = [decoder decodeIntForKey:@"lifetime"];
        range = [decoder decodeIntForKey:@"range"];
        isOfficial = [decoder decodeBoolForKey:@"isOfficial"];
        isUnlocked = [decoder decodeBoolForKey:@"isUnlocked"];
        id_type = [decoder decodeObjectForKey:@"id_type"];
        deleted = [decoder decodeBoolForKey:@"deleted"];
//        avatarCacheByPeerID = [decoder decodeObjectForKey:@"avatarCacheByPeerID"];
        lastUpdateTime = [decoder decodeObjectForKey:@"lastUpdateTime"];
        messages = [decoder decodeObjectForKey:@"messages"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:roomID forKey:@"roomID"];
    [encoder encodeObject:creatorID forKey:@"creatorID"];
    [encoder encodeFloat:distance forKey:@"distance"];
    [encoder encodeObject:name forKey:@"name"];
    [encoder encodeObject:key forKey:@"key"];
    [encoder encodeObject:location forKey:@"location"];
    [encoder encodeDouble:latitude forKey:@"latitude"];
    [encoder encodeDouble:longitude forKey:@"longitude"];
    [encoder encodeInt:lifetime forKey:@"lifetime"];
    [encoder encodeInt:range forKey:@"range"];
    [encoder encodeBool:isOfficial forKey:@"isOfficial"];
    [encoder encodeBool:isUnlocked forKey:@"isUnlocked"];
    [encoder encodeObject:id_type forKey:@"id_type"];
    [encoder encodeBool:deleted forKey:@"deleted"];
//    [encoder encodeObject:avatarCacheByPeerID forKey:@"avatarCacheByPeerID"];
    [encoder encodeObject:lastUpdateTime forKey:@"lastUpdateTime"];
    [encoder encodeObject:messages forKey:@"messages"];
}


@end
