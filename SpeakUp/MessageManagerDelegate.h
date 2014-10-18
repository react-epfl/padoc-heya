//
//  MemberManagerDelegate.h
//  InterMix
//
//  Created by Adrian Holzer on 07.02.12.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MessageManagerDelegate <NSObject>

-(void)updateMessagesInRoom: (NSString*) roomID;
-(void)notifyThatRoomHasBeenDeleted:(Room*) room;

@end
