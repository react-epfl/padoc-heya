//
//  Message.m
//  SpeakUp
//
//  Created by Adrian Holzer on 16.12.11.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import "Message.h"

@implementation Message

@synthesize content, numberOfNo, numberOfYes, yesIsPressed,noIsPressed, messageID, score, creationTime, room, roomID, secondsSinceCreation, lastModified, deleted, authorPeerID, parentMessageID,pseudo,avatarURL, replies;

- (id)init{
    self = [super init];
    if(self){
        noIsPressed=NO;
        yesIsPressed=NO;
        numberOfNo=0;
        numberOfYes=0;
        score=0;
        deleted=NO;
        replies= [[NSMutableArray alloc] init];
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
        [self setAuthorPeerID: [dict objectForKey:@"creator_id"]];
        [self setCreationTime: [dict objectForKey:@"creation_time"]];
        [self setPseudo:[dict objectForKey:@"pseudo"]];
        NSString* URL = [NSString stringWithFormat:@"https://secure.gravatar.com/avatar/%@?s=64&r=any&default=retro&forcedefault=1",self.authorPeerID ];
        [self setAvatarURL:URL];
        [self setContent: [dict objectForKey:@"body"]];
        [self setNumberOfNo: [[dict objectForKey:@"dislikes"]intValue]];
        [self setNumberOfYes: [[dict objectForKey:@"likes"]intValue]];
        [self setScore:numberOfYes-numberOfNo];
        
        // MESSAGES
        self.replies = [NSMutableArray array];
        if ([dict objectForKey:@"replies"]) { // meesages are nil if there are none
            for (NSDictionary *messageDictionary in [dict objectForKey:@"replies"]) {
                Message* message = [[Message alloc] initWithDictionary:messageDictionary roomID: roomID];
                [self.replies addObject:message];
            }
        }
        //ADD SOME MOCK replies
       // Message *m = [[Message alloc] init];
       // m.content=@"this is some mock content";
       // m.messageID=@"666";
       // m.parentMessageID=self.messageID;
       // [self.replies addObject:m];
    }
    return self;
}

@end
