//
//  ProfileTableViewController.m
//
//  Created by Adrian Holzer on 20.12.11.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "MessageTableViewController.h"
#import "InputViewController.h"
#import "Message.h"
#import "SpeakUpManager.h"
#import "MessageCell.h"

#define FONT_SIZE 17.0f
#define CELL_CONTENT_WIDTH 280.0f
#define CELL_CONTENT_MARGIN 10.0f
#define CELL_MIN_SIZE 65.0f
#define CELL_MAX_SIZE 500.0f
#define YES_NO_LOGO_WIDTH 40
#define YES_NO_LOGO_HEIGHT 36
#define YES_LOGO_HORIZONTAL_OFFSET 200
#define NO_LOGO_HORIZONTAL_OFFSET 250
#define YES_NO_LOGO_VERTICAL_OFFSET 40
#define CELL_VERTICAL_OFFSET 65

@implementation MessageTableViewController

@synthesize roomNameLabel, segmentedControl, noConnectionLabel ;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
            }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor whiteColor];
    [self.roomNameLabel setText:[[[SpeakUpManager sharedSpeakUpManager] currentRoom]name]];
    [[SpeakUpManager sharedSpeakUpManager] setMessageManagerDelegate:self];
    
    // BACK BUTTON START
    UIButton *newBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [newBackButton setImage:[UIImage imageNamed: @"button-back1.png"] forState:UIControlStateNormal];
    [newBackButton setImage:[UIImage imageNamed: @"button-back2.png"] forState:UIControlStateSelected];
    [newBackButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    newBackButton.frame = CGRectMake(5, 5, 30, 30);
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:newBackButton];
    // BACK BUTTON END
    
    // COMPOSE BUTTON START
    UIButton *composeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [composeButton setImage:[UIImage imageNamed: @"button-write1.png"] forState:UIControlStateNormal];
    [composeButton setImage:[UIImage imageNamed: @"button-write2.png"] forState:UIControlStateSelected];
    [composeButton addTarget:self action:@selector(performSegueToCompose:) forControlEvents:UIControlEventTouchUpInside];
    composeButton.frame = CGRectMake(5, 5, 30, 30);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:composeButton];
    // COMPOSE BUTTON END
    
}

-(void)performSegueToCompose:(id)sender{
    [self performSegueWithIdentifier:@"MessagesToSpeak" sender:self];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [[SpeakUpManager sharedSpeakUpManager] setConnectionDelegate:self];
    [noConnectionLabel setHidden:[[SpeakUpManager sharedSpeakUpManager] connectionIsOK]];
    [self sortMessages];
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

-(void)notifyThatRoomHasBeenDeleted:(Room*) room{
    if ([room.roomID isEqual:[[[SpeakUpManager sharedSpeakUpManager] currentRoom] roomID]]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Room Closed"
                                                        message:[NSString stringWithFormat: @"Room %@ has been closed by its owner and is no longer available", [[[SpeakUpManager sharedSpeakUpManager] currentRoom]name]]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages] count]==0){
        return 1;
    }
    return [[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages] count];
}

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
       // UIButton *thumbUpButton = (UIButton *)[cell viewWithTag:2];
       // [thumbUpButton setImage:[UIImage imageNamed:@"noMsg.png"] forState:UIControlStateNormal] ;
       // cell.backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        //cell.backgroundView.backgroundColor = [UIColor whiteColor];
        //cell.backgroundView.layer.cornerRadius  =1;
        
        return cell;
    }
    else{
        Message* message = [self getMessageForIndex:[indexPath row]];
        
        NSString *CellIdentifier = @"MessageCell";
        
        /////////////// JUST FOR TEST
        //if(!message.parentMessageID)
        //if(arc4random()%2==0){
          //CellIdentifier = @"ReplyMessageCell";
       //}
        ///////////////////
        
        MessageCell *cell = (MessageCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[MessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.message=message;
        // CONTENT - set up the content
        UITextView *contentTextView = (UITextView *)[cell viewWithTag:10];
        
       
        contentTextView.text = [message content];
        CGRect frame = contentTextView.frame;
        frame.size.height = contentTextView.contentSize.height;
        contentTextView.frame = frame;
        
       
        
        
        // THUMBS - Setup the ThumbsUP and down buttons
        UIButton *thumbUpButton = (UIButton *)[cell viewWithTag:3];
        if([[[SpeakUpManager sharedSpeakUpManager] likedMessages]  containsObject:message.messageID]){
            [thumbUpButton setImage:[UIImage imageNamed:@"tUpP1.png"] forState:UIControlStateNormal] ;
        }else{
            [thumbUpButton setImage:[UIImage imageNamed:@"tUp1.png"] forState:UIControlStateNormal] ;
        }
        UIButton *thumbDownButton = (UIButton *)[cell viewWithTag:5];
        if([[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  containsObject:message.messageID]){
            [thumbDownButton setImage:[UIImage imageNamed:@"tDownP1.png"] forState:UIControlStateNormal] ;
        }else {
            [thumbDownButton setImage:[UIImage imageNamed:@"tDown1.png"] forState:UIControlStateNormal] ;
        }
        // TIME - Setup the time label
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
            time = @"just now";
        }else if(minutes>0 && hours == 0){
            time = [NSString stringWithFormat:@"%d min ago",minutes];
        }else {
            time = [NSString stringWithFormat:@"%d hours ago",hours];
        }
        [timeLabel setText: time];
        
        UILabel *backgroundLabel = (UILabel *)[cell viewWithTag:12];
        backgroundLabel.backgroundColor=[UIColor whiteColor];
        
        // SCORE - Setup the score label
        UILabel *scoreLabel = (UILabel *)[cell viewWithTag:7];
        if(message.score>0){
            scoreLabel.textColor = [UIColor colorWithRed:0.0/255.0 green:173.0/255.0 blue:121.0/255.0 alpha:1.0];//dark green color
            [scoreLabel setText: [NSString stringWithFormat:@"+%d", message.score]];
        }else if(message.score<0){
            scoreLabel.textColor = [UIColor colorWithRed:238.0/255.0 green:0.0/255.0 blue:58.0/255.0 alpha:1.0];//dark red color
            [scoreLabel setText: [NSString stringWithFormat:@"%d", message.score]];
        }else{
            scoreLabel.textColor = [UIColor grayColor];
            [scoreLabel setText: @"0"];
        }
        UILabel *numberofVotesLabel = (UILabel *)[cell viewWithTag:8];
        int numberOfVotes= message.numberOfNo + message.numberOfYes;
        if(numberOfVotes<2){
            [numberofVotesLabel setText: [NSString stringWithFormat:@"(%d vote)", numberOfVotes]];
        }else{
            [numberofVotesLabel setText: [NSString stringWithFormat:@"(%d votes)", numberOfVotes]];
        }
        
        // CELL STYLE
        cell.backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        //cell.contentView.backgroundColor=[UIColor colorWithRed:112.0/255.0 green:197.0/255.0 blue:248.0/255.0 alpha:1.0];
        // if message is mine the color could be different
         if([[[SpeakUpManager sharedSpeakUpManager] peer_id]isEqual:message.authorPeerID]){
           // cell.backgroundView.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.7];
        }else{
          //  cell.backgroundView.backgroundColor = [UIColor whiteColor];
        }
        cell.backgroundView.layer.cornerRadius  =2;
        return cell;
    }
}

-(Message*)getMessageForIndex:(NSInteger)index{
    if ([[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages] count]>0){
        return (Message *)[[[[SpeakUpManager sharedSpeakUpManager] currentRoom] messages] objectAtIndex:index];
    }
    return nil;
}


-(IBAction)sortBy:(id)sender{
    UISegmentedControl *seg = (UISegmentedControl *) sender;
    NSInteger selectedSegment = seg.selectedSegmentIndex;
    
    if (selectedSegment == 0) {
        [[[SpeakUpManager sharedSpeakUpManager] currentRoom] setMessagesSortedBy:BEST_RATING];
    }else if(selectedSegment == 1){
        [[[SpeakUpManager sharedSpeakUpManager] currentRoom] setMessagesSortedBy:MOST_RECENT];
    }
    
    [self sortMessages];
    [self.tableView reloadData];
    
}


-(void)connectionWasLost{
    noConnectionLabel.backgroundColor = [UIColor colorWithRed:238.0/255.0 green:0.0/255.0 blue:58.0/255.0 alpha:1.0];//dark red color
    [noConnectionLabel setText: @"CONNECTION LOST"];
    [noConnectionLabel setHidden:NO];
}
-(void)connectionHasRecovered{
    noConnectionLabel.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:173.0/255.0 blue:121.0/255.0 alpha:1.0];//dark green color
    [noConnectionLabel setText: @"CONNECTION ESTABLISHED"];
    [noConnectionLabel performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:3.0];
}

//#pragma mark - Table view delegate
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Navigation logic may go here. Create and push another view controller.
//    /*
//     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
//     // ...
//     // Pass the selected object to the new view controller.
//     [self.navigationController pushViewController:detailViewController animated:YES];
//     */
//}


// LIKE
-(IBAction)rateMessageUp:(id)sender{
    if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
    @synchronized(self){
        NSString* messageID;
        int yesRating = 0;
        int noRating = 0;
        UIButton *aButton = (UIButton *)sender;
        UIView *contentView = [aButton superview];
        UITableViewCell *cell = (UITableViewCell *)[contentView superview];
        NSIndexPath *indexPath = [[self tableView] indexPathForCell:cell];
        NSUInteger row = [indexPath row];
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
        [[SpeakUpManager sharedSpeakUpManager] rateMessage:messageID inRoom:[[[SpeakUpManager sharedSpeakUpManager] currentRoom] roomID] yesRating:yesRating noRating:noRating];
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
        }else{
            NSLog(@"the message %@ does not have an id",[message description]);
        }
        [self.tableView reloadData];
    }
    }
}

// DISLIKE
-(IBAction)rateMessageDown:(id)sender{
     if([[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
    @synchronized(self){
        NSString* messageID;
        int yesRating = 0;
        int noRating = 0;
        UIButton *aButton = (UIButton *)sender;
        UIView *contentView = [aButton superview];
        UITableViewCell *cell = (UITableViewCell *)[contentView superview];
        NSIndexPath *indexPath = [[self tableView] indexPathForCell:cell];
        NSUInteger row = [indexPath row];
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
        [[SpeakUpManager sharedSpeakUpManager] rateMessage:messageID inRoom:[[[SpeakUpManager sharedSpeakUpManager] currentRoom] roomID] yesRating:yesRating noRating:noRating];
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
        }else{
            NSLog(@"the message %@ does not have an id",[message description]);
        }
       [self.tableView reloadData];
    }
     }
}


// GO TO INPUT
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    if ([[segue identifier] isEqualToString:@"MessagesToSpeak"]) {
//       // InputViewController *inputVC  = (InputViewController *)[segue destinationViewController];
//        //[inputVC setRoom: currentRoom];
//    }
//}


// SLIDE TO DELETE
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    Message* message = [self getMessageForIndex:indexPath.section];
//    if([[[SpeakUpManager sharedSpeakUpManager] peer_id] isEqual:message.authorPeerID]){
//        return @"Delete";
//    }
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


// RECEIVE NEW MESSAGES
-(void)updateMessagesInRoom:(NSString*) roomID{
    //maybe we can use a room ID and if the room ID is equal to the current room, then there is an update, not otherwise.
    if([roomID isEqual:[[[SpeakUpManager sharedSpeakUpManager] currentRoom] roomID]]){
        if(!self.editing){
            [self sortMessages];
            [self.tableView reloadData];
        }
    }
}

// UTILITIES

// CALCULATE HEIGHT
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSUInteger row = [indexPath row];
    Message* message = [self getMessageForIndex:row];
    NSString *text = message.content;
    
    CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2),CELL_MAX_SIZE);
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    CGFloat height = MAX(size.height + CELL_VERTICAL_OFFSET, CELL_MIN_SIZE);
    return height + (CELL_CONTENT_MARGIN * 2);
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



@end