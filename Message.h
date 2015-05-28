//
//  Message.h
//  SpeakUp
//
//  Created by Sven Reber on 28/05/15.
//  Copyright (c) 2015 Adrian Holzer. All rights reserved.
//

#ifndef SpeakUp_Message_h
#define SpeakUp_Message_h
#import <Foundation/Foundation.h>


@interface Message : NSObject<NSCoding>
{
    NSString *type;
    NSObject *content;
}

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSObject *content;

- (instancetype)initWithType:(NSString *)type
                 withContent:(NSObject *)content;

@end


#endif
