//
//  NewRoomViewController.m
//  SpeakUp
//
//  Created by Adrian Holzer on 07.05.12.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import "NewRoomViewController.h"
#import "Room.h"
#import "SpeakUpManager.h"
#import <QuartzCore/QuartzCore.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

#define MAX_ROOMS 3
#define MAX_LENGTH 30
#define RANGE 200 // a room has a 200 meter range
#define LIFETIME 720//message remain 12 hours in the room

@implementation NewRoomViewController

@synthesize input, mapView, connectionLostSpinner, segmentedControl, keyTextField, createRoomButton, unlockRoomButton,createRoomLabel, pseudoLabel, pseudoSwitch,warningLabel,avatarLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    [[SpeakUpManager sharedSpeakUpManager] setConnectionDelegate:self];
    
    // BACK BUTTON
    UIButton *newBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [newBackButton setImage:[UIImage imageNamed: @"button-back1.png"] forState:UIControlStateNormal];
    [newBackButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    newBackButton.frame = CGRectMake(5, 5, 30, 30);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:newBackButton];
    
    // NAV TITLE
    UILabel *customLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120.0f, 44.0f)];
    customLabel.backgroundColor= [UIColor clearColor];
    customLabel.textAlignment = NSTextAlignmentCenter;
    [customLabel setFont:[UIFont fontWithName:@"Helvetica-Light" size:MediumFontSize]];
    customLabel.textColor =  [UIColor whiteColor];
    
    // INPUT
    self.input.delegate=self;
    self.input.layer.masksToBounds=YES;
    self.input.layer.backgroundColor=[[UIColor whiteColor] CGColor];
    self.input.layer.borderWidth= 0.0f;
    self.input.placeholder=NSLocalizedString(@"ROOM_NAME", nil);
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    self.input.leftView = view;
    self.input.leftViewMode = UITextFieldViewModeAlways;
    [keyTextField setKeyboardType:UIKeyboardTypeDefault];
    
    // UNLOCK INPUT
    self.keyTextField.layer.masksToBounds=YES;
    self.keyTextField.layer.backgroundColor=[[UIColor whiteColor] CGColor];
    self.keyTextField.layer.borderWidth= 0.0f;
    self.keyTextField.placeholder=NSLocalizedString(@"ROOM_KEY", nil);
    UIView *view2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    self.keyTextField.leftView = view2;
    self.keyTextField.leftViewMode = UITextFieldViewModeAlways;
    [keyTextField setKeyboardType:UIKeyboardTypeNumberPad];
    
    //SEGMENTED VIEW CONTROL TITLE
    [segmentedControl setTitle:NSLocalizedString(@"UNLOCK", nil) forSegmentAtIndex:0];
    [segmentedControl setTitle:NSLocalizedString(@"CREATE", nil) forSegmentAtIndex:1];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [UIFont fontWithName:@"Helvetica-Light" size:MediumFontSize], UITextAttributeFont,
                                [UIColor whiteColor], UITextAttributeTextColor, nil  ];
    [segmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    NSDictionary *highlightedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                           myGrey, UITextAttributeTextColor, nil  ];
    [segmentedControl setTitleTextAttributes:highlightedAttributes forState:UIControlStateHighlighted];
    NSDictionary *selectedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIColor whiteColor], UITextAttributeTextColor,
                                        [NSNumber numberWithInt:NSUnderlineStyleSingle],NSUnderlineStyleAttributeName, nil  ];
    [segmentedControl setTitleTextAttributes:selectedAttributes forState:UIControlStateSelected];
    
    // UNLOCK BUTTON
    [unlockRoomButton setTitle:NSLocalizedString(@"JOIN_ROOM", nil) forState:UIControlStateNormal];
    unlockRoomButton.layer.masksToBounds=YES;
    [unlockRoomButton setTitleColor: [UIColor lightGrayColor ] forState:UIControlStateHighlighted];
    [unlockRoomButton setBackgroundColor:myPurple];
    
    // CREATE BUTTON
    [createRoomButton setTitle:NSLocalizedString(@"CREATE_ROOM", nil) forState:UIControlStateNormal];
    createRoomButton.layer.masksToBounds=YES;
    [createRoomButton setTitleColor: [UIColor lightGrayColor ] forState:UIControlStateHighlighted];
    [createRoomButton setBackgroundColor:myPurple];
    
    // HIDE CREATION STUFF AND SHOW UNLOCK STUFF
    [mapView setHidden:YES];
    [input setHidden:YES];
    [pseudoSwitch setHidden:YES];
    [pseudoLabel setHidden:YES];
    [avatarLabel setHidden:YES];
    [createRoomButton setHidden:YES];
    [unlockRoomButton setHidden:NO];
    [createRoomButton setHidden:YES];
    [keyTextField setHidden:NO];
    [createRoomLabel setHidden:YES];
    [warningLabel setHidden:YES];
    [keyTextField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated{
    if ([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
        [connectionLostSpinner stopAnimating];
    }else{
        [connectionLostSpinner startAnimating];
    }
    //GOOGLE TRACKER
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"NewRoom Screen"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = self.mapView.userLocation.coordinate;
    // set sane span values
    mapRegion.span.latitudeDelta = 0.0f;
    mapRegion.span.longitudeDelta = 0.0f;
    // check for sane center values
    if (mapRegion.center.latitude > 90.0f || mapRegion.center.latitude < -90.0f ||
        mapRegion.center.longitude > 360.0f || mapRegion.center.longitude < -180.0f
        ) {
        //Bad Lat or Long don't do anything
    }else{
        [self.mapView setRegion:mapRegion animated: YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if([[input text] length]>0){
        [self createRoom:nil];
    }
    return NO;
}

-(void)connectionWasLost{
    [connectionLostSpinner startAnimating];
}
-(void)connectionHasRecovered{
    [connectionLostSpinner stopAnimating];
}

-(IBAction)createRoom:(id)sender{
    if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
        NSString *trimmedString = [input.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if(self.input.text.length>0 && trimmedString.length >0){
            NSLog(@"creating a new room %@ ", input.text);
            Room* myRoom = [[Room alloc] init];
            myRoom.name = self.input.text;
            myRoom.latitude=self.mapView.userLocation.coordinate.latitude;
            myRoom.longitude=self.mapView.userLocation.coordinate.longitude;
            myRoom.range=RANGE;
            myRoom.lifetime=LIFETIME;
            myRoom.id_type = ANONYMOUS;
            [[SpeakUpManager sharedSpeakUpManager] createRoom:myRoom];// ADER GET CALLBACK AND ADD ROOMKEY TO LIST OF OWN ROOMS
            
            // DUMMY
            
            [[[SpeakUpManager sharedSpeakUpManager] myOwnRoomKeyArray] addObject:@"15576"];
            
            //DUMMMY
            
            self.input.text=@"";
            [self.navigationController popViewControllerAnimated:YES];
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            // GOOGLE ANALYTICS
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                                  action:@"button_press"  // Event action (required)
                                                                   label:@"create_room"   // Event label
                                                                   value:nil] build]];    // Event value
        }
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
    }
}

// used to limit the number of characters to MAX_LENGTH
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSUInteger newLength = (textField.text.length - range.length) + string.length;
    if(newLength <= MAX_LENGTH){
        return YES;
    }
    return NO;
}

-(IBAction)createOrUnlock:(id)sender{
    UISegmentedControl *seg = (UISegmentedControl *) sender;
    NSInteger selectedSegment = seg.selectedSegmentIndex;
    [warningLabel setText:NSLocalizedString(@"TURN_LOCATION_ON", nil)];
    if (selectedSegment == CREATE_TAB) {
        [unlockRoomButton setHidden:YES];
        [keyTextField setHidden:YES];
        if ([[SpeakUpManager sharedSpeakUpManager] locationIsOK]) {
            [warningLabel setHidden:YES];
            [mapView setHidden:NO];
            [input setHidden:NO];
            [createRoomButton setHidden:NO];
            [createRoomLabel setHidden:NO];
            [pseudoSwitch setHidden:NO];
            [pseudoLabel setHidden:NO];
            [avatarLabel setHidden:NO];
            [input becomeFirstResponder];
        }else{
            [warningLabel setHidden:NO];
            [pseudoSwitch setHidden:YES];
            [pseudoLabel setHidden:YES];
            [avatarLabel setHidden:YES];
            [mapView setHidden:YES];
            [input setHidden:YES];
            [createRoomButton setHidden:YES];
            [createRoomLabel setHidden:YES];
        }
    }else if(selectedSegment == UNLOCK_TAB){
        [warningLabel setHidden:YES];
        [pseudoSwitch setHidden:YES];
        [pseudoLabel setHidden:YES];
        [avatarLabel setHidden:YES];
        [mapView setHidden:YES];
        [input setHidden:YES];
        [createRoomButton setHidden:YES];
        [unlockRoomButton setHidden:NO];
        [keyTextField setHidden:NO];
        [createRoomLabel setHidden:YES];
        [keyTextField becomeFirstResponder];
    }
}

- (IBAction)unlock:(id)sender {
    if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
        // check if the label is ok, then pop the view
        //[[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID:nil  orRoomHash:keyTextField.text];
        
        [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID:nil  orRoomHash:keyTextField.text withHandler:^(NSDictionary* handler){
            NSLog(@"XXXXXXXXXXXXXXX");
        }];
        // could wait for response and then enter the lobby
        
        
        [self.navigationController popViewControllerAnimated:YES];
        // GOOGLE ANALYTICS
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                              action:@"button_press"  // Event action (required)
                                                               label:@"join_room"          // Event label
                                                               value:nil] build]];    // Event value
    }
}


- (void)loginFailed:(NSError *)error {
    // [[[UIAlertView alloc] initWithTitle:@"Login failed" message:[error localizedFailureReason] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
    anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
    anim.autoreverses = YES ;
    anim.repeatCount = 2.0f ;
    anim.duration = 0.07f ;
    [ unlockRoomButton.layer addAnimation:anim forKey:nil ] ;
    //loginWarningLabel.text=@"invalid username or password";
    [unlockRoomButton setHidden:NO];
}


- (IBAction)flip:(id)sender {
    if (pseudoSwitch.on){
        NSLog(@"Should use pseudo");
    }
    else  NSLog(@"Should not use pseudo");
}

-(IBAction)goToWebSite:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.seance.ch/speakup"]];
    // GOOGLE ANALYTICS
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"button_press"  // Event action (required)
                                                           label:@"info_from_add"          // Event label
                                                           value:nil] build]];    // Event value
}


@end
