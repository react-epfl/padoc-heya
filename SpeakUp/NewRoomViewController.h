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

@interface NewRoomViewController : UIViewController<MKMapViewDelegate,UITextFieldDelegate,MFMailComposeViewControllerDelegate,ConnectionDelegate>

@property(strong, nonatomic) IBOutlet UIBarButtonItem * createButton;
@property(strong, nonatomic) IBOutlet UITextField * input;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property(strong, nonatomic) IBOutlet UILabel * noConnectionLabel;


-(IBAction)sendMail;

@end
