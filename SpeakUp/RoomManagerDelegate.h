//
//  RoomManagerDelegate.h
//  SpeakUp
//
//  Created by Adrian Holzer on 23.04.12.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RoomManagerDelegate <NSObject>

-(void)updateRooms:(NSMutableArray*)updatedNearbyRooms unlockedRooms: (NSMutableArray*)updatedUnlockedRooms;

@end
