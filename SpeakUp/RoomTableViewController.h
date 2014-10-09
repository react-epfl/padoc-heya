//
//  HomeTableViewController.h
//
//  Created by Adrian Holzer on 19.12.11.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "RoomManagerDelegate.h"
#import <UIKit/UIKit.h>
#import "SpeakUpManagerDelegate.h"
#import "ConnectionDelegate.h"


@interface RoomTableViewController : UITableViewController <RoomManagerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, SpeakUpManagerDelegate, ConnectionDelegate>{
  //  EGORefreshTableHeaderView *_refreshHeaderView;
	
	//  Reloading var should really be your tableviews datasource
	//  Putting it here for demo purposes
	//BOOL _reloading;
   // BOOL _roomsReady;
}

-(IBAction)refresh:(id)sender;

@property(strong, nonatomic) IBOutlet UIButton * refreshButton;
@property(strong, nonatomic) IBOutlet UIButton * plusButton;
@property(strong, nonatomic) IBOutlet UIImageView * roomLogo;
@property(strong, nonatomic) NSMutableArray *nearbyRooms;
@property(strong, nonatomic) NSMutableArray *unlockedRooms;
@property(strong, nonatomic) IBOutlet UITextField * roomTextField;
@property( nonatomic)  int UNLOCKED_SECTION;
@property( nonatomic)  int NEARBY_SECTION;


@end
