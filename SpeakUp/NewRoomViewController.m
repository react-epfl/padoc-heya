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

@synthesize input, mapView, connectionLostSpinner, segmentedControl, keyTextField, createRoomButton, unlockRoomButton,createRoomLabel, privateBottomLabel, privateTopLabel, privatSwitch,warningLabel;

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
    [customLabel setFont:[UIFont fontWithName:FontName size:MediumFontSize]];
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
                                [UIFont fontWithName:FontName size:MediumFontSize], UITextAttributeFont,
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
    [privatSwitch setHidden:YES];
    [privateBottomLabel setHidden:YES];
    [privateTopLabel setHidden:YES];
    [createRoomButton setHidden:YES];
    [unlockRoomButton setHidden:NO];
    [createRoomButton setHidden:YES];
    [keyTextField setHidden:NO];
    [createRoomLabel setHidden:YES];
    [warningLabel setHidden:YES];
    [keyTextField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated{
    unlockRoomButton.enabled=YES;
     createRoomButton.enabled=YES;
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

-(IBAction)createRoom:(id)sender{
    if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
        NSString *trimmedString = [input.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if(self.input.text.length>0 && trimmedString.length >0){
            NSLog(@"creating a new room %@ ", input.text);
            Room* myRoom = [[Room alloc] init];
            myRoom.name = self.input.text;
            if (!privatSwitch.on) {
                myRoom.latitude=self.mapView.userLocation.coordinate.latitude;
                myRoom.longitude=self.mapView.userLocation.coordinate.longitude;
            }
            myRoom.range=RANGE;
            myRoom.lifetime=LIFETIME;
            myRoom.id_type = ANONYMOUS;
            createRoomButton.enabled=NO;
            [[SpeakUpManager sharedSpeakUpManager] createRoom:myRoom withHandler:^(NSDictionary* handler){
                if ([handler objectForKey:@"key"]) {
                    [self.navigationController popViewControllerAnimated:YES];
                    self.input.text=@"";
                    [[[SpeakUpManager sharedSpeakUpManager] myOwnRoomKeyArray] addObject:[handler objectForKey:@"key"]];
                }else{
                    [self unlockorcreatefailed];
                }
                createRoomButton.enabled=YES;
            }];
        }
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
    }
}

- (IBAction)unlock:(id)sender {
    if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
        unlockRoomButton.enabled=NO;
        [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID:nil  orRoomHash:keyTextField.text withHandler:^(NSDictionary* handler){
            BOOL unlocked = [[handler objectForKey:@"unlocked"] boolValue];
            if (unlocked) {
                [self.navigationController popViewControllerAnimated:YES];
                [[[SpeakUpManager sharedSpeakUpManager] unlockedRoomKeyArray] addObject:[handler objectForKey:@"key"]];
                keyTextField.text = @"";
                [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"button_press"  label:@"join_room"  value:nil] build]];
            }else{
                [self unlockorcreatefailed];
            }
            unlockRoomButton.enabled=YES;
        }];
    }
}

- (void)unlockorcreatefailed{
    CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
    anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
    anim.autoreverses = YES ;
    anim.repeatCount = 2.0f ;
    anim.duration = 0.07f ;
    [unlockRoomButton.layer addAnimation:anim forKey:nil];
    [createRoomButton.layer addAnimation:anim forKey:nil];
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
            privatSwitch.on=NO;
            [warningLabel setHidden:YES];
            [mapView setHidden:NO];
            [input setHidden:NO];
            [createRoomButton setHidden:NO];
            [createRoomLabel setHidden:NO];
            [privatSwitch setHidden:NO];
            [privateBottomLabel setHidden:NO];
            [privateTopLabel setHidden:NO];
            privateTopLabel.text=NSLocalizedString(@"PUBLIC_ROOM_TOP", nil);
            privateBottomLabel.text=NSLocalizedString(@"PUBLIC_ROOM_BOTTOM", nil);
            [input becomeFirstResponder];
        }else{
             privatSwitch.on = YES;
            privateTopLabel.text=NSLocalizedString(@"PRIVATE_ROOM_TOP", nil);
            privateBottomLabel.text=NSLocalizedString(@"PRIVATE_ROOM_BOTTOM", nil);
            [privatSwitch setHidden:YES];
            [mapView setHidden:YES];
        }
    }else if(selectedSegment == UNLOCK_TAB){
        [warningLabel setHidden:YES];
        [privatSwitch setHidden:YES];
        [privateBottomLabel setHidden:YES];
        [privateTopLabel setHidden:YES];
        [mapView setHidden:YES];
        [input setHidden:YES];
        [createRoomButton setHidden:YES];
        [unlockRoomButton setHidden:NO];
        [keyTextField setHidden:NO];
        [createRoomLabel setHidden:YES];
        [keyTextField becomeFirstResponder];
    }
}

-(IBAction)privateOrPublic:(id)sender{
    if (privatSwitch.on) {
        [mapView setHidden:YES];
        privateTopLabel.text=NSLocalizedString(@"PRIVATE_ROOM_TOP", nil);
        privateBottomLabel.text=NSLocalizedString(@"PRIVATE_ROOM_BOTTOM", nil);
    }else{
        [mapView setHidden:NO];
        privateTopLabel.text=NSLocalizedString(@"PUBLIC_ROOM_TOP", nil);
        privateBottomLabel.text=NSLocalizedString(@"PUBLIC_ROOM_BOTTOM", nil);
    }
}

-(IBAction)goToWebSite:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.seance.ch/speakup"]];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"button_press"  label:@"info_from_add"  value:nil] build]];
}

-(void)connectionWasLost{
    [connectionLostSpinner startAnimating];
}
-(void)connectionHasRecovered{
    [connectionLostSpinner stopAnimating];
}


@end
