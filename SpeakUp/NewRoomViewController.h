//
//  NewRoomViewController.h
//  SpeakUp
//
//  Created by Adrian Holzer on 07.05.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MessageUI/MessageUI.h>
#import "ConnectionDelegate.h"



@interface NewRoomViewController : UIViewController<MKMapViewDelegate,UITextFieldDelegate,ConnectionDelegate>

//@property(strong, nonatomic) IBOutlet UIBarButtonItem * createButton;
@property(strong, nonatomic) IBOutlet UITextField * input;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
//@property(strong, nonatomic) IBOutlet UILabel * noConnectionLabel;
@property(strong, nonatomic) IBOutlet UISegmentedControl* segmentedControl ;

@property(strong, nonatomic) IBOutlet UITextField * keyTextField;
@property(strong, nonatomic) IBOutlet UIButton * createRoomButton;
@property(strong, nonatomic) IBOutlet UIButton * unlockRoomButton;
@property(strong, nonatomic) IBOutlet UILabel * createRoomLabel;

@property(strong, nonatomic) IBOutlet UILabel * warningLabel;

@property(strong, nonatomic) IBOutlet UISwitch * pseudoSwitch;
@property(strong, nonatomic) IBOutlet UILabel * pseudoLabel;

@property(strong, nonatomic) IBOutlet UIActivityIndicatorView *connectionLostSpinner;

//-(IBAction)sendMail;

-(IBAction)createOrUnlock:(id)sender;

@end
