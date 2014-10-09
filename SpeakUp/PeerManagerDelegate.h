//
//  PeerManagerDelegate.h
//  SpeakUp
//
//  Created by Adrian Holzer on 24.09.12.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PeerManagerDelegate <NSObject>


-(void)peerIsReady;

-(void)peerIsNotReady;


@end
