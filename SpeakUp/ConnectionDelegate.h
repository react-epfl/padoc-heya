//
//  ConnectionDelegate.h
//  SpeakUp
//
//  Created by Adrian Holzer on 26.06.13.
//  Copyright (c) 2013 Adrian Holzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ConnectionDelegate <NSObject>


-(void)connectionWasLost;

-(void)connectionHasRecovered;

@end
