//
//  AppDelegate.h
//  Heya
//
//  Created by Adrian Holzer on 23.10.12.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MHPadoc.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)setPadoc:(MHPadoc *)padoc;

@end
