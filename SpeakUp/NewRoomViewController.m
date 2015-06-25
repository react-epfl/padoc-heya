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

#define MAX_LENGTH 30 // A room name cannot exceed 30 characters
#define RANGE 200 // A room has a 200 meter range
#define LIFETIME 720 // The room closes 12 hours after its last update

@implementation NewRoomViewController

@synthesize input, mapView, connectionLostSpinner, createRoomButton, createRoomLabel, privateBottomLabel, privateTopLabel, privatSwitch, warningLabel;

- (void)viewDidLoad {
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
    self.navigationItem.titleView = customLabel;
    [((UILabel *)self.navigationItem.titleView) setText:NSLocalizedString(@"NEW_ROOM", nil)];
    
    // INPUT
    self.input.delegate=self;
    self.input.layer.masksToBounds=YES;
    self.input.layer.backgroundColor=[[UIColor whiteColor] CGColor];
    self.input.layer.borderWidth= 0.0f;
    self.input.placeholder=NSLocalizedString(@"ROOM_NAME", nil);
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    self.input.leftView = view;
    self.input.leftViewMode = UITextFieldViewModeAlways;
    
    // CREATE BUTTON
    [createRoomButton setTitle:NSLocalizedString(@"CREATE_ROOM", nil) forState:UIControlStateNormal];
    createRoomButton.layer.masksToBounds=YES;
    [createRoomButton setTitleColor: [UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [createRoomButton setBackgroundColor:myPurple];
}

- (void)viewWillAppear:(BOOL)animated {
    createRoomButton.enabled = YES;
    if ([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]) {
        [connectionLostSpinner stopAnimating];
    } else {
        [connectionLostSpinner startAnimating];
    }
    
    // GOOGLE TRACKER
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"NewRoom Screen"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
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
    } else {
        [self.mapView setRegion:mapRegion animated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([[input text] length] > 0) {
        [self createRoom:nil];
    }
    return NO;
}

-(IBAction)createRoom:(id)sender {
    if ([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]) {
        NSString *trimmedString = [input.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (self.input.text.length>0 && trimmedString.length > 0) {
            NSLog(@"creating a new room %@ ", input.text);
            
            Room *myRoom = [[Room alloc] init];
            myRoom.name = self.input.text;
            if (!privatSwitch.on) {
                myRoom.latitude = self.mapView.userLocation.coordinate.latitude;
                myRoom.longitude = self.mapView.userLocation.coordinate.longitude;
            }
            myRoom.range = RANGE;
            myRoom.lifetime = LIFETIME;
            myRoom.id_type = ANONYMOUS;
            
            myRoom.roomID = [[NSProcessInfo processInfo] globallyUniqueString];
            myRoom.key = [[NSProcessInfo processInfo] globallyUniqueString];
            myRoom.creatorID = [[SpeakUpManager sharedSpeakUpManager] peer_id];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
            myRoom.lastUpdateTime = [dateFormatter stringFromDate:[NSDate date]];
            
            createRoomButton.enabled = NO;
            [[SpeakUpManager sharedSpeakUpManager] createRoom:myRoom withHandler:^(NSDictionary* handler) {
                if ([handler objectForKey:@"key"]) {
                    [self.navigationController popViewControllerAnimated:YES];
                    self.input.text = @"";
                    [[[SpeakUpManager sharedSpeakUpManager] myOwnRoomKeyArray] addObject:[handler objectForKey:@"key"]];
                } else {
                    [self createfailed];
                }
                createRoomButton.enabled = YES;
            }];
        }
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
    }
}

- (void)createfailed {
    CAKeyframeAnimation * anim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    anim.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f)], [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f)]];
    anim.autoreverses = YES;
    anim.repeatCount = 2.0f;
    anim.duration = 0.07f;
    [createRoomButton.layer addAnimation:anim forKey:nil];
}

// used to limit the number of characters to MAX_LENGTH
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = (textField.text.length - range.length) + string.length;
    if (newLength <= MAX_LENGTH){
        return YES;
    }
    return NO;
}

-(IBAction)privateOrPublic:(id)sender {
    if (privatSwitch.on) {
        [mapView setHidden:YES];
        privateTopLabel.text = NSLocalizedString(@"PRIVATE_ROOM_TOP", nil);
        privateBottomLabel.text = NSLocalizedString(@"PRIVATE_ROOM_BOTTOM", nil);
    } else {
        [mapView setHidden:NO];
        privateTopLabel.text = NSLocalizedString(@"PUBLIC_ROOM_TOP", nil);
        privateBottomLabel.text = NSLocalizedString(@"PUBLIC_ROOM_BOTTOM", nil);
    }
}

-(IBAction)goToWebSite:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.seance.ch/speakup"]];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                                                        action:@"button_press"
                                                                                         label:@"info_from_add"
                                                                                         value:nil] build]];
}

-(void)connectionWasLost {
    [connectionLostSpinner startAnimating];
}

-(void)connectionHasRecovered {
    [connectionLostSpinner stopAnimating];
}

@end
