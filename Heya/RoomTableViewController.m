//
//  RoomTableViewController.m
//  SpeakUp
//
//  Created by Adrian Holzer on 19.12.11.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import "RoomTableViewController.h"
#import "Room.h"
#import "SpeakUpManager.h"
#import "Message.h"
#import "MessageTableViewController.h"
//#import "GAI.h"
//#import "GAIDictionaryBuilder.h"
//#import "GAIFields.h"

#define DISTANCE 1500

@implementation RoomTableViewController

@synthesize plusButton, roomLogo, roomTextField, NEARBY_SECTION, UNLOCKED_SECTION, MY_SECTION, refreshButton;

#pragma mark - View lifecycle
- (void)viewDidLoad {
    NEARBY_SECTION = 0;
    UNLOCKED_SECTION = -1;
    MY_SECTION = -1;
    [[SpeakUpManager sharedSpeakUpManager] setRoomManagerDelegate:self];
    [[SpeakUpManager sharedSpeakUpManager] setSpeakUpDelegate:self];
    [[SpeakUpManager sharedSpeakUpManager] setConnectionDelegate:self];
    self.navigationController.navigationBar.translucent = NO;
    self.tableView.separatorColor = [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:255.0/255.0 alpha:0.8];// LITE GREY
    [super viewDidLoad];
    self.tableView.bounces = YES;
    
    // PLUS BUTTON
    plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [plusButton setImage:[UIImage imageNamed: @"button-add1.png"] forState:UIControlStateNormal];
    [plusButton addTarget:self action:@selector(performAddRoomSegue:) forControlEvents:UIControlEventTouchUpInside];
    plusButton.frame = CGRectMake(0, 0, 40, 40);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:plusButton];
    
    // REFRESH BUTTON
    refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [refreshButton setImage:[UIImage imageNamed: @"button-refresh.png"] forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
    refreshButton.frame = CGRectMake(0, 0, 40, 40);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:refreshButton];
    
    // NAV TITLE
    UILabel *customLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120.0f, 44.0f)];
    customLabel.backgroundColor= [UIColor clearColor];
    customLabel.textAlignment = NSTextAlignmentCenter;
    [customLabel setFont:[UIFont fontWithName:FontName size:MediumFontSize]];
    customLabel.textColor =  [UIColor whiteColor];
    self.navigationItem.titleView = customLabel;
    [((UILabel *)self.navigationItem.titleView) setText:NSLocalizedString(@"ROOMS", nil)];
}

- (void)viewWillAppear:(BOOL)animated {
    [[SpeakUpManager sharedSpeakUpManager] getNearbyRooms];
    [[SpeakUpManager sharedSpeakUpManager] setConnectionDelegate:self];
    
//    // GOOGLE TRACKER
//    id tracker = [[GAI sharedInstance] defaultTracker];
//    [tracker set:kGAIScreenName value:@"Room Screen"];
//    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[SpeakUpManager sharedSpeakUpManager] savePeerData];
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait); // Return YES for supported orientations
}


#pragma mark - Table view data source

// HANDLE ROW AND SECTIONS
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NEARBY_SECTION + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == NEARBY_SECTION) {
        int roomsCount = [[[SpeakUpManager sharedSpeakUpManager] roomArray] count];
        if (![[SpeakUpManager sharedSpeakUpManager] locationIsOK] || roomsCount == 0) {
            return 1; // returns one when there is no room (the cell will contain an instruction)
        } else {
            return roomsCount;
        }
    }
    
    else if (section == UNLOCKED_SECTION) {
        return [[[SpeakUpManager sharedSpeakUpManager] unlockedRoomArray] count];
    }
    
    else if (section == MY_SECTION) {
        return [[[SpeakUpManager sharedSpeakUpManager] myOwnRoomArray] count];
    }
    
    return 0;
}

// LOAD DATA
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ((![[SpeakUpManager sharedSpeakUpManager] connectionIsOK] || ![[SpeakUpManager sharedSpeakUpManager] locationIsOK]) && indexPath.section == NEARBY_SECTION) {
        
        static NSString *CellIdentifier = @"NoRoomCell";
        UITableViewCell *cell = [self buildCellForIdentifier:CellIdentifier inTableView:tableView];
        
        // Populate Community Cells
        UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
//        UIActivityIndicatorView *connectionLostSpinner = (UIActivityIndicatorView *)[cell viewWithTag:2];
        if (![[SpeakUpManager sharedSpeakUpManager] locationIsOK]) {
            nameLabel.text = NSLocalizedString(@"NO_ROOM", nil);
//            [connectionLostSpinner stopAnimating];
        }
        if (![[SpeakUpManager sharedSpeakUpManager] connectionIsOK]) {
            nameLabel.text = @"";
//            [connectionLostSpinner startAnimating];
        }
        
        return cell;
        
    } else {
        
        [((UILabel *)self.navigationItem.titleView) setText:NSLocalizedString(@"ROOMS", nil)];
        //if there is no room, simply put this no room cell
        NSUInteger row = [indexPath row];
        NSUInteger section = [indexPath section];
        
        if (section == NEARBY_SECTION) {
            
            if ([[[SpeakUpManager sharedSpeakUpManager] roomArray] count] == 0) {
                
                static NSString *CellIdentifier = @"NoRoomCell";
                UITableViewCell *cell = [self buildCellForIdentifier:CellIdentifier inTableView:tableView];
                
                if ([[[SpeakUpManager sharedSpeakUpManager] myOwnRoomArray] count] == 0) {
                    [self setRoomName:NSLocalizedString(@"NO_ROOM", nil) toCell:cell];
                } else {
                    [self setRoomName:NSLocalizedString(@"", nil) toCell:cell];
                }
                
                return cell;
                
            } else {
                
                Room *room = (Room *)[[[SpeakUpManager sharedSpeakUpManager] roomArray] objectAtIndex:row];
                
                static NSString *CellIdentifier = @"CommunityCell";
                UITableViewCell *cell = [self buildCellForIdentifier:CellIdentifier inTableView:tableView];
                
                [self setRoomName:[room name] toCell:cell];
//                [self setRoomDistance:[NSString stringWithFormat:@"%.0f m", room.distance] toCell:cell];
                [self setRoomDistance:@"" toCell:cell];
                
                return cell;
                
            }
            
        } else {
            
            Room *room = nil;
            if (section == UNLOCKED_SECTION) {
                room = (Room *)[[[SpeakUpManager sharedSpeakUpManager] unlockedRoomArray] objectAtIndex:row];
            } else if (section == MY_SECTION) {
                room = (Room *)[[[SpeakUpManager sharedSpeakUpManager] myOwnRoomArray] objectAtIndex:row];
            }
            
            static NSString *CellIdentifier = @"CommunityCell";
            UITableViewCell *cell = [self buildCellForIdentifier:CellIdentifier inTableView:tableView];
            
            [self setRoomName:[room name] toCell:cell];
            [self setRoomDistance:@"" toCell:cell];
            
            return cell;
            
        }
        
    }
    
    return nil;
}

- (UITableViewCell *)buildCellForIdentifier:(NSString *)CellIdentifier inTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    return cell;
}

- (void) setRoomName:(NSString *)name toCell:(UITableViewCell *)cell {
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
    nameLabel.text = name;
}

- (void) setRoomDistance:(NSString *)distance toCell:(UITableViewCell *)cell {
    UILabel *distanceLabel = (UILabel *)[cell viewWithTag:2];
    [distanceLabel setText:distance];
}

// CUSTOM SECTION HEADER
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *sectionName = nil;
    if (section == NEARBY_SECTION) {
        if ([[[SpeakUpManager sharedSpeakUpManager] roomArray] count] == 0) {
            sectionName = NSLocalizedString(@"NO_NEARBY_ROOMS", nil);
        } else {
            sectionName = NSLocalizedString(@"NEARBY_ROOMS", nil);
        }
    } else if (section == MY_SECTION) {
        sectionName = NSLocalizedString(@"MY_ROOMS", nil);
    } else if (section == UNLOCKED_SECTION) {
        sectionName = NSLocalizedString(@"UNLOCKED_ROOMS", nil);
    }
    
    UIView *sectionHeaderView = [[UIView alloc] init];
    UILabel *sectionHeader = [[UILabel alloc] initWithFrame:CGRectMake(20, 1, 200, 20)];
    sectionHeader.backgroundColor = myGrey;
    sectionHeaderView.backgroundColor = myGrey;
    sectionHeader.textColor = [UIColor blackColor];
    sectionHeader.font = [UIFont fontWithName:FontName size:SmallFontSize];
    sectionHeader.text = sectionName;
    [sectionHeaderView addSubview:sectionHeader];
    
    return sectionHeaderView;
}

// SEGUES

- (void)performAddRoomSegue:(id)sender{
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"JoinRoomSegue"]) {
        [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID:[[SpeakUpManager sharedSpeakUpManager] currentRoomID] orRoomHash:nil withHandler:^(NSDictionary* handler) {
            NSLog(@"XXXXXXXXXXXXXXX");
        }];
    }
    
    if ([[segue identifier] isEqualToString:@"RoomToMessages"]) {
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [[self tableView] indexPathForCell:cell];
        NSUInteger row = [indexPath row];
        
        MessageTableViewController *mvc = (MessageTableViewController *)[segue destinationViewController];
        [mvc setParentMessage:nil];
        if (indexPath.section == NEARBY_SECTION) {
            [[SpeakUpManager sharedSpeakUpManager] setCurrentRoomID:[((Room*)[[[SpeakUpManager sharedSpeakUpManager] roomArray] objectAtIndex:row])roomID]];
        } else if (indexPath.section == UNLOCKED_SECTION) {
            [[SpeakUpManager sharedSpeakUpManager] setCurrentRoomID:[((Room*)[[[SpeakUpManager sharedSpeakUpManager] unlockedRoomArray] objectAtIndex:row])roomID]];
        } else if (indexPath.section == MY_SECTION) {
            [[SpeakUpManager sharedSpeakUpManager] setCurrentRoomID:[((Room*)[[[SpeakUpManager sharedSpeakUpManager] myOwnRoomArray] objectAtIndex:row])roomID]];
        }
        
        // ADER could be done asynchronously with callback
        [[SpeakUpManager sharedSpeakUpManager] getMessagesInRoomID: [[SpeakUpManager sharedSpeakUpManager] currentRoomID] orRoomHash:nil withHandler:^(NSDictionary* handler) {
            NSLog(@"YYYYYY");
        }];
    }
}

// SERVER CALLBACKS
- (void)updateRooms {
    if (!self.editing) {
        //ADER ADD MYOWN ROOM
        MY_SECTION = 0;
        UNLOCKED_SECTION = 1;
        NEARBY_SECTION = 2;
        
        if ([[[SpeakUpManager sharedSpeakUpManager] myOwnRoomArray] count] == 0) {
            MY_SECTION = -1;
            UNLOCKED_SECTION--;
            NEARBY_SECTION--;
        }
        if ([[[SpeakUpManager sharedSpeakUpManager] unlockedRoomArray] count] == 0) {
            UNLOCKED_SECTION = -1;
            NEARBY_SECTION--;
        }
        NSLog(@"HELLO");
        
        [self.tableView reloadData];
    }
}

- (void)connectionWasLost {
    //[noConnectionLabel setHidden:NO];
}

- (void)connectionHasRecovered {
    //[noConnectionLabel setHidden:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)dismissKeyboard {
    [roomTextField resignFirstResponder];
}

- (void)updateData {
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)refresh:(id)sender {
    [[SpeakUpManager sharedSpeakUpManager] getNearbyRooms];
    
//    // GOOGLE ANALYTICS
//    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
//                                                          action:@"button_press"  // Event action (required)
//                                                           label:@"reload"          // Event label
//                                                           value:nil] build]];    // Event value
}

// DELETE UNLOCKED ROOMS
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MY_SECTION) {
        return NSLocalizedString(@"DELETE", nil);
    }
    return NSLocalizedString(@"HIDE", nil);
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.section == MY_SECTION) {
            Room* room = [[[SpeakUpManager sharedSpeakUpManager] myOwnRoomArray] objectAtIndex:indexPath.row];
            [[[SpeakUpManager sharedSpeakUpManager] myOwnRoomArray] removeObject:room];
            [[[SpeakUpManager sharedSpeakUpManager] myOwnRoomIDArray] removeObject:room.roomID];
            [[SpeakUpManager sharedSpeakUpManager] deleteRoom:room];
            [tableView reloadData];
        } else if (indexPath.section == UNLOCKED_SECTION) {
            Room* room = [[[SpeakUpManager sharedSpeakUpManager] unlockedRoomArray] objectAtIndex:indexPath.row];
            [[[SpeakUpManager sharedSpeakUpManager] unlockedRoomArray] removeObject:room];
            [[[SpeakUpManager sharedSpeakUpManager] unlockedRoomIDArray] removeObject:room.roomID];
            [tableView reloadData];
        } else {
            Room* room = [[[SpeakUpManager sharedSpeakUpManager] roomArray] objectAtIndex:indexPath.row];
            [[[SpeakUpManager sharedSpeakUpManager] roomArray] removeObject:room];
            [tableView reloadData];
        }
    }
}

@end
