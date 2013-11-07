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
#define MAX_LENGTH 30
#define RANGE 200 // a room has a 200 meter range
#define LIFETIME 720//message remain 12 hours in the room

@implementation NewRoomViewController


@synthesize createButton, input, mapView, connectionLostSpinner, segmentedControl, keyTextField, createRoomButton, unlockRoomButton,createRoomLabel, pseudoLabel, pseudoSwitch,warningLabel;


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
    UIColor *liteBlue = [UIColor colorWithRed:181.0/255.0 green:216.0/255.0 blue:248.0/255.0 alpha:1.0];// LITE BLUE
    UIColor *darkBlue = [UIColor colorWithRed:58.0/255.0 green:102.0/255.0 blue:159.0/255.0 alpha:1.0];// LITE GREY
    
    [segmentedControl setTitle:NSLocalizedString(@"UNLOCK", nil) forSegmentAtIndex:0];
    [segmentedControl setTitle:NSLocalizedString(@"CREATE", nil) forSegmentAtIndex:1];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [UIFont fontWithName:@"HelveticaNeue-Medium" size:16], UITextAttributeFont,
                                liteBlue, UITextAttributeTextColor,
                                nil];
    [segmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    NSDictionary *highlightedAttributes = [NSDictionary dictionaryWithObject:darkBlue forKey:UITextAttributeTextColor];
    [segmentedControl setTitleTextAttributes:highlightedAttributes forState:UIControlStateHighlighted];
    
    NSDictionary *selectedAttributes = [NSDictionary dictionaryWithObject: darkBlue forKey:UITextAttributeTextColor];
    [segmentedControl setTitleTextAttributes:selectedAttributes forState:UIControlStateSelected];

    
    //SEGMENTED VIEW CONTROL IMAGES
    [segmentedControl setBackgroundImage:[UIImage imageNamed:@"seg-selected3.png"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [segmentedControl setBackgroundImage:[UIImage imageNamed:@"seg-selected4.png"] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [segmentedControl setBackgroundImage:[UIImage imageNamed:@"seg-selected4.png"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [segmentedControl setDividerImage:[UIImage imageNamed:@"seg-div3.png"] forLeftSegmentState:UIControlStateSelected  rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [segmentedControl setDividerImage:[UIImage imageNamed:@"seg-div3.png"] forLeftSegmentState:UIControlStateNormal  rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
     [segmentedControl setDividerImage:[UIImage imageNamed:@"seg-div3.png"] forLeftSegmentState:UIControlStateNormal  rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  
    
    // UNLOCK BUTTON
    [unlockRoomButton setTitle:NSLocalizedString(@"UNLOCK", nil) forState:UIControlStateNormal];
    unlockRoomButton.layer.masksToBounds=YES;
    unlockRoomButton.layer.cornerRadius=2.0f;
    [unlockRoomButton setTitleColor: [UIColor lightGrayColor ] forState:UIControlStateHighlighted];
    [unlockRoomButton setBackgroundImage:[UIImage imageNamed:@"seg-selected3.png"] forState:UIControlStateNormal];
   // [unlockRoomButton setBackgroundImage:[UIImage imageNamed:@"seg-selected4.png"] forState:UIControlStateSelected];
    
    //PSEUDO LABEL
    [pseudoLabel setText:NSLocalizedString(@"PSEUDO", nil)];
    
    //WARNING LABEL
    //[warningLabel setText:NSLocalizedString(@"TURN_LOCATION_ON", nil)];
    [warningLabel setText:NSLocalizedString(@"JOIN_ROOM_INFO", nil)];
    
    // HIDE CREATION STUFF AND SHOW UNLOCK STUFF
    [mapView setHidden:YES];
    [input setHidden:YES];
    [pseudoSwitch setHidden:YES];
    [pseudoLabel setHidden:YES];
    [createRoomButton setHidden:YES];
    [unlockRoomButton setHidden:NO];
    [keyTextField setHidden:NO];
    [createRoomLabel setHidden:YES];
    [warningLabel setHidden:NO];
    [keyTextField becomeFirstResponder];


    
}

- (void)viewWillAppear:(BOOL)animated{
    if ([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
        [connectionLostSpinner stopAnimating];
    }else{
        [connectionLostSpinner startAnimating];
    }

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
    [connectionLostSpinner startAnimating];
}
-(void)connectionHasRecovered{
    [connectionLostSpinner stopAnimating];
}

-(IBAction)createRoom:(id)sender{
    if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
        
        /*if([self.input.text isEqualToString:@"Waroftheworldviews"]){
            [[SpeakUpManager sharedSpeakUpManager] setIsSuperUser:YES];
            NSLog(@"YOU ARE A SUPER USER NOW :)");
            self.input.text=@"";
            [self.input setPlaceholder:@"You are super :)"];
        }else*/
        NSString *trimmedString = [input.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if(self.input.text.length>0 && trimmedString.length >0){
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
            
            if (pseudoSwitch.on) {
                myRoom.id_type= AVATAR;
            }else{
                myRoom.id_type = ANONYMOUS;
            }
            [[SpeakUpManager sharedSpeakUpManager] createRoom:myRoom];
            self.input.text=@"";
            [self.navigationController popViewControllerAnimated:YES];
        }
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
    }
}




// used to limit the number of characters to MAX_LENGTH
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    

    
    //if(textField.text.length==0 ){
      //  [createButton setEnabled:NO];
    //}
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
        [warningLabel setHidden:NO];
        [pseudoSwitch setHidden:YES];
        [pseudoLabel setHidden:YES];
      [mapView setHidden:YES];
        [input setHidden:YES];
        [createRoomButton setHidden:YES];
        [unlockRoomButton setHidden:NO];
        [keyTextField setHidden:NO];
         [createRoomLabel setHidden:YES];
        [keyTextField becomeFirstResponder];
        [warningLabel setText:NSLocalizedString(@"JOIN_ROOM_INFO", nil)];
    }
    
    
}

- (IBAction)unlock:(id)sender {
    if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
    // check if the label is ok, then pop the view
    [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID:nil  orRoomHash:keyTextField.text];
    // could wait for response and then enter the lobby
    [self.navigationController popViewControllerAnimated:YES];
    }

}


- (IBAction)flip:(id)sender {
    if (pseudoSwitch.on){
       NSLog(@"Should use pseudo"); 
    }
    else  NSLog(@"Should not use pseudo");
}



@end
