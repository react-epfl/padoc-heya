//
//  InputViewController.h
//  SpeakUp
//
//  Created by Adrian Holzer on 10.04.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"

@interface InputViewController : UIViewController <UITextViewDelegate>


@property(strong, nonatomic) IBOutlet UIBarButtonItem * sendButton;
@property(strong, nonatomic) IBOutlet UITextView * input;
@property(strong, nonatomic) IBOutlet UILabel * characterCounterLabel;
@property(strong, nonatomic) Room *room;

-(IBAction)sendInput:(id)sender;

@end
