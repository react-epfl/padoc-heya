//
//  Packet.h
//  Heya
//
//  Created by Sven Reber on 28/05/15.
//  Copyright (c) 2015 Adrian Holzer. All rights reserved.
//

#ifndef Heya_Packet_h
#define Heya_Packet_h
#import <Foundation/Foundation.h>


@interface PacketContent : NSObject<NSCoding>
{
    NSString *type;
    NSObject *content;
    NSArray *args;
}

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) id content;
@property (nonatomic, copy) NSArray *args;

- (instancetype)initWithType:(NSString *)type
                 withContent:(id)content;

@end


#endif
