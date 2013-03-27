//
//  Member.m
//  InterMix
//
//  Created by Adrian Holzer on 16.12.11.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "Message.h"

@implementation Message

@synthesize content, numberOfNo, numberOfYes, yesIsPressed,noIsPressed, messageID, score, creationTime, room, roomID, secondsSinceCreation, lastModified, isVisible, peersWhoFlagged, authorPeerID, publication, publicationID, publicationRequest,subscription,subscriptionID,subscriptionRequest,ratingPerPeer;

- (id)init{
    self = [super init];
    if(self){
        noIsPressed=NO;
        yesIsPressed=NO;
        numberOfNo=0;
        numberOfYes=0;
        score=0;
        ratingPerPeer= [[NSMutableDictionary alloc] init];
        subscription=nil;
        subscriptionID=nil;
    }
    return self;
}


@end
