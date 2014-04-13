//
//  ProfileTableViewController.m
//
//  Created by Adrian Holzer on 20.12.11.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "MessageTableViewController.h"
#import "Message.h"
#import "SpeakUpManager.h"
#import "MessageCell.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"


#define CELL_CONTENT_WIDTH 280.0f
#define CELL_CONTENT_MARGIN 10.0f
#define CELL_MIN_SIZE 80.0
#define CELL_MAX_SIZE 9999.0f
#define YES_NO_LOGO_WIDTH 40
#define YES_NO_LOGO_HEIGHT 36
#define YES_LOGO_HORIZONTAL_OFFSET 200
#define NO_LOGO_HORIZONTAL_OFFSET 250
#define FOOTER_OFFSET 60 // space below the text
#define HEADER_OFFSET 45 // not used
#define CELL_VERTICAL_OFFSET 65 // not used
#define TEXT_WIDTH 280
#define SIDES 40
#define EXPIRATION_DURATION_IN_HOURS 24


#define INPUTVIEW_HEIGHT 40

@implementation MessageTableViewController

@synthesize roomNameLabel, segmentedControl, connectionLostSpinner, inputView, keyboardIsVisible,keyboardHeight, inputButton, inputTextView,showKey,roomNumberLabel,expirationLabel,isFirstMessageUpdate,roomInfoLabel;




#pragma mark - View lifecycle
//=========================
// LOAD VIEW
//=========================
- (void)viewDidLoad
{

    [super viewDidLoad];
    
   // UIColor *darkBlue = [UIColor colorWithRed:58.0/255.0 green:102.0/255.0 blue:159.0/255.0 alpha:1.0];
   // UIColor *mediumBlue = [UIColor colorWithRed:110.0/255.0 green:195.0/255.0 blue:245.0/255.0 alpha:1.0];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor whiteColor];
    //[self.roomNameLabel setText:[[[SpeakUpManager sharedSpeakUpManager] currentRoom]name]];
    [[SpeakUpManager sharedSpeakUpManager] setMessageManagerDelegate:self];
    
    // BACK BUTTON START
    UIButton *newBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [newBackButton setImage:[UIImage imageNamed: @"button-back1.png"] forState:UIControlStateNormal];
    
    [newBackButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    newBackButton.frame = CGRectMake(5, 5, 30, 30);
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:newBackButton];
    // BACK BUTTON END
    
    
    [segmentedControl setTitle:NSLocalizedString(@"RATING_SORT", nil) forSegmentAtIndex:0];
    [segmentedControl setTitle:NSLocalizedString(@"RECENT_SORT", nil) forSegmentAtIndex:1];
    [segmentedControl setSelectedSegmentIndex:0];// a small routine to avoid a weird color bug
    [segmentedControl setSelectedSegmentIndex:1];
    
    
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

    [roomNameLabel setText:[[[SpeakUpManager sharedSpeakUpManager] currentRoom]name]];
    [roomNumberLabel setText:[[[SpeakUpManager sharedSpeakUpManager] currentRoom]key]];
    
    /// INPUT VIEW
    keyboardIsVisible=NO;
    keyboardHeight=0;
    
   inputView = [[UIView alloc] initWithFrame:CGRectMake(0,self.tableView.contentOffset.y+(self.tableView.frame.size.height-INPUTVIEW_HEIGHT),self.view.frame.size.width,INPUTVIEW_HEIGHT)];
    
    inputView.backgroundColor = myPurple;
    [self.view addSubview:inputView];
    inputTextView.text=@"";

    inputButton = [UIButton buttonWithType:UIButtonTypeCustom];
    inputButton.layer.masksToBounds=YES;
    inputButton.layer.cornerRadius=4.0f;
    
    [inputButton setTitleColor: [UIColor whiteColor ] forState:UIControlStateNormal];
    [inputButton setTitleColor: myGrey forState:UIControlStateHighlighted];
    
    [inputButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Light" size:MediumFontSize]];
    [inputButton addTarget:self action:@selector(sendInput:) forControlEvents:UIControlEventTouchUpInside];
    [inputButton setTitle:NSLocalizedString(@"SEND", nil) forState:UIControlStateNormal];
    
    inputButton.titleLabel.numberOfLines = 1;
    inputButton.titleLabel.adjustsFontSizeToFitWidth = YES;

    
    inputButton.frame = CGRectMake(self.view.frame.size.width-80, 5 , 70, 30);

    [inputView addSubview:inputButton];

    inputTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, 5, self.view.frame.size.width-100, 30)];
    //textView.borderStyle = UITextBorderStyleRoundedRect;
    inputTextView.font = [UIFont systemFontOfSize:MediumFontSize];

    //textView.placeholder = @"enter text";
    inputTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    inputTextView.keyboardType = UIKeyboardTypeDefault;
    inputTextView.returnKeyType = UIReturnKeyDone;
    inputTextView.layer.cornerRadius=0;
    
    [inputTextView setDelegate:self];
    [inputView addSubview:inputTextView];
    
    // MANAGE KEYBOARD
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // LISTEN TO TOUCH EVENT
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    tgr.delegate = self;
    [self.tableView addGestureRecognizer:tgr]; // or [self.view addGestureRecognizer:tgr];

    
}
- (void)viewTapped:(UITapGestureRecognizer *)tgr
{
    NSLog(@"view tapped");
    [inputTextView resignFirstResponder ];
    // remove keyboard
}


- (void)placeInputView{
    CGRect newFrame = inputView.frame;
    newFrame.origin.x = 0;
    newFrame.origin.y = self.tableView.contentOffset.y+(self.tableView.frame.size.height-INPUTVIEW_HEIGHT)-keyboardHeight;
    inputView.frame = newFrame;
}

- (void)viewDidAppear:(BOOL)animated
{
    // need this since view did load does not correctly calculate the size of the screen
    [self placeInputView];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    //Assign new frame to your view
    keyboardIsVisible=YES;
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    self.keyboardHeight= keyboardFrameBeginRect.size.height;

    [UIView animateWithDuration:0.3 animations:^{
        [self.inputView setFrame:CGRectMake(0,self.inputView.frame.origin.y-keyboardFrameBeginRect.size.height,self.inputView.frame.size.width,self.inputView.frame.size.height)];
    }];
}

-(void)keyboardDidHide:(NSNotification *)notification
{
    //Assign new frame to your view
    keyboardIsVisible=NO;
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    self.keyboardHeight= 0;
    [UIView animateWithDuration:0.3 animations:^{
        [self.inputView setFrame:CGRectMake(0,self.inputView.frame.origin.y+keyboardFrameBeginRect.size.height,self.inputView.frame.size.width,self.inputView.frame.size.height)];
    }];
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self placeInputView];
}

- (void)viewWillAppear:(BOOL)animated
{
     isFirstMessageUpdate=YES;
    roomInfoLabel.text=@"";
    [[SpeakUpManager sharedSpeakUpManager] setConnectionDelegate:self];
        if ([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
            [connectionLostSpinner stopAnimating];
        }else{
            [connectionLostSpinner startAnimating];
        }
    
    
    //============================================
    // EXPIRATION TIME 24 hours since last change
    //============================================
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *lastUpdateTime = [dateFormatter dateFromString:[[[SpeakUpManager sharedSpeakUpManager] currentRoom]lastUpdateTime]];
    NSTimeInterval elapsedTimeSinceUpdate = [lastUpdateTime timeIntervalSinceNow];
    //24*3600-elapsedTimeSinceUpdate= time remaining in seconds,
    NSInteger timeToExpirationInSeconds = EXPIRATION_DURATION_IN_HOURS*3600 + (int)elapsedTimeSinceUpdate;
    NSInteger minutes = (timeToExpirationInSeconds / 60) % 60;
    NSInteger hours = (timeToExpirationInSeconds / 3600);
    NSString* time=@"";
    if(minutes  <1 && hours  <1){
        time = NSLocalizedString(@"ABOUT_TO_CLOSE", nil);
    }else if(minutes>0 && hours == 0){
        time = [NSString stringWithFormat:  NSLocalizedString(@"CLOSES_IN_MINUTES", nil),minutes];
    }else {
        time = [NSString stringWithFormat:  NSLocalizedString(@"CLOSES_IN_HOURS", nil),hours];
    }
    [expirationLabel setText: time];
    
    
    
    [self sortMessages];
    [self.tableView reloadData];
    [super viewWillAppear:animated];
    //GOOGLE TRACKER
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Message Screen"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    [[[SpeakUpManager sharedSpeakUpManager] deletedMessageIDs] removeAllObjects];
    
     [self placeInputView];
    
}

-(void)resetTimer{
   [expirationLabel setText: [NSString stringWithFormat:  NSLocalizedString(@"CLOSES_IN_HOURS", nil),EXPIRATION_DURATION_IN_HOURS]];
}



-(void)notifyThatRoomHasBeenDeleted:(Room*) room{
    if ([room.roomID isEqual:[[[SpeakUpManager sharedSpeakUpManager] currentRoom] roomID]]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"ROOM_CLOSED", nil)
                                                        message:[NSString stringWithFormat: NSLocalizedString(@"ROOM_CLOSED_LONG", nil) , [[[SpeakUpManager sharedSpeakUpManager] currentRoom]name]]
                                                       delegate:nil
                                              cancelButtonTitle: NSLocalizedString(@"OK", nil) 
                                              otherButtonTitles:nil];
        [alert show];
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [[SpeakUpManager sharedSpeakUpManager] savePeerData];
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
    
}
//=========================
// HANDLES SECTIONS AND ROWS
//=========================
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages]==nil){
        [connectionLostSpinner startAnimating];
        return 0;
    }
    [connectionLostSpinner stopAnimating];
    if ([[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages] count]==0){
        return 1;
    }
    return [[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages] count];
}

//=========================
// LOADS DATA
//=========================
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // check this site
    // http://www.cimgf.com/2009/09/23/uitableviewcell-dynamic-height/
    //if there is no room, simply put this no room cell

    
    
    if ([[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages] count]==0){
        //static
        NSString *CellIdentifier = @"NoMessageCell";
        MessageCell *cell = (MessageCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[MessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        UITextView *noMessageView = (UITextView *)[cell viewWithTag:1];
        [noMessageView setText:NSLocalizedString(@"NO_MESSAGE", nil)];
        //=========================
        // MESSAGE LABEL
        //=========================
        //UILabel *backgroundLabel = (UILabel *)[cell viewWithTag:12];
        //backgroundLabel.backgroundColor=[UIColor whiteColor];
        //backgroundLabel.layer.cornerRadius  =2;
        //backgroundLabel.layer.shadowColor  = [[UIColor blackColor] CGColor];
        return cell;
    }
    else{
        Message* message = [self getMessageForIndex:[indexPath row]];
        NSString *CellIdentifier = @"MessageCell";
        MessageCell *cell = (MessageCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[MessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        //=========================
        // CONTENT
        //=========================
        cell.message=message;
        // CONTENT - set up the content
        UITextView *contentTextView = (UITextView *)[cell viewWithTag:10];
        NSString * text = [message content];
        CGSize textViewConstraint = CGSizeMake(contentTextView.frame.size.width,CELL_MAX_SIZE);
        CGSize size = [text sizeWithFont:contentTextView.font constrainedToSize:textViewConstraint lineBreakMode:NSLineBreakByWordWrapping];
        [contentTextView setText:text];
        [contentTextView setFrame:CGRectMake(contentTextView.frame.origin.x, contentTextView.frame.origin.y, contentTextView.frame.size.width, size.height+1000)];// ADER this size is there to avoid cut off text if someone type one line and an empty line....

        //=========================
        // THUMBS
        //=========================
        UIButton *thumbUpButton = (UIButton *)[cell viewWithTag:3];
        NSString* rowInString = [NSString stringWithFormat:@"%d",indexPath.row];
        [thumbUpButton setTitle:rowInString forState:UIControlStateNormal];
        if([[[SpeakUpManager sharedSpeakUpManager] likedMessages]  containsObject:message.messageID]){
            [thumbUpButton setImage:[UIImage imageNamed:@"tUpP1.png"] forState:UIControlStateNormal] ;
        }else{
            [thumbUpButton setImage:[UIImage imageNamed:@"tUp1.png"] forState:UIControlStateNormal] ;
        }
        UIButton *thumbDownButton = (UIButton *)[cell viewWithTag:5];
        [thumbDownButton setTitle:rowInString forState:UIControlStateNormal];
        if([[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  containsObject:message.messageID]){
            [thumbDownButton setImage:[UIImage imageNamed:@"tDownP1.png"] forState:UIControlStateNormal] ;
        }else {
            [thumbDownButton setImage:[UIImage imageNamed:@"tDown1.png"] forState:UIControlStateNormal] ;
        }
        //=========================
        // TIME
        //=========================
        UILabel *timeLabel = (UILabel *)[cell viewWithTag:6];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        NSDate *messageCreationTime = [dateFormatter dateFromString:message.creationTime];
        NSTimeInterval elapsedTimeSinceMessageCreation = [messageCreationTime timeIntervalSinceNow];
        message.secondsSinceCreation = elapsedTimeSinceMessageCreation;
        NSInteger minutes = -(message.secondsSinceCreation / 60) % 60;
        NSInteger hours = -(message.secondsSinceCreation / 3600);
        NSString* time=@"";
        if(minutes  <1 && hours  <1){
            time = NSLocalizedString(@"JUST_NOW", nil);
        }else if(minutes>0 && hours == 0){
            time = [NSString stringWithFormat:  NSLocalizedString(@"MINUTES_AGO", nil),minutes];
        }else {
            time = [NSString stringWithFormat:  NSLocalizedString(@"HOURS_AGO", nil),hours];
        }
        [timeLabel setText: time];
        //=========================
        // MESSAGE LABEL
        //=========================
        UILabel *backgroundLabel = (UILabel *)[cell viewWithTag:12];
        backgroundLabel.backgroundColor=[UIColor whiteColor];
        backgroundLabel.layer.cornerRadius  =2;
        backgroundLabel.layer.shadowColor  = [[UIColor blackColor] CGColor];
        //=========================
        // SCORE
        //=========================
        UILabel *scoreLabel = (UILabel *)[cell viewWithTag:7];
         scoreLabel.textColor= [UIColor blackColor];
        if(message.score>0){
            //scoreLabel.textColor = [UIColor colorWithRed:0.0/255.0 green:173.0/255.0 blue:121.0/255.0 alpha:1.0];//dark green color
           
            [scoreLabel setText: [NSString stringWithFormat:@"+%d", message.score]];
        }else if(message.score<0){
            //scoreLabel.textColor = [UIColor colorWithRed:238.0/255.0 green:0.0/255.0 blue:58.0/255.0 alpha:1.0];//dark red color
            [scoreLabel setText: [NSString stringWithFormat:@"%d", message.score]];
        }else{
           // scoreLabel.textColor = [UIColor grayColor];
            [scoreLabel setText: @"0"];
        }
        UILabel *numberofVotesLabel = (UILabel *)[cell viewWithTag:8];
        int numberOfVotes= message.numberOfNo + message.numberOfYes;
        if(numberOfVotes<2){
            [numberofVotesLabel setText: [NSString stringWithFormat:  NSLocalizedString(@"VOTE", nil), numberOfVotes]];
        }else{
            [numberofVotesLabel setText: [NSString stringWithFormat: NSLocalizedString(@"VOTES", nil) , numberOfVotes]];
        }
        //=========================
        // AVATAR
        //=========================
        if ([[[[SpeakUpManager sharedSpeakUpManager] currentRoom] id_type] isEqualToString:AVATAR]) {
            UIImageView *avatarView = (UIImageView *)[cell viewWithTag:11];
   
            UIImage* avatarImage = [[[[SpeakUpManager sharedSpeakUpManager] currentRoom] avatarCacheByPeerID] objectForKey:message.authorPeerID];
            if (!avatarImage) {
                avatarImage= [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:message.avatarURL]]];
                [[[[SpeakUpManager sharedSpeakUpManager] currentRoom] avatarCacheByPeerID] setObject:avatarImage forKey:message.authorPeerID];
            }
            [avatarView setImage:avatarImage];
            //avatarView.layer.cornerRadius = 5;
        }
        return cell;
    }
}
//=========================
// GET MESSAGE FOR INDEX
//=========================
-(Message*)getMessageForIndex:(NSInteger)index{
    if ([[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages] count]>0){
        return (Message *)[[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages] objectAtIndex:index];
    }
    return nil;
}
//=========================
// SORT
//=========================
-(IBAction)sortBy:(id)sender{
    UISegmentedControl *seg = (UISegmentedControl *) sender;
    NSInteger selectedSegment = seg.selectedSegmentIndex;
    NSString* eventName;
    
    if (selectedSegment == 0) {
        [[[SpeakUpManager sharedSpeakUpManager] currentRoom] setMessagesSortedBy:BEST_RATING];
        eventName=@"score_message_ordering_tab";
    }else if(selectedSegment == 1){
        [[[SpeakUpManager sharedSpeakUpManager] currentRoom] setMessagesSortedBy:MOST_RECENT];
        eventName=@"time_message_ordering_tab";
    }
    [self sortMessages];
    [self.tableView reloadData];
    NSIndexPath *myIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:myIndexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
    
    // GOOGLE ANALYTICS
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"tab_change"  // Event action (required)
                                                           label:eventName          // Event label
                                                           value:nil] build]];    // Event value
}
//=========================
// CONNECTION HANDLING
//=========================
-(void)connectionWasLost{
    [connectionLostSpinner startAnimating];
}
-(void)connectionHasRecovered{
    [connectionLostSpinner stopAnimating];
}
//=========================
// RATING UP
//=========================
-(IBAction)rateMessageUp:(id)sender{
    if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
    @synchronized(self){
        NSString* messageID;
        int yesRating = 0;
        int noRating = 0;
        UIButton *aButton = (UIButton *)sender;
        NSString* rowInString = [aButton titleForState:UIControlStateNormal];
        NSUInteger row = [rowInString integerValue];
        Message* message = [self getMessageForIndex:row];
        messageID = message.messageID;
        if (messageID) {
        //if the message was disliked, remove the message from the list of disliked messages and add it to the liked messages
        if([[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  containsObject:message.messageID]){
            [[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  removeObject:message.messageID];
            noRating = -1;
            [[[SpeakUpManager sharedSpeakUpManager] likedMessages]  addObject:message.messageID];
            yesRating=1;
        }
        //else if the message was liked remove it from the list of liked messages
        else if([[[SpeakUpManager sharedSpeakUpManager] likedMessages]  containsObject:message.messageID]){
            [[[SpeakUpManager sharedSpeakUpManager] likedMessages]  removeObject:message.messageID];
            yesRating=-1;
        }
        // else (i.e., when the message was neither liked or dislike, add it to the list of like messages)
        else{
            [[[SpeakUpManager sharedSpeakUpManager] likedMessages]  addObject:message.messageID];
            yesRating=1;
        }
        // update the message rating on the server
        [[SpeakUpManager sharedSpeakUpManager] rateMessage:messageID inRoom:[[SpeakUpManager sharedSpeakUpManager] currentRoomID] yesRating:yesRating noRating:noRating];
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
        }else{
            NSLog(@"the message %@ does not have an id",[message description]);
        }
        [self.tableView reloadData];
        // GOOGLE ANALYTICS
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                              action:@"button_press"  // Event action (required)
                                                               label:@"thumb_up"          // Event label
                                                               value:nil] build]];    // Event value
    }
    }
}
//=========================
// RATING DOWN
//=========================
-(IBAction)rateMessageDown:(id)sender{
     if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
    @synchronized(self){
        NSString* messageID;
        int yesRating = 0;
        int noRating = 0;
        UIButton *aButton = (UIButton *)sender;
        NSString* rowInString = [aButton titleForState:UIControlStateNormal];
        NSUInteger row = [rowInString integerValue];
        Message* message = [self getMessageForIndex:row];
        messageID = message.messageID;
        if (messageID) {
        //if the message was disliked, remove the message from the list of disliked messages
        if([[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  containsObject:message.messageID]){
            [[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  removeObject:message.messageID];
            noRating--;
        }
        //else if the message was liked remove it from the list of liked messages and add it to the disliked messages
        else if([[[SpeakUpManager sharedSpeakUpManager] likedMessages]  containsObject:message.messageID]){
            [[[SpeakUpManager sharedSpeakUpManager] likedMessages]  removeObject:message.messageID];
            yesRating--;
            [[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  addObject:message.messageID];
            noRating++;
        }
        // else (i.e., when the message was neither liked or dislike, add it to the list of disliked messages)
        else{
            [[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  addObject:messageID];
            noRating++;
        }
        // update the message rating on the server
        [[SpeakUpManager sharedSpeakUpManager] rateMessage:messageID inRoom:[[SpeakUpManager sharedSpeakUpManager] currentRoomID] yesRating:yesRating noRating:noRating];
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
        }else{
            NSLog(@"the message %@ does not have an id",[message description]);
        }
       [self.tableView reloadData];
        // GOOGLE ANALYTICS
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                              action:@"button_press"  // Event action (required)
                                                               label:@"thumb_down"          // Event label
                                                               value:nil] build]];    // Event value
    }
     }
}
//=========================
// SLIDE TO DELETE
//=========================
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Hide";
}
// DELETE
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Message* message = [self getMessageForIndex:indexPath.row];
        [[[[SpeakUpManager sharedSpeakUpManager] currentRoom]messages] removeObject:message];
        [[SpeakUpManager sharedSpeakUpManager] deleteMessage:message];
        [tableView reloadData];
    }
}
//=========================
// RECEIVE NEW MESSAGES
//=========================
-(void)updateMessagesInRoom:(NSString*) roomID{
    //maybe we can use a room ID and if the room ID is equal to the current room, then there is an update, not otherwise.
    if([roomID isEqual:[[SpeakUpManager sharedSpeakUpManager] currentRoomID]]){
        if(!self.editing){
            [self sortMessages];
            [self.tableView reloadData];
            [self setRoomInfo];
            if (isFirstMessageUpdate) {
                isFirstMessageUpdate=NO;
            }else{
                [self resetTimer];// puts timer back to 24 hours but only if its not the first time
            }

        }
       
    }
}

-(void)setRoomInfo{
    int numberofmessages = (int)[[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages] count];
    int numberofvotes=0;
    for (Message* message in [[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages]){
        numberofvotes+=message.numberOfNo + message.numberOfYes;
    }
    if (numberofmessages ==0){
       roomInfoLabel.text= @"";
    }else if (numberofmessages <2 && numberofvotes<2) {
       roomInfoLabel.text= [NSString stringWithFormat:  NSLocalizedString(@"ROOM_INFO_11", nil),numberofmessages,numberofvotes];
    }else if (numberofmessages <2 && numberofvotes>=2)  {
        roomInfoLabel.text= [NSString stringWithFormat:  NSLocalizedString(@"ROOM_INFO_12", nil),numberofmessages,numberofvotes];
    }else if (numberofmessages >=2 && numberofvotes<2)  {
        roomInfoLabel.text= [NSString stringWithFormat:  NSLocalizedString(@"ROOM_INFO_21", nil),numberofmessages,numberofvotes];
    }else{
        roomInfoLabel.text= [NSString stringWithFormat:  NSLocalizedString(@"ROOM_INFO_22", nil),numberofmessages,numberofvotes];
    }
    
    
    //roomInfoLabel.text= [NSString stringWithFormat:  NSLocalizedString(@"ROOM_INFO", nil),numberofmessages,numberofvotes];
    
}
//=========================
// GET HEIGHT FOR ROW
//=========================
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if ([[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages] count]==0) {
        return self.view.frame.size.height - 145;//big enough to put the expiration at the bottom
    }
    
    NSUInteger row = [indexPath row];
    Message* message = [self getMessageForIndex:row];
    NSString *text = message.content;
    CGSize textViewConstraint = CGSizeMake(self.view.frame.size.width-SIDES,CELL_MAX_SIZE);
    CGSize size = [text sizeWithFont:[UIFont fontWithName:@"Helvetica-Light" size:NormalFontSize] constrainedToSize:textViewConstraint lineBreakMode:NSLineBreakByWordWrapping];// ADER get font from cell
    return size.height +FOOTER_OFFSET + HEADER_OFFSET;
    
}


// SORTING
-(void) sortMessages{
    if ([[[SpeakUpManager sharedSpeakUpManager] currentRoom]messagesSortedBy]==MOST_RECENT) {
        [[[SpeakUpManager sharedSpeakUpManager] currentRoom] setMessages:  [self sortMessagesByTime:[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages]]];
    }else{
        [[[SpeakUpManager sharedSpeakUpManager] currentRoom] setMessages:  [self sortMessagesByScore:[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages]]];
    }
}
-(NSMutableArray*) sortMessagesByScore:(NSMutableArray*)messages{
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO];
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [messages sortedArrayUsingDescriptors:sortDescriptors];
    return [sortedArray mutableCopy];
}
-(NSMutableArray*) sortMessagesByTime:(NSMutableArray*)messages{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    for (Message* message in messages){
        NSDate *messageCreationTime = [dateFormatter dateFromString:message.creationTime];
        NSTimeInterval elapsedTimeSinceMessageCreation = [messageCreationTime timeIntervalSinceNow];
        message.secondsSinceCreation = elapsedTimeSinceMessageCreation;
    }
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"secondsSinceCreation" ascending:NO];
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [messages sortedArrayUsingDescriptors:sortDescriptors];
    return [sortedArray mutableCopy];
}



// INPUT METHODS
- (void)textViewDidChange:(UITextView *)textView
{
    int characterNumber = [[inputTextView text] length];
    //[characterCounterLabel setText:[NSString stringWithFormat:@"%d / %d", characterNumber, MAX_LENGTH]];
    // update the input
    [[SpeakUpManager sharedSpeakUpManager] setInputText:inputTextView.text];
    [inputButton setEnabled:NO];
    if(characterNumber>0){
        [inputButton setEnabled:YES];
    }
}


// used to limit the number of characters to MAX_LENGTH
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [inputTextView resignFirstResponder];
        return NO;
    }
    NSUInteger newLength = (textView.text.length - range.length) + text.length;
    if(newLength <= 500)
    {
        return YES;
    }
    return NO;
}
    
-(IBAction)sendInput:(id)sender{
    if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
        // should send the message first
        if(![inputTextView.text isEqualToString:@""]){
            // create a new message
            Message *newMessage = [[Message alloc] init];
            newMessage.content= inputTextView.text;
            newMessage.roomID=[[[SpeakUpManager sharedSpeakUpManager] currentRoom] roomID];
            [[SpeakUpManager sharedSpeakUpManager] createMessage:newMessage];
            [inputTextView setText:@""];
            //update the input
            [inputTextView resignFirstResponder];
            [[SpeakUpManager sharedSpeakUpManager] setInputText:inputTextView.text];
            [[SpeakUpManager sharedSpeakUpManager] savePeerData];
            // GOOGLE ANALYTICS
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                                  action:@"button_press"  // Event action (required)
                                                                   label:@"send"          // Event label
                                                                   value:nil] build]];    // Event value
        }
    }
}



@end