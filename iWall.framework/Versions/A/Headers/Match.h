//
//  Match.h
//  iWall
//
//  Created by Benoît Garbinato on 27/11/12.
//  Copyright (c) 2012 Université de Lausanne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Publication.h"
#import "Subscription.h"

@interface Match : NSObject

+(id)withJSONData:(NSDictionary*)data;

-(id)initWithJSONData:(NSDictionary*)data;

- (id)initWithPublication:(Publication*)publication subscription:(Subscription*)subscription timestamp:(NSDate*)timestamp;

@property (nonatomic, strong) Event* event;
@property (nonatomic, strong) NSString* topic;
@property (nonatomic, strong) NSString* selector;
@property (nonatomic, strong) NSNumber* subscriptionID;
@property (nonatomic, strong) NSNumber* publicationID;
@property (nonatomic, strong) NSNumber* subscriberID;
@property (nonatomic, strong) NSDate* timestamp;

@end
