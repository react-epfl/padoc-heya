//
//  Reply.m
//  SpeakUp
//
//  Created by Adrian Holzer on 09.07.13.
//  Copyright (c) 2013 Adrian Holzer. All rights reserved.
//

#import "Reply.h"

@implementation Reply

@synthesize parentMessageID;

- (id)init{
    self = [super init];
    if(self){
        parentMessageID=nil;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*) dict roomID:(NSString *)aRoomID{
    self = [super init];
    if(self){
        [self setParentMessageID:[dict objectForKey:@"parent_id"]];
    }
    return self;
}


@end
