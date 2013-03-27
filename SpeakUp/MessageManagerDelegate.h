//
//  MemberManagerDelegate.h
//  InterMix
//
//  Created by Adrian Holzer on 07.02.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MessageManagerDelegate <NSObject>



-(void)updateMessages:(NSArray*)messages inRoom: (Room*) room;

-(void)notifyThatRoomHasBeenDeleted:(Room*) room;

@end
