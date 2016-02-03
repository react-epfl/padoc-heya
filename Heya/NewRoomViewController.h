//
//  NewRoomViewController.h
//  SpeakUp
//
//  Created by Adrian Holzer on 07.05.12.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MessageUI/MessageUI.h>
#import "ConnectionDelegate.h"



@interface NewRoomViewController : UIViewController<UITextFieldDelegate, ConnectionDelegate>

@property(strong, nonatomic) IBOutlet UITextField *input;
@property(strong, nonatomic) IBOutlet UIButton *createRoomButton;
@property(strong, nonatomic) IBOutlet UILabel *createRoomLabel;
@property(strong, nonatomic) IBOutlet UITextView *warningLabel;
@property(strong, nonatomic) IBOutlet UIActivityIndicatorView *connectionLostSpinner;

-(IBAction)goToWebSite:(id)sender;

@end
