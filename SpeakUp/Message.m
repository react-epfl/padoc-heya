//
//  Member.m
//  InterMix
//
//  Created by Adrian Holzer on 16.12.11.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "Message.h"

@implementation Message

@synthesize content, numberOfNo, numberOfYes, yesIsPressed,noIsPressed, messageID, score, creationTime, room, roomID, secondsSinceCreation, lastModified, deleted, authorPeerID, parentMessageID,pseudo;

- (id)init{
    self = [super init];
    if(self){
        noIsPressed=NO;
        yesIsPressed=NO;
        numberOfNo=0;
        numberOfYes=0;
        score=0;
        deleted=NO;
        //replies= [[NSMutableArray alloc] init];
        parentMessageID=nil;
        pseudo=@"";
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*) dict roomID:(NSString *)aRoomID{
    self = [super init];
    if(self){
        [self setRoomID:aRoomID];
        [self setDeleted:[[dict objectForKey:@"deleted"] boolValue]];
        [self setMessageID:[dict objectForKey:@"_id"]];
        [self setParentMessageID:[dict objectForKey:@"_id"]];
        [self setAuthorPeerID: [dict objectForKey:@"creator_id"]];
        [self setCreationTime: [dict objectForKey:@"creation_time"]];
        //NSString* content1= [dict objectForKey:@"body"];
        //NSString* trimmedcontent = [content1 stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        [self setPseudo:[dict objectForKey:@"pseudo"]];
        [self setContent: [dict objectForKey:@"body"]];
        [self setNumberOfNo: [[dict objectForKey:@"dislikes"]intValue]];
        [self setNumberOfYes: [[dict objectForKey:@"likes"]intValue]];
        //[self setReplies: [dict objectForKey:@"replies"]];// ADER not sure if this works
        [self setScore:numberOfYes-numberOfNo];
    }
    return self;
}

@end
