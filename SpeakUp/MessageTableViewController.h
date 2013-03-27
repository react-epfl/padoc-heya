//
//  ProfileTableViewController.h
//  SpeakUp
//
//  Created by Adrian Holzer on 20.12.11.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "MessageManagerDelegate.h"
#import "EGORefreshTableHeaderView.h"

@interface MessageTableViewController : UITableViewController<UINavigationControllerDelegate, MessageManagerDelegate, UITableViewDelegate, UITableViewDataSource>{
    
    
    EGORefreshTableHeaderView *_refreshHeaderView;
	
	//  Reloading var should really be your tableviews datasource
	//  Putting it here for demo purposes
	BOOL _reloading;
}

//press thumb up
-(IBAction)rateMessageUp:(id)sender;
//press thumb up
-(IBAction)rateMessageDown:(id)sender;
//press thumb up
-(IBAction)sortBy:(id)sender;

//@property (nonatomic, retain) NSTimer * timer;
@property(strong, nonatomic) Room *currentRoom;
//@property(strong, nonatomic) NSArray *messages;
@property(strong, nonatomic) IBOutlet UILabel* roomNameLabel;
@property(strong, nonatomic) IBOutlet UISegmentedControl* segmentedControl ;



@end
