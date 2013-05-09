//
//  Member.m
//  InterMix
//
//  Created by Adrian Holzer on 16.12.11.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "Message.h"

@implementation Message

@synthesize content, numberOfNo, numberOfYes, yesIsPressed,noIsPressed, messageID, score, creationTime, room, roomID, secondsSinceCreation, lastModified, isVisible, authorPeerID;

- (id)init{
    self = [super init];
    if(self){
        noIsPressed=NO;
        yesIsPressed=NO;
        numberOfNo=0;
        numberOfYes=0;
        score=0;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*) dict roomID:(NSString *)aRoomID{
    self = [super init];
    if(self){
        [self setRoomID:aRoomID];

        [self setMessageID:[dict objectForKey:@"_id"]];
        [self setAuthorPeerID: [dict objectForKey:@"creator_id"]];
        [self setCreationTime: [dict objectForKey:@"creation_time"]];
        [self setContent: [dict objectForKey:@"body"]];
        [self setNumberOfNo: [[dict objectForKey:@"dislikes"]intValue]];
        [self setNumberOfYes: [[dict objectForKey:@"likes"]intValue]];
        [self setScore:numberOfYes-numberOfNo];
    }
    return self;
}

@end
