//
//  Packet.h
//  SpeakUp
//
//  Created by Sven Reber on 28/05/15.
//  Copyright (c) 2015 Adrian Holzer. All rights reserved.
//

#ifndef SpeakUp_Packet_h
#define SpeakUp_Packet_h
#import <Foundation/Foundation.h>


@interface PacketContent : NSObject<NSCoding>
{
    NSString *type;
    NSObject *content;
    NSArray *args;
}

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSObject *content;
@property (nonatomic, copy) NSArray *args;

- (instancetype)initWithType:(NSString *)type
                 withContent:(NSObject *)content;

@end


#endif
