//
//  ProfileTableViewController.h
//  SpeakUp
//
//  Created by Adrian Holzer on 20.12.11.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "MessageManagerDelegate.h"
#import "ConnectionDelegate.h"

@interface MessageTableViewController : UITableViewController<UINavigationControllerDelegate, MessageManagerDelegate, UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate,ConnectionDelegate,UITextViewDelegate>{
    
   // EGORefreshTableHeaderView *_refreshHeaderView;
	//  Reloading var should really be your tableviews datasource
	//  Putting it here for demo purposes
	//BOOL _reloading;
}

//press thumb up
-(IBAction)rateMessageUp:(id)sender;
//press thumb up
-(IBAction)rateMessageDown:(id)sender;
//press thumb up
-(IBAction)sortBy:(id)sender;

@property(strong, nonatomic) IBOutlet UILabel* roomNameLabel;
@property(strong, nonatomic) IBOutlet UISegmentedControl* segmentedControl ;
//@property(strong, nonatomic) IBOutlet UILabel * noConnectionLabel;

@property(strong, nonatomic)  UIView * inputView;
@property(strong, nonatomic)  UIButton * inputButton;
@property(strong, nonatomic)  UITextView * inputTextView;

@property(nonatomic)  BOOL keyboardIsVisible;
@property(nonatomic)  BOOL showKey;
@property(nonatomic) int keyboardHeight;

@property(strong, nonatomic) IBOutlet UIActivityIndicatorView *connectionLostSpinner;




@end
