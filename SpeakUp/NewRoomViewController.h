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



@interface NewRoomViewController : UIViewController<MKMapViewDelegate,UITextFieldDelegate,ConnectionDelegate>

@property(strong, nonatomic) IBOutlet UITextField * input;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property(strong, nonatomic) IBOutlet UISegmentedControl* segmentedControl ;
@property(strong, nonatomic) IBOutlet UITextField * keyTextField;
@property(strong, nonatomic) IBOutlet UIButton * createRoomButton;
@property(strong, nonatomic) IBOutlet UIButton * unlockRoomButton;
@property(strong, nonatomic) IBOutlet UILabel * createRoomLabel;
@property(strong, nonatomic) IBOutlet UITextView * warningLabel;
@property(strong, nonatomic) IBOutlet UILabel * privateTopLabel;
@property(strong, nonatomic) IBOutlet UILabel * privateBottomLabel;
@property(strong, nonatomic) IBOutlet UISwitch * privatSwitch;
@property(strong, nonatomic) IBOutlet UIActivityIndicatorView *connectionLostSpinner;

-(IBAction)createOrUnlock:(id)sender;
-(IBAction)privateOrPublic:(id)sender;
-(IBAction)goToWebSite:(id)sender;

@end
