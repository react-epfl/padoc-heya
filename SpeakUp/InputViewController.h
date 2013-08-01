//
//  InputViewController.h
//  SpeakUp
//
//  Created by Adrian Holzer on 10.04.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "ConnectionDelegate.h"

@interface InputViewController : UIViewController <UITextViewDelegate,ConnectionDelegate>


@property(strong, nonatomic) UIButton * sendButton;
@property(strong, nonatomic) IBOutlet UITextView * input;
@property(strong, nonatomic) IBOutlet UILabel * characterCounterLabel;
@property(strong, nonatomic) IBOutlet UILabel * noConnectionLabel;

-(IBAction)sendInput:(id)sender;

@end
