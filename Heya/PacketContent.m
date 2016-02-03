//
//  Packet.m
//  SpeakUp
//
//  Created by Sven Reber on 28/05/15.
//  Copyright (c) 2015 Adrian Holzer. All rights reserved.
//

#import "PacketContent.h"


@implementation PacketContent

@synthesize type, content, args;

- (instancetype)initWithType:(NSString *)typeInit
                 withContent:(id)contentInit
{
    self = [super init];
    if (self)
    {
        type = typeInit;
        content = contentInit;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        type = [decoder decodeObjectForKey:@"type"];
        content = [decoder decodeObjectForKey:@"content"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:type forKey:@"type"];
    [encoder encodeObject:content forKey:@"content"];
}

- (void)dealloc
{
    type = nil;
    content = nil;
}

@end