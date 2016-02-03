//
//  Message.m
//  SpeakUp
//
//  Created by Adrian Holzer on 16.12.11.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import "Message.h"

@implementation Message

@synthesize content, numberOfNo, numberOfYes, yesIsPressed,noIsPressed, messageID, score, creationTime, room, roomID, secondsSinceCreation, lastModified, deleted, authorPeerID, parentMessageID,pseudo,avatarURL, replies,hotScore;


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
        [self setParentMessageID: [dict objectForKey:@"parent_id"]];
        if (!self.deleted) {
            self.replies = [NSMutableArray array];
            if ([dict objectForKey:@"replies"]) { // meesages are nil if there are none
                for (NSDictionary *messageDictionary in [dict objectForKey:@"replies"]) {
                    Message* message = [[Message alloc] initWithDictionary:messageDictionary roomID: roomID];
                    if (!message.deleted) {
                        [self.replies addObject:message];
                    }
                }
            }
        }
    }
    return self;
}


-(double)hotScore{
    if(self.score<=0){
        return self.score;
    }else{
        int HotScoreHalfLifeInMinutes=15;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        NSDate *messageCreationTime = [dateFormatter dateFromString:self.creationTime];
        NSTimeInterval elapsedTimeSinceMessageCreation = [messageCreationTime timeIntervalSinceNow];
        self.secondsSinceCreation = elapsedTimeSinceMessageCreation;
        NSInteger minutes = -self.secondsSinceCreation/60;
        int e = minutes/HotScoreHalfLifeInMinutes;
        double hot = self.score/pow(2,e);
        NSLog(@"Message date in minutes: %ld, score: %d, hot: %f", (long)minutes, self.score, hot  );
        return hot;
    }
    
}


- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        messageID = [decoder decodeObjectForKey:@"messageID"];
        parentMessageID = [decoder decodeObjectForKey:@"parentMessageID"];
        pseudo = [decoder decodeObjectForKey:@"pseudo"];
        authorPeerID = [decoder decodeObjectForKey:@"authorPeerID"];
        roomID = [decoder decodeObjectForKey:@"roomID"];
        room = [decoder decodeObjectForKey:@"room"];
        avatarURL = [decoder decodeObjectForKey:@"avatarURL"];
        content = [decoder decodeObjectForKey:@"content"];
        creationTime = [decoder decodeObjectForKey:@"creationTime"];
        lastModified = [decoder decodeObjectForKey:@"lastModified"];
        secondsSinceCreation = [decoder decodeIntForKey:@"secondsSinceCreation"];
        deleted = [decoder decodeBoolForKey:@"deleted"];
        numberOfYes = [decoder decodeIntForKey:@"numberOfYes"];
        numberOfNo = [decoder decodeIntForKey:@"numberOfNo"];
        score = [decoder decodeIntForKey:@"score"];
        hotScore = [decoder decodeDoubleForKey:@"hotScore"];
        yesIsPressed = [decoder decodeBoolForKey:@"yesIsPressed"];
        noIsPressed = [decoder decodeBoolForKey:@"noIsPressed"];
        replies = [decoder decodeObjectForKey:@"replies"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:messageID forKey:@"messageID"];
    [encoder encodeObject:parentMessageID forKey:@"parentMessageID"];
    [encoder encodeObject:pseudo forKey:@"pseudo"];
    [encoder encodeObject:authorPeerID forKey:@"authorPeerID"];
    [encoder encodeObject:roomID forKey:@"roomID"];
    [encoder encodeObject:room forKey:@"room"];
    [encoder encodeObject:avatarURL forKey:@"avatarURL"];
    [encoder encodeObject:content forKey:@"content"];
    [encoder encodeObject:creationTime forKey:@"creationTime"];
    [encoder encodeObject:lastModified forKey:@"lastModified"];
    [encoder encodeInt:secondsSinceCreation forKey:@"secondsSinceCreation"];
    [encoder encodeBool:deleted forKey:@"deleted"];
    [encoder encodeInt:numberOfYes forKey:@"numberOfYes"];
    [encoder encodeInt:numberOfNo forKey:@"numberOfNo"];
    [encoder encodeInt:score forKey:@"score"];
    [encoder encodeDouble:hotScore forKey:@"hotScore"];
    [encoder encodeBool:yesIsPressed forKey:@"yesIsPressed"];
    [encoder encodeBool:noIsPressed forKey:@"noIsPressed"];
    [encoder encodeObject:replies forKey:@"replies"];
}

@end
