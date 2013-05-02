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

@synthesize nearbyRooms, plusButton, roomLogo;

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
    //[[SpeakUpManager sharedSpeakUpManager] checkIfReady];
    // EGO STUFF
    if (_refreshHeaderView == nil) {
        EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
        view.delegate = self;
        [self.tableView addSubview:view];
        _refreshHeaderView = view;
    }
    //  update the last update date
    [_refreshHeaderView refreshLastUpdatedDate];
    
    [super viewDidLoad];
}


- (void)updateData{
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
   // [[SpeakUpManager sharedSpeakUpManager] subscribeToNearbyRooms];
    [super viewDidDisappear:animated];
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
        if(![[SpeakUpManager sharedSpeakUpManager] connectionIsOK] &&![[SpeakUpManager sharedSpeakUpManager] locationIsOK]){
            nameLabel.text = @"Waiting for location and connection...";
        }
        else if(![[SpeakUpManager sharedSpeakUpManager] locationIsOK]){
            nameLabel.text = @"Waiting for location...";
        }
        else if(![[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
            nameLabel.text = @"Waiting for connection...";
        }
        return cell;
    }else{
        [plusButton setEnabled:YES];
        self.navigationItem.title=@"Nearby rooms";
        //if there is no room, simply put this no room cell
        if ([nearbyRooms count]==0){
            static NSString *CellIdentifier = @"NoRoomCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
            nameLabel.text = @"Looking for nearby rooms";
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
            
            if (room.isOfficial==1){
                if([[[SpeakUpManager sharedSpeakUpManager] myRoomIDs] containsObject:room.roomID]){
                    cell.imageView.image = [UIImage imageNamed:@"official-room.png"];
                }else{
                    cell.imageView.image = [UIImage imageNamed:@"official-room-notmine.png"];
                }
            }else{
                if([[[SpeakUpManager sharedSpeakUpManager] myRoomIDs] containsObject:room.roomID]){
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"RoomToMessages"]) {
        MessageTableViewController *messageTVC  = (MessageTableViewController *)[segue destinationViewController];
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [[self tableView] indexPathForCell:cell];
        NSUInteger row = [indexPath row];
        Room *room = [nearbyRooms objectAtIndex:row];
        [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoom:room.roomID];
        [messageTVC setCurrentRoom: room];
        // if (!room.subscriptionRequest) {
        //   [[SpeakUpManager sharedSpeakUpManager] subscribeToAllMessagesInRoom:room.roomID];
        // }
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
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Room* room  = (Room *)[[[SpeakUpManager sharedSpeakUpManager] roomArray] objectAtIndex:indexPath.row];
    if([[[SpeakUpManager sharedSpeakUpManager] myRoomIDs] containsObject:room.roomID]){
        return @"Delete";
    }
    return @"Hide";
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Room* room = [nearbyRooms objectAtIndex:indexPath.row];
        NSLog(@"hiding room %@ ", room.roomID);
        nearbyRooms = [[SpeakUpManager sharedSpeakUpManager] deleteRoom:room];
        [tableView reloadData];
    }
}

///////////////////////////
//// EGO STUFF BEGINS
///////////////////////////
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
	//  put here just for demo
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
///////////////////////////
//// EGO STUFF ENDS
///////////////////////////


@end
