//
//  RoomTableViewController.m
//  SpeakUp
//
//  Created by Adrian Holzer on 19.12.11.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import "RoomTableViewController.h"
#import "Room.h"
#import "SpeakUpManager.h"
#import "Message.h"
#import "MessageTableViewController.h"

#define DISTANCE 1500

@implementation RoomTableViewController

@synthesize nearbyRooms, plusButton, roomLogo,roomTextField;

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
    nearbyRooms=nil;
    [plusButton setEnabled:NO];
    
    [[SpeakUpManager sharedSpeakUpManager] setRoomManagerDelegate:self];
    [[SpeakUpManager sharedSpeakUpManager] setSpeakUpDelegate:self];
    [[SpeakUpManager sharedSpeakUpManager] setConnectionDelegate:self];
    // EGO STUFF
    if (_refreshHeaderView == nil) {
        EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
        view.delegate = self;
        [self.tableView addSubview:view];
        _refreshHeaderView = view;
    }
    //  update the last update date
    [_refreshHeaderView refreshLastUpdatedDate];
    
   
    //UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                               //    initWithTarget:self
                                 //  action:@selector(dismissKeyboard)];
    
    //[self.view addGestureRecognizer:tap];
    
    
    [super viewDidLoad];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

-(void)dismissKeyboard {
    [roomTextField resignFirstResponder];
}

- (void)updateData{
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[SpeakUpManager sharedSpeakUpManager] getNearbyRooms];
    [[SpeakUpManager sharedSpeakUpManager] setConnectionDelegate:self];
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
    // Returns one section
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(![[SpeakUpManager sharedSpeakUpManager] connectionIsOK] ||![[SpeakUpManager sharedSpeakUpManager] locationIsOK]){
        return 1; // returns one when there is no room (the cell will contain an instruction)
    }
    if ([nearbyRooms count]>0){
        return[nearbyRooms count];
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(![[SpeakUpManager sharedSpeakUpManager] connectionIsOK] ||![[SpeakUpManager sharedSpeakUpManager] locationIsOK]){
        [plusButton setEnabled:NO];
        self.navigationItem.title=@"Loading...";
        static NSString *CellIdentifier = @"NoRoomCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        // Populate Community Cells
        UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
        if(![[SpeakUpManager sharedSpeakUpManager] locationIsOK]){
            nameLabel.text = @"Waiting for location...";
        }else if(![[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
            nameLabel.text = @"Waiting for connection...";
        }
        return cell;
    }else{
        [plusButton setEnabled:YES];
        self.navigationItem.title=@"Rooms";
        //if there is no room, simply put this no room cell
        if ([nearbyRooms count]==0){
            static NSString *CellIdentifier = @"NoRoomCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
            nameLabel.text = @"No room nearby, create one!";
            return cell;
        }
        else{
            static NSString *CellIdentifier = @"CommunityCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            // Populate Community Cells
            NSUInteger row = [indexPath row];
            Room *room = (Room *)[nearbyRooms objectAtIndex:row];
            UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
            nameLabel.text = [room name];
            
            UILabel *distanceLabel = (UILabel *)[cell viewWithTag:2];
            [distanceLabel setText: [NSString stringWithFormat:@"%.0f m", room.distance]];
            
            if (room.isOfficial){
                if([[[SpeakUpManager sharedSpeakUpManager] peer_id]isEqual:room.creatorID]){
                    cell.imageView.image = [UIImage imageNamed:@"official-room.png"];
                }else{
                    cell.imageView.image = [UIImage imageNamed:@"official-room-notmine.png"];
                }
            }else{
                 if([[[SpeakUpManager sharedSpeakUpManager] peer_id]isEqual:room.creatorID]){
                    cell.imageView.image = [UIImage imageNamed:@"non-official-room-mine.png"];
                }
                else{
                    cell.imageView.image = [UIImage imageNamed:@"non-official-room.png"];
                }
            }
            return cell;
        }
    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section==0) {
        return @"Nearby rooms";
    }else{
        return @"Other rooms";
    }
    
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    //check if
    if ([identifier isEqualToString:@"JoinRoomSegue"]) {
        // if the room id is not ok when the response is received trigger prepareForSegue
        // return NO;
    }
    return YES;
    
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"JoinRoomSegue"]) {
       
       [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID: [[[SpeakUpManager sharedSpeakUpManager] currentRoom] roomID] orRoomHash:nil];
        
    }
    
    if ([[segue identifier] isEqualToString:@"RoomToMessages"]) {
       // MessageTableViewController *messageTVC  = (MessageTableViewController *)[segue destinationViewController];
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [[self tableView] indexPathForCell:cell];
        NSUInteger row = [indexPath row];
        [[SpeakUpManager sharedSpeakUpManager] setCurrentRoom:[nearbyRooms objectAtIndex:row]];
        [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID: [[[SpeakUpManager sharedSpeakUpManager] currentRoom] roomID] orRoomHash:nil];
       // [messageTVC setCurrentRoom: room];
    }
}
//callback from the server
-(void)updateRooms:(NSArray*)updatedRooms{
    //NSLog(@"UPDATES DATA");
    if(!self.editing){
        nearbyRooms=updatedRooms;
        [self.tableView reloadData];
        // EGO finnish loading
        [self doneLoadingTableViewData];
    }
}

//request sent to the server
//- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    Room* room  = (Room *)[[[SpeakUpManager sharedSpeakUpManager] roomArray] objectAtIndex:indexPath.row];
//    if([[[SpeakUpManager sharedSpeakUpManager] peer_id] isEqual:room.creatorID]){
//        return @"Delete";
//    }
    //return @"Hide";
//}

// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        Room* room = [nearbyRooms objectAtIndex:indexPath.row];
//        NSLog(@"hiding room %@ ", room.roomID);
//        [[[SpeakUpManager sharedSpeakUpManager] roomArray] removeObject:room];
//        [[SpeakUpManager sharedSpeakUpManager] deleteRoom:room];
//        [tableView reloadData];
//
//    }
//}

-(void)connectionWasLost{
    //[noConnectionLabel setHidden:NO];
}
-(void)connectionHasRecovered{
    //[noConnectionLabel setHidden:YES];
}

////////////////////////////////////
//// PULL DOWN LIBRARY (EGO) STUFF BEGINS
////////////////////////////////////
#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods
- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
}
- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return _reloading; // should return if data source model is reloading
}
- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [NSDate date]; // should return date data source was last changed
}
#pragma mark -
#pragma mark Data Source Loading / Reloading Methods
- (void)reloadTableViewDataSource{
    [[SpeakUpManager sharedSpeakUpManager] getNearbyRooms];
	//  should be calling your tableviews data source model to reload
	_reloading = YES;
}
- (void)doneLoadingTableViewData{
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}
#pragma mark -
#pragma mark UIScrollViewDelegate Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}




/////////////////////////////////
//// PULL DOWN LIBRARY (EGO) STUFF ENDS
/////////////////////////////////


@end
