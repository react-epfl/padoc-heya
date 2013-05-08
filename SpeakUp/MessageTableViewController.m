//
//  ProfileTableViewController.m
//  InterMix
//
//  Created by Adrian Holzer on 20.12.11.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "MessageTableViewController.h"
#import "InputViewController.h"
#import "Message.h"
#import "SpeakUpManager.h"

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

@synthesize currentRoom, roomNameLabel, segmentedControl ;


- (id)initWithStyle:(UITableViewStyle)style
{
    
    
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor whiteColor];
    
    //[self.navigationItem setTitle:room.name];
    [self.roomNameLabel setText:currentRoom.name];
    [[SpeakUpManager sharedSpeakUpManager] setMessageManagerDelegate:self];
    
}

//define the targetmethod
-(void) targetMethod: (NSTimer*) theTimer{
    // test if peer is still in the vicinity
    //[self testLocationMatchAndLeaveRoomIfNecessary];
    // NSLog(@"request messages");
    //[self requestMessages];
}

//- (void)viewDidUnload
//{
  //  [super viewDidUnload];
//}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

-(void)notifyThatRoomHasBeenDeleted:(Room*) room{
    if ([room.roomID isEqual:currentRoom.roomID]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Room Closed"
                                                        message:[NSString stringWithFormat: @"Room %@ has been closed by its owner and is no longer available", currentRoom.name ]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [self.navigationController popViewControllerAnimated:YES];
    }
}


-(void)notifyThatLocationHasChangedSignificantly{
//       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Room Closed"
//                                                        message:[NSString stringWithFormat: @"Room %@ has been closed by its owner and is no longer available", currentRoom.name ]
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//        [self.navigationController popViewControllerAnimated:YES];
}


- (void)viewDidDisappear:(BOOL)animated
{
    //Saving peer data
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
    if ([currentRoom.messages count]==0){
        return 1;
    }
    return [currentRoom.messages count];
    
}

// test if the peer is still in the range of the room , if this is not the case, leaves the room with a alert
-(void)testLocationMatchAndLeaveRoomIfNecessary{
   // CLLocation * peerlocation = [[CLLocation alloc] initWithLatitude:[[SpeakUpManager sharedSpeakUpManager] latitude] longitude:[[SpeakUpManager sharedSpeakUpManager] longitude]];
    //CLLocation * roomlocation = [[CLLocation alloc] initWithLatitude:[currentRoom latitude] longitude: [currentRoom longitude]];
   // if([peerlocation distanceFromLocation:roomlocation]> currentRoom.range){
        // goes back to the room view,
     //   UIAlertView *alert = [[UIAlertView alloc]
       //                       initWithTitle: [NSString stringWithFormat: @"You have left %@", currentRoom.name ]
         //                     message: [NSString stringWithFormat: @"Messages in %@ are no longer available", currentRoom.name ]
           //                   delegate: nil
             //                 cancelButtonTitle:@"OK"
               //               otherButtonTitles:nil];
        //[alert show];
        //[self.navigationController popViewControllerAnimated:YES];
    //}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // returns one the number of communities. in a following version, we would only see the activated communities.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // check this site
    // http://www.cimgf.com/2009/09/23/uitableviewcell-dynamic-height/
    // MessageManager *sharedMessageManager = [MessageManager sharedMessageManager];
    //if there is no room, simply put this no room cell
    if ([currentRoom.messages count]==0){
        static NSString *CellIdentifier = @"NoMessageCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        UIButton *thumbUpButton = (UIButton *)[cell viewWithTag:2];
        [thumbUpButton setImage:[UIImage imageNamed:@"noMsg.png"] forState:UIControlStateNormal] ;
         cell.backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
         cell.backgroundView.backgroundColor = [UIColor whiteColor];
        cell.backgroundView.layer.cornerRadius  =2;
        return cell;
    }
    else{
        static NSString *CellIdentifier = @"MessageCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        // CONTENT - set up the content 
        UITextView *contentTextView = (UITextView *)[cell viewWithTag:10];
        NSUInteger section = [indexPath section];
        Message* message = [self getMessageForIndex:section];
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
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
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
        // if message is mine the color could be different
        if([[[SpeakUpManager sharedSpeakUpManager] myMessageIDs] containsObject:message.messageID]){
            //cell.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.7];
            cell.backgroundView.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.7];
        }else{
            //cell.backgroundColor = [UIColor whiteColor ];
            cell.backgroundView.backgroundColor = [UIColor whiteColor];
        }
       // cell.backgroundView.layer.shadowColor =[[UIColor blackColor] CGColor];
        cell.backgroundView.layer.cornerRadius  =2;
       // cell.backgroundView.layer.shadowRadius=2;
        //cell.backgroundView.layer.shadowOpacity=.8;
       // cell.backgroundView.layer.shadowOffset = CGSizeMake(2.0, 2.0);
        return cell;
    }
}

-(Message*)getMessageForIndex:(NSInteger)index{
    Message  *message;
    if ([currentRoom.messages count]>0){
        switch (self.segmentedControl.selectedSegmentIndex) {
            case 0:
                message = (Message *)[[self getMessagesSortedByScore] objectAtIndex:index];
                return message;
            case 1:
                message = (Message *)[[self getMessagesSortedByTime] objectAtIndex:index];
                return message;
            default:
                break;
        }
    }
    return nil;
}


-(IBAction)sortBy:(id)sender{
    [self.tableView reloadData];
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}


//press like
-(IBAction)rateMessageUp:(id)sender{
    @synchronized(self){
        NSString* messageID;
        BOOL yesRating = NO;
        BOOL noRating = NO;
        UIButton *aButton = (UIButton *)sender;
        UIView *contentView = [aButton superview];
        UITableViewCell *cell = (UITableViewCell *)[contentView superview];
        NSIndexPath *indexPath = [[self tableView] indexPathForCell:cell];
        NSUInteger section = [indexPath section];
        Message* message = [self getMessageForIndex:section];
        messageID = message.messageID;
        //if the message was disliked, remove the message from the list of disliked messages and add it to the liked messages
        if([[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  containsObject:message.messageID]){
            [[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  removeObject:message.messageID];
            noRating = NO  ;
            [[[SpeakUpManager sharedSpeakUpManager] likedMessages]  addObject:message.messageID];
            yesRating= YES;
        }
        //else if the message was liked remove it from the list of liked messages
        else if([[[SpeakUpManager sharedSpeakUpManager] likedMessages]  containsObject:message.messageID]){
            [[[SpeakUpManager sharedSpeakUpManager] likedMessages]  removeObject:message.messageID];
            yesRating=NO;
        }
        // else (i.e., when the message was neither liked or dislike, add it to the list of like messages)
        else{
            [[[SpeakUpManager sharedSpeakUpManager] likedMessages]  addObject:message.messageID];
            yesRating=YES;
        }
        [self.tableView reloadData];
        // update the message rating on the server
        [[SpeakUpManager sharedSpeakUpManager] rateMessage:messageID inRoom:currentRoom.roomID likes:yesRating dislkies:noRating];
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
    }
}

-(IBAction)rateMessageDown:(id)sender{
    @synchronized(self){
        NSString* messageID;
        BOOL yesRating = NO;
        BOOL noRating = NO;
        UIButton *aButton = (UIButton *)sender;
        UIView *contentView = [aButton superview];
        UITableViewCell *cell = (UITableViewCell *)[contentView superview];
        NSIndexPath *indexPath = [[self tableView] indexPathForCell:cell];
        NSUInteger section = [indexPath section];
        Message* message = [self getMessageForIndex:section];
        messageID = message.messageID;
        //if the message was disliked, remove the message from the list of disliked messages
        if([[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  containsObject:message.messageID]){
            [[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  removeObject:message.messageID];
            noRating=NO;
        }
        //else if the message was liked remove it from the list of liked messages and add it to the disliked messages
        else if([[[SpeakUpManager sharedSpeakUpManager] likedMessages]  containsObject:message.messageID]){
            [[[SpeakUpManager sharedSpeakUpManager] likedMessages]  removeObject:message.messageID];
            yesRating=NO ;
            [[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  addObject:message.messageID];
            noRating= YES ;
        }
        // else (i.e., when the message was neither liked or dislike, add it to the list of disliked messages)
        else{
            [[[SpeakUpManager sharedSpeakUpManager] dislikedMessages]  addObject:messageID];
            noRating=YES;
        }
        [self.tableView reloadData];
        // update the message rating on the server
         [[SpeakUpManager sharedSpeakUpManager] rateMessage:messageID inRoom:currentRoom.roomID likes:yesRating dislkies:noRating];
        [[SpeakUpManager sharedSpeakUpManager] savePeerData];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"MessagesToSpeak"]) {
        InputViewController *inputVC  = (InputViewController *)[segue destinationViewController];
        [inputVC setRoom: currentRoom];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message* message = [self getMessageForIndex:indexPath.section];
    if([[[SpeakUpManager sharedSpeakUpManager] myMessageIDs] containsObject:message.messageID]){
        return @"Delete";
    }
    return @"Hide";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSUInteger section = [indexPath section];
    Message* message = [self getMessageForIndex:section];
    NSString *text = message.content;
    
    CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2),CELL_MAX_SIZE);
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    CGFloat height = MAX(size.height + CELL_VERTICAL_OFFSET, CELL_MIN_SIZE);
    return height + (CELL_CONTENT_MARGIN * 2);
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Message* message = [self getMessageForIndex:indexPath.section];
        [currentRoom.messages removeObject:message];
        [[SpeakUpManager sharedSpeakUpManager] deleteMessage:message];
        [tableView reloadData];

    }
}


// callback from server
-(void)updateMessages:(NSArray*)updatedMessages inRoom:(Room*) room{
    //maybe we can use a room ID and if the room ID is equal to the current room, then there is an update, not otherwise.
    if([room.roomID isEqual:currentRoom.roomID]){
        if(!self.editing){
            [self.tableView reloadData];
          //  [self doneLoadingTableViewData]; // EGO finnish loading
        }
    }
}

-(NSArray*) getMessagesSortedByScore{
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO];
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [currentRoom.messages sortedArrayUsingDescriptors:sortDescriptors];
    return sortedArray;
}

-(NSArray*) getMessagesSortedByTime{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    for (Message* message in currentRoom.messages){
        NSDate *messageCreationTime = [dateFormatter dateFromString:message.creationTime];
        NSTimeInterval elapsedTimeSinceMessageCreation = [messageCreationTime timeIntervalSinceNow];
        message.secondsSinceCreation = elapsedTimeSinceMessageCreation;
    }
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"secondsSinceCreation" ascending:NO];
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [currentRoom.messages sortedArrayUsingDescriptors:sortDescriptors];
    return sortedArray;
}


@end


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */
