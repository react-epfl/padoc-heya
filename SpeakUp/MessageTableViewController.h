//
//  ProfileTableViewController.h
//  SpeakUp
//
//  Created by Adrian Holzer on 20.12.11.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "MessageManagerDelegate.h"
#import "ConnectionDelegate.h"

@interface MessageTableViewController : UITableViewController<UINavigationControllerDelegate, MessageManagerDelegate, UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate,ConnectionDelegate,UITextViewDelegate>

-(IBAction)rateMessageUp:(id)sender;
-(IBAction)rateMessageDown:(id)sender;
-(IBAction)sortBy:(id)sender;
-(IBAction)goToWebSite:(id)sender;

@property(strong, nonatomic) IBOutlet UILabel* roomNumberLabel;
@property(strong, nonatomic) IBOutlet UILabel* roomNameLabel;
@property(strong, nonatomic) IBOutlet UILabel* expirationLabel;
@property(strong, nonatomic) IBOutlet UILabel* roomInfoLabel;
@property(strong, nonatomic) IBOutlet UISegmentedControl* segmentedControl ;
@property(strong, nonatomic)  UIView * inputView;
@property(strong, nonatomic)  UIButton * inputButton;
@property(strong, nonatomic)  UITextView * inputTextView;
@property(nonatomic)  BOOL keyboardIsVisible;
@property(nonatomic)  BOOL showKey;
@property(nonatomic) int keyboardHeight;
@property(nonatomic)  BOOL isFirstMessageUpdate;
@property(strong, nonatomic) IBOutlet UIActivityIndicatorView *connectionLostSpinner;

@end
