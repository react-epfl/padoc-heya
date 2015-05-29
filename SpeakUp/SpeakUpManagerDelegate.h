//
//  ALPSManagerDelegate.h
//  Hello ALPS
//
//  Created by Adrian Holzer on 27.11.12.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MHMulticastSocket.h"

@protocol SpeakUpManagerDelegate <NSObject>

@property (nonatomic, strong) MHMulticastSocket *socket;

-(void)updateData;

- (void)setSocket:(MHMulticastSocket *)socket;

@end
