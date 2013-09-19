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

@synthesize nearbyRooms, plusButton, roomLogo,roomTextField, unlockedRooms, NEARBY_SECTION, UNLOCKED_SECTION;



#pragma mark - View lifecycle
//=========================
// LOAD VIEW
//=========================
- (void)viewDidLoad
{
    nearbyRooms=nil;
    unlockedRooms=nil;
    NEARBY_SECTION=0;
    UNLOCKED_SECTION=-1;
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
    // self.navigationController.navigationBar.clipsToBounds = NO;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed: @"background-nav.png"] forBarMetrics:UIBarMetricsDefault];
    //[self.navigationController.navigationBar setShadowImage:[UIImage imageNamed: @"shadow-nav.png"]];
    // PLUS BUTTON START
    plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [plusButton setImage:[UIImage imageNamed: @"button-add1.png"] forState:UIControlStateNormal];
    [plusButton setImage:[UIImage imageNamed: @"button-add2.png"] forState:UIControlStateHighlighted];
    [plusButton addTarget:self action:@selector(performAddRoomSegue:) forControlEvents:UIControlEventTouchUpInside];
    plusButton.frame = CGRectMake(0, 0, 40, 40);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:plusButton];
    self.tableView.separatorColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];// LITE GREY
    //[plusButton setEnabled:NO];
    // PLUS BUTTON END
    [super viewDidLoad];
    self.tableView.bounces = YES;
    // NAV TITLE
    UILabel *customLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120.0f, 44.0f)];
    customLabel.backgroundColor= [UIColor clearColor];
    customLabel.textAlignment = NSTextAlignmentCenter;
    [customLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:22]];
    customLabel.textColor =  [UIColor whiteColor];
    self.navigationItem.titleView = customLabel;
    [((UILabel *)self.navigationItem.titleView) setText:NSLocalizedString(@"ROOMS", nil)];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait); // Return YES for supported orientations
}
#pragma mark - Table view data source
//=========================
// HANDLE ROW AND SECTIONS
//=========================
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (UNLOCKED_SECTION==0) {
        return 2;
    }
    return 1; 
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if((![[SpeakUpManager sharedSpeakUpManager] locationIsOK]) && section==NEARBY_SECTION){
        return 1; // returns one when there is no room (the cell will contain an instruction)
    }
    if (section==NEARBY_SECTION && [nearbyRooms count]>0){
        return[nearbyRooms count];
    }else if(section==NEARBY_SECTION && [nearbyRooms count]==0){
        return 1;
    }
    if (section==UNLOCKED_SECTION && [unlockedRooms count]>0 ){
        return[unlockedRooms count];
        //return 2;
    }
    return 0;
}
//==============
// LOAD DATA
//==============
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if((![[SpeakUpManager sharedSpeakUpManager] connectionIsOK] || ![[SpeakUpManager sharedSpeakUpManager] locationIsOK])  && indexPath.section==NEARBY_SECTION){
        //[plusButton setEnabled:NO];
       // [((UILabel *)self.navigationItem.titleView) setText:NSLocalizedString(@"LOADING", nil)];
        static NSString *CellIdentifier = @"NoRoomCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        // Populate Community Cells
        UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];

        if(![[SpeakUpManager sharedSpeakUpManager] locationIsOK]){
            nameLabel.text =  NSLocalizedString(@"NO_LOCATION", nil);
        }
        if(![[SpeakUpManager sharedSpeakUpManager] connectionIsOK]){
            nameLabel.text =  NSLocalizedString(@"NO_CONNECTION", nil) ;
        }

        return cell;
    }else{
        //[plusButton setEnabled:YES];
        [((UILabel *)self.navigationItem.titleView) setText:NSLocalizedString(@"ROOMS", nil)];
        //if there is no room, simply put this no room cell
        NSUInteger row = [indexPath row];
        if (indexPath.section==NEARBY_SECTION) {
            if ([nearbyRooms count]==0){
                static NSString *CellIdentifier = @"NoRoomCell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                }
                UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
                nameLabel.text = NSLocalizedString(@"NO_ROOM", nil) ;
                return cell;
            }
            else{
                static NSString *CellIdentifier = @"CommunityCell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                }
                
                Room *room = (Room *)[nearbyRooms objectAtIndex:row];
                UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
                nameLabel.text = [room name];
                
                UILabel *distanceLabel = (UILabel *)[cell viewWithTag:2];
                [distanceLabel setText: [NSString stringWithFormat:@"%.0f m", room.distance]];
                return cell;
            }
        }
        else { // IF WE ARE IN THE UNLOCK SECTION
                static NSString *CellIdentifier = @"CommunityCell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                }
                // Populate Community Cells
                //NSUInteger row = [indexPath row];
                Room *room = (Room *)[unlockedRooms objectAtIndex:row];
                UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
                nameLabel.text =  [room name];
                
                UILabel *distanceLabel = (UILabel *)[cell viewWithTag:2];
                [distanceLabel setText: @""];
                return cell;
            }
    }
}
//=======================
// CUSTOM SECTION HEADER
//======================
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *sectionName = nil;
    if (section==NEARBY_SECTION) {
        sectionName = NSLocalizedString(@"NEARBY_ROOMS", nil);
    }else{
        sectionName = NSLocalizedString(@"UNLOCKED_ROOMS", nil); 
    }

    UIView *sectionHeaderView = [[UIView alloc] init];
    UILabel *sectionHeader = [[UILabel alloc] initWithFrame:CGRectMake(20, 1, 200, 20)];
    sectionHeader.backgroundColor =  [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];// LITE GREY
    sectionHeaderView.backgroundColor =  [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];// LITE GREY
    sectionHeader.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    sectionHeader.textColor = [UIColor grayColor];
    sectionHeader.text = sectionName;
    [sectionHeaderView addSubview:sectionHeader];
    return sectionHeaderView;
}
//===========
// SEGUES
//===========
-(void)performAddRoomSegue:(id)sender{
    [self performSegueWithIdentifier:@"AddRoomSegue" sender:self];
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
        [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID: [[SpeakUpManager sharedSpeakUpManager] currentRoomID] orRoomHash:nil];
    }
    if ([[segue identifier] isEqualToString:@"RoomToMessages"]) {
        // MessageTableViewController *messageTVC  = (MessageTableViewController *)[segue destinationViewController];
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [[self tableView] indexPathForCell:cell];
        NSUInteger row = [indexPath row];
        
        if (indexPath.section== NEARBY_SECTION) {        
            [[SpeakUpManager sharedSpeakUpManager] setCurrentRoomID: [((Room*)[nearbyRooms objectAtIndex:row])roomID] ];
            [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID: [[SpeakUpManager sharedSpeakUpManager] currentRoomID] orRoomHash:nil];
        }else{
            [[SpeakUpManager sharedSpeakUpManager] setCurrentRoomID:[((Room*)[unlockedRooms objectAtIndex:row])roomID] ];
            [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID: [[SpeakUpManager sharedSpeakUpManager] currentRoomID] orRoomHash:nil];
        }
    }
}
//==================
// SERVER CALLBACKS
//==================
-(void)updateRooms:(NSArray*)updatedNearbyRooms unlockedRooms: (NSArray*)updatedUnlockedRooms{
    if(!self.editing){
        nearbyRooms=updatedNearbyRooms;
        unlockedRooms=updatedUnlockedRooms;
        if ([unlockedRooms count]>0) {
            NEARBY_SECTION=1;
            UNLOCKED_SECTION=0;
        }else{
            NEARBY_SECTION=0;
            UNLOCKED_SECTION=-1;
        }
        [self.tableView reloadData];
        // EGO finnish loading
        [self doneLoadingTableViewData];
    }
}
-(void)connectionWasLost{
    //[noConnectionLabel setHidden:NO];
}
-(void)connectionHasRecovered{
    //[noConnectionLabel setHidden:YES];
}
//=====================================
// PULL DOWN LIBRARY (EGO) STUFF BEGINS
//=====================================
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
//===========
// UTILITIES
//===========
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
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
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
@end

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
//    }
//}