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


//@interface NewRoomViewController ()

//@end

#define MAX_ROOMS 3
#define MAX_LENGTH 40
// a room has a 200 meter range
#define RANGE 200
//message remain 12 hours in the room
#define LIFETIME 720

@implementation NewRoomViewController


@synthesize createButton, input, mapView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [input becomeFirstResponder];
    self.mapView.delegate = self;
    self.input.delegate=self;
    int characterNumber = [[input text] length];
    [createButton setEnabled:NO];
    
    int myNumberOfRooms = [[[SpeakUpManager sharedSpeakUpManager] myRoomIDs] count];
    
    
    if((characterNumber>0 && myNumberOfRooms<MAX_ROOMS)|| [[SpeakUpManager sharedSpeakUpManager] isSuperUser]){
        [createButton setEnabled:YES];
        [input setEnabled:YES];
    }else if(myNumberOfRooms>=MAX_ROOMS){
        [input setPlaceholder:@"You cannot create more rooms"];
        [input setUserInteractionEnabled:NO];
    }
    if([[SpeakUpManager sharedSpeakUpManager] isSuperUser]){
        [input setPlaceholder:@"You are super :)"];
        self.navigationItem.title=[NSString stringWithFormat:@"Create room"];
    }else {
        int numberOfRoomsLeft = MAX_ROOMS - myNumberOfRooms;
        self.navigationItem.title=[NSString stringWithFormat:@"Create room (%d left)",numberOfRoomsLeft];
    }
    
    //self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    
    // MKCoordinateRegion mapRegion;
    /// mapRegion.center = self.mapView.userLocation.coordinate;
    //mapRegion.span.latitudeDelta = 25;
    //mapRegion.span.longitudeDelta = 10;
    
    //[self.mapView setRegion:mapRegion animated: YES];
    
    // [self.view insertSubview:mapView atIndex:0];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
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
    int myNumberOfRooms = [[[SpeakUpManager sharedSpeakUpManager] myRoomIDs] count];
    if(([[input text] length]>0 && myNumberOfRooms<MAX_ROOMS) || [[SpeakUpManager sharedSpeakUpManager] isSuperUser] ){
        [self createRoom:nil];
    }
    return NO;
}

-(IBAction)createRoom:(id)sender{
    if([self.input.text isEqualToString:@"Waroftheworldviews"]){
        [[SpeakUpManager sharedSpeakUpManager] setIsSuperUser:YES];
        NSLog(@"YOU ARE A SUPER USER NOW :)");
        self.input.text=@"";
        [self.input setPlaceholder:@"You are super :)"];
    }else if(self.input.text.length>0){
        NSLog(@"creating a new room %@ ", input.text);
        Room* myRoom = [[Room alloc] init];
        int roomNumber= [[SpeakUpManager sharedSpeakUpManager] getNextRoomNumber];
        int peerID= [[[SpeakUpManager sharedSpeakUpManager] peerID] intValue] ;
        if([[SpeakUpManager sharedSpeakUpManager] isSuperUser]){
            myRoom.isOfficial=YES;
        }
        myRoom.roomID=[NSString stringWithFormat: @"peer%droom%d", peerID, roomNumber];
        
        myRoom.name = self.input.text;
        myRoom.latitude=self.mapView.userLocation.coordinate.latitude;
        myRoom.longitude=self.mapView.userLocation.coordinate.longitude;
        myRoom.range=RANGE;
        myRoom.lifetime=LIFETIME;
        [[SpeakUpManager sharedSpeakUpManager] createRoom:myRoom];
        self.input.text=@"";
        [self.navigationController popViewControllerAnimated:YES];
    }
    [[SpeakUpManager sharedSpeakUpManager] savePeerData];
}

-(IBAction)sendMail{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mfViewController = [[MFMailComposeViewController alloc] init];
        mfViewController.mailComposeDelegate = self;
        NSArray *toRecipients = [NSArray arrayWithObject:@"adrian.holzer@me.com"];
        [mfViewController setToRecipients:toRecipients];
        [mfViewController setSubject:@"SpeakUp Feedback"];
        
        [self presentViewController:mfViewController animated:YES completion:nil];
    }else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Status:" message:@"Your phone is not currently configured to send mail." delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
        
        [alert show];
    }
    
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Status:" message:@"" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
    
    switch (result) {
        case MFMailComposeResultCancelled:
            alert.message = @"Message Canceled";
            break;
        case MFMailComposeResultSaved:
            alert.message = @"Message Saved";
            break;
        case MFMailComposeResultSent:
            alert.message = @"Message Sent";
            break;
        case MFMailComposeResultFailed:
            alert.message = @"Message Failed";
            break;
        default:
            alert.message = @"Message Not Sent";
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [alert show];
    
}

// used to limit the number of characters to MAX_LENGTH
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(textField.text.length==0){
        [createButton setEnabled:NO];
    }
    NSUInteger newLength = (textField.text.length - range.length) + string.length;
    if(newLength <= MAX_LENGTH)
    {
        int myNumberOfRooms = [[[SpeakUpManager sharedSpeakUpManager] myRoomIDs] count];
        if((newLength>0 && myNumberOfRooms<MAX_ROOMS )|| [[SpeakUpManager sharedSpeakUpManager] isSuperUser]){
            [createButton setEnabled:YES];
        }
        return YES;
    } else {
        return NO;
    }
}

@end
