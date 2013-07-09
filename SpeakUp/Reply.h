//
//  Reply.h
//  SpeakUp
//
//  Created by Adrian Holzer on 09.07.13.
//  Copyright (c) 2013 Adrian Holzer. All rights reserved.
//

#import "Message.h"

@interface Reply : Message


@property (strong, nonatomic) NSString* parentMessageID;

@end
