//
//  NewRoomViewController.m
//  SpeakUp
//
//  Created by Adrian Holzer on 07.05.12.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "NewRoomViewController.h"
#import "Room.h"
#import "SpeakUpManager.h"
#import <QuartzCore/QuartzCore.h>

#define MAX_ROOMS 3
#define MAX_LENGTH 40
#define RANGE 200 // a room has a 200 meter range
#define LIFETIME 720//message remain 12 hours in the room

@implementation NewRoomViewController


@synthesize createButton, input, mapView, noConnectionLabel, segmentedControl, keyTextField, createRoomButton, unlockRoomButton,createRoomLabel, pseudoLabel, pseudoSwitch,warningLabel;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.mapView.delegate = self;
    
    
    
    [createButton setEnabled:YES];
    [[SpeakUpManager sharedSpeakUpManager] setConnectionDelegate:self];
    if([[SpeakUpManager sharedSpeakUpManager] isSuperUser]){
        [input setPlaceholder:@"You are super :)"];
    }
    
    // BACK BUTTON START
    UIButton *newBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [newBackButton setImage:[UIImage imageNamed: @"button-back1.png"] forState:UIControlStateNormal];
    [newBackButton setImage:[UIImage imageNamed: @"button-back2.png"] forState:UIControlStateHighlighted];
    [newBackButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    newBackButton.frame = CGRectMake(5, 5, 30, 30);
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:newBackButton];
    // BACK BUTTON END
    
    // COMPOSE BUTTON START
    UIButton *composeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [composeButton setImage:[UIImage imageNamed: @"button-write1.png"] forState:UIControlStateNormal];
    [composeButton setImage:[UIImage imageNamed: @"button-write2.png"] forState:UIControlStateHighlighted];
    [composeButton addTarget:self action:@selector(sendMail) forControlEvents:UIControlEventTouchUpInside];
    composeButton.frame = CGRectMake(5, 5, 30, 30);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:composeButton];
    // COMPOSE BUTTON END
    
    // NAV TITLE
    UILabel *customLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120.0f, 44.0f)];
    customLabel.backgroundColor= [UIColor clearColor];
    customLabel.textAlignment = NSTextAlignmentCenter;
    [customLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:20]];
    customLabel.textColor =  [UIColor whiteColor];
    self.navigationItem.titleView = customLabel;
    [((UILabel *)self.navigationItem.titleView) setText:NSLocalizedString(@"CREATE_ROOM", nil)];
    
    // INPUT
    self.input.delegate=self;
    
    self.input.layer.cornerRadius=2.0f;
    self.input.layer.masksToBounds=YES;
    self.input.layer.backgroundColor=[[UIColor whiteColor] CGColor];
    self.input.layer.borderWidth= 0.0f;
    //[self.input setValue:[UIColor colorWithRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1.0] forKeyPath:@"_placeholderLabel.textColor"];
    self.input.placeholder=NSLocalizedString(@"ROOM_NAME", nil);
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    self.input.leftView = view;
    self.input.leftViewMode = UITextFieldViewModeAlways;
    [keyTextField setKeyboardType:UIKeyboardTypeDefault];
    
    // UNLOCK INPUT
    self.keyTextField.layer.cornerRadius=2.0f;
    self.keyTextField.layer.masksToBounds=YES;
    self.keyTextField.layer.backgroundColor=[[UIColor whiteColor] CGColor];
    self.keyTextField.layer.borderWidth= 0.0f;
    //[self.keyTextField setValue:[UIColor colorWithRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1.0] forKeyPath:@"_placeholderLabel.textColor"];
    self.keyTextField.placeholder=NSLocalizedString(@"ROOM_KEY", nil);
    UIView *view2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    self.keyTextField.leftView = view2;
    self.keyTextField.leftViewMode = UITextFieldViewModeAlways;
     [keyTextField setKeyboardType:UIKeyboardTypeNumberPad];
    
    //SEGMENTED VIEW CONTROL TITLE
    [segmentedControl setTitle:NSLocalizedString(@"UNLOCK", nil) forSegmentAtIndex:0];
    [segmentedControl setTitle:NSLocalizedString(@"CREATE", nil) forSegmentAtIndex:1];
    
    //SEGMENTED VIEW CONTROL IMAGES
    [segmentedControl setBackgroundImage:[UIImage imageNamed:@"seg-selected3.png"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [segmentedControl setBackgroundImage:[UIImage imageNamed:@"seg-selected2.png"] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [segmentedControl setDividerImage:[UIImage imageNamed:@"seg-div3.png"] forLeftSegmentState:UIControlStateSelected  rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [segmentedControl setDividerImage:[UIImage imageNamed:@"seg-div3.png"] forLeftSegmentState:UIControlStateNormal  rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
     [segmentedControl setDividerImage:[UIImage imageNamed:@"seg-div3.png"] forLeftSegmentState:UIControlStateNormal  rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  
    
    // UNLOCK BUTTON
    [unlockRoomButton setTitle:NSLocalizedString(@"UNLOCK", nil) forState:UIControlStateNormal];
    unlockRoomButton.layer.masksToBounds=YES;
    unlockRoomButton.layer.cornerRadius=2.0f;
    [unlockRoomButton setTitleColor: [UIColor lightGrayColor ] forState:UIControlStateHighlighted];
    [unlockRoomButton setBackgroundImage:[UIImage imageNamed:@"seg-selected3.png"] forState:UIControlStateNormal];
    [unlockRoomButton setBackgroundImage:[UIImage imageNamed:@"seg-selected2.png"] forState:UIControlStateSelected];
    
    //PSEUDO LABEL
    [pseudoLabel setText:NSLocalizedString(@"PSEUDO", nil)];
    
    //WARNING LABEL
    [warningLabel setText:NSLocalizedString(@"TURN_LOCATION_ON", nil)];
    
    
    // HIDE CREATION STUFF AND SHOW UNLOCK STUFF
    [mapView setHidden:YES];
    [input setHidden:YES];
    [pseudoSwitch setHidden:YES];
    [pseudoLabel setHidden:YES];
    [createRoomButton setHidden:YES];
    [unlockRoomButton setHidden:NO];
    [keyTextField setHidden:NO];
    [createRoomLabel setHidden:YES];
    [warningLabel setHidden:YES];
    [keyTextField becomeFirstResponder];

    
}

- (void)viewWillAppear:(BOOL)animated{
    [noConnectionLabel setHidden:[[SpeakUpManager sharedSpeakUpManager] connectionIsOK]];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = self.mapView.userLocation.coordinate;
    //mapRegion.span.latitudeDelta = 0.25;
    mapRegion.span.longitudeDelta = 0.008;
    [self.mapView setRegion:mapRegion animated: YES];
    [self.mapView regionThatFits:mapRegion];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if([[input text] length]>0){
        [self createRoom:nil];
    }
    return NO;
}

-(void)connectionWasLost{
    noConnectionLabel.backgroundColor = [UIColor colorWithRed:238.0/255.0 green:0.0/255.0 blue:58.0/255.0 alpha:1.0];//dark red color
    [noConnectionLabel setText:  NSLocalizedString(@"CONNECTION_LOST", nil)];
    [noConnectionLabel setHidden:NO];
}
-(void)connectionHasRecovered{
    noConnectionLabel.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:173.0/255.0 blue:121.0/255.0 alpha:1.0];//dark green color
    [noConnectionLabel setText: NSLocalizedString(@"CONNECTION_ESTABLISHED", nil)];
    [noConnectionLabel performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:3.0];
}

-(IBAction)createRoom:(id)sender{
    if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
        
        if([self.input.text isEqualToString:@"Waroftheworldviews"]){
            [[SpeakUpManager sharedSpeakUpManager] setIsSuperUser:YES];
            NSLog(@"YOU ARE A SUPER USER NOW :)");
            self.input.text=@"";
            [self.input setPlaceholder:@"You are super :)"];
        }else if(self.input.text.length>0){
            NSLog(@"creating a new room %@ ", input.text);
            Room* myRoom = [[Room alloc] init];
            if([[SpeakUpManager sharedSpeakUpManager] isSuperUser]){
                myRoom.isOfficial=YES;
            }
            myRoom.name = self.input.text;
            myRoom.latitude=self.mapView.userLocation.coordinate.latitude;
            myRoom.longitude=self.mapView.userLocation.coordinate.longitude;
            myRoom.range=RANGE;
            myRoom.lifetime=LIFETIME;
            myRoom.usesPseudonyms= pseudoSwitch.on;
            [[SpeakUpManager sharedSpeakUpManager] createRoom:myRoom];
            self.input.text=@"";
            [self.navigationController popViewControllerAnimated:YES];
        }
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
    }
}

-(IBAction)sendMail{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mfViewController = [[MFMailComposeViewController alloc] init];
        mfViewController.mailComposeDelegate = self;
        NSArray *toRecipients = [NSArray arrayWithObject:@"adrian.holzer@me.com"];
        [mfViewController setToRecipients:toRecipients];
        [mfViewController setSubject: NSLocalizedString(@"FEEDBACK", nil) ];
        
        [self presentViewController:mfViewController animated:YES completion:nil];
    }else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STATUS", nil)  message:NSLocalizedString(@"NO_MAIL", nil)  delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil)  otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STATUS", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    
    switch (result) {
        case MFMailComposeResultCancelled:
            alert.message = NSLocalizedString(@"MESSAGE_CANCELED", nil);
            break;
        case MFMailComposeResultSaved:
            alert.message = NSLocalizedString(@"MESSAGE_SAVED", nil);
            break;
        case MFMailComposeResultSent:
            alert.message = NSLocalizedString(@"MESSAGE_SENT", nil);
            break;
        case MFMailComposeResultFailed:
            alert.message = NSLocalizedString(@"MESSAGE_FAILED", nil);
            break;
        default:
            alert.message = NSLocalizedString(@"MESSAGE_NOT_SENT", nil);
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [alert show];
}

// used to limit the number of characters to MAX_LENGTH
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if(textField.text.length==0){
        [createButton setEnabled:NO];
    }
    NSUInteger newLength = (textField.text.length - range.length) + string.length;
    if(newLength <= MAX_LENGTH){
        [createButton setEnabled:YES];
        return YES;
    } 
    return NO;
}

-(IBAction)createOrUnlock:(id)sender{
    UISegmentedControl *seg = (UISegmentedControl *) sender;
    NSInteger selectedSegment = seg.selectedSegmentIndex;
    
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
        [input becomeFirstResponder];
        }else{
            [warningLabel setHidden:NO];
            [pseudoSwitch setHidden:YES];
            [pseudoLabel setHidden:YES];
            [mapView setHidden:YES];
            [input setHidden:YES];
            [createRoomButton setHidden:YES];
            [createRoomLabel setHidden:YES];
            }
    }else if(selectedSegment == UNLOCK_TAB){
        [warningLabel setHidden:YES];
        [pseudoSwitch setHidden:YES];
        [pseudoLabel setHidden:YES];
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
    // check if the label is ok, then pop the view
    [[[SpeakUpManager sharedSpeakUpManager] unlockedRoomKeyArray] addObject:keyTextField.text];
    [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID:nil  orRoomHash:keyTextField.text];
    // could wait for response and then enter the lobby
    [self.navigationController popViewControllerAnimated:YES];

}


- (IBAction)flip:(id)sender {
    if (pseudoSwitch.on){
       NSLog(@"Should use pseudo"); 
    }
    else  NSLog(@"Should not use pseudo");
}



@end
