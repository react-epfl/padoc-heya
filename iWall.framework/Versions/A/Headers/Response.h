//
//  Response.h
//  iWall2
//
//  Created by Garbinato Benoît on 17/1/12.
//  Copyright (c) 2012 Université de Lausanne. All rights reserved.
//

#import "Request.h"
#import "Publication.h"
#import "Subscription.h"

@interface Response : Request

@property (nonatomic, readonly) BOOL invocationFailed;
@property (nonatomic, readonly) Publication* publication;
@property (nonatomic, readonly) Subscription* subscription;
@property (nonatomic, readonly) NSArray* allPublications;
@property (nonatomic, readonly) NSArray* allSubscriptions;
@property (nonatomic, readonly) NSArray* latestMatches;
@property (nonatomic, readonly) CLLocation* location;
@property (nonatomic, readonly) NSNumber* sessionIsOpen;
@property (nonatomic, readonly) NSString* exception;
@property (nonatomic, readonly) NSString* exceptionMessage;

@end
