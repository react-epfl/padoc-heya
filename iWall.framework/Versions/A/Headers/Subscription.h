//
//  Subscription.h
//  iWall2
//
//  Created by François Vessaz on 17.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Subscription : NSObject

+(id)withJSONData:(NSDictionary*)data;

+(id)withID:(long)ID topic:(NSString*)topic selector:(NSString*)selector range:(double)rangeInMeters isOutward:(BOOL)outward duration:(long)durationInMinutes isMobile:(BOOL)mobile latitude:(double)latitude longitude:(double)longitude subscriberID:(long)subscriberID timestamp:(NSDate*)timestamp;

+(id)withTopic:(NSString*)topic selector:(NSString*)selector range:(double)rangeInMeters isOutward:(BOOL)outward duration:(long)durationInMinutes isMobile:(BOOL)mobile;

-(id)initWithJSONData:(NSDictionary*)data;

-(id)initWithID:(long)ID topic:(NSString*)topic selector:(NSString*)selector range:(double)rangeInMeters isOutward:(BOOL)outward duration:(long)durationInMinutes isMobile:(BOOL)mobile latitude:(double)latitude longitude:(double)longitude subscriberID:(long)subscriberID timestamp:(NSDate*)timestamp;

-(id)initWithTopic:(NSString*)topic selector:(NSString*)selector range:(double)rangeInMeters isOutward:(BOOL)outward duration:(long)durationInMinutes isMobile:(BOOL)mobile;

@property (nonatomic) BOOL mobile;
@property (nonatomic) BOOL outward;
@property (nonatomic, strong) NSNumber* ID;
@property (nonatomic, strong) NSString* topic;
@property (nonatomic, strong) NSString* selector;
@property (nonatomic, strong) NSNumber* range;
@property (nonatomic, strong) NSNumber* duration;
@property (nonatomic, strong) NSNumber* subscriberID;
@property (nonatomic, strong) CLLocation* location;
@property (nonatomic, strong) NSDate* timestamp;


@end
