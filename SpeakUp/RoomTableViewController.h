//
//  HomeTableViewController.h
//
//  Created by Adrian Holzer on 19.12.11.
//  Copyright (c) 2012 Adrian Holzer. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "RoomManagerDelegate.h"
#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"
#import "SpeakUpManagerDelegate.h"
#import "ConnectionDelegate.h"


@interface RoomTableViewController : UITableViewController <RoomManagerDelegate, UITableViewDelegate, UITableViewDataSource, EGORefreshTableHeaderDelegate, SpeakUpManagerDelegate, ConnectionDelegate>{
    EGORefreshTableHeaderView *_refreshHeaderView;
	
	//  Reloading var should really be your tableviews datasource
	//  Putting it here for demo purposes
	BOOL _reloading;
    BOOL _roomsReady;
}

@property(strong, nonatomic) IBOutlet UIBarButtonItem * plusButton;
@property(strong, nonatomic) IBOutlet UIImageView * roomLogo;
@property(strong, nonatomic) NSArray *nearbyRooms;


@end
