//
//  Request.h
//  iWall2
//
//  Created by Garbinato Benoît on 17/1/12.
//  Copyright (c) 2012 Université de Lausanne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Event.h"

@interface Request : NSObject

+(id)request;
-(id)init;

+(id)withJSONData:(NSDictionary*)data;
-(id)initWithJSONData:(NSDictionary*)data;


@property (nonatomic, strong) NSString* operation;
@property (nonatomic, strong) NSNumber* peerID;
@property (nonatomic, strong) NSString* peerName;
@property (nonatomic, strong) NSNumber* subscriptionID;
@property (nonatomic, strong) NSNumber* publicationID;
@property (nonatomic, strong) NSString* topic;
@property (nonatomic, strong) NSNumber* range;
@property (nonatomic, strong) NSNumber* outward;
@property (nonatomic, strong) NSNumber* duration;
@property (nonatomic, strong) NSNumber* mobile;
@property (nonatomic, strong) Event* event;
@property (nonatomic, strong) NSString* selector;
@property (nonatomic, readonly) NSDictionary* data;

@end
