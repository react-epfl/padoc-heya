//
//  Utils.h
//  iWall
//
//  Created by Benoît Garbinato on 6/12/12.
//  Copyright (c) 2012 Université de Lausanne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define minutesToMilliseconds 60000
#define secondsToMilliseconds 1000
#define kilometersToMeters 1000
 
@class Event; 
@class Publication;
@class Subscription;
@class Match;

@interface Utils : NSObject
 
/*
 * Formatting methods
 */

+(NSString*)formatBool:(BOOL)value;
+(NSString*)formatDistance:(double) distanceInMeters;
+(NSString*)formatDistance:(double) distanceInMeters abbreviated:(BOOL)abbreviated;
+(NSString*)formatDuration:(long) durationInMilliseconds;
+(NSString*)formatDuration:(long) durationInMilliseconds abbreviated:(BOOL)abbreviated;
+(NSString*)formatTimestamp:(NSDate*)timestamp;
+(NSString*)formatDouble:(double)aDouble withPrecision:(int)precision;
+(NSString*)formatLatitude:(double)latitude withPrecision:(int)precision;
+(NSString*)formatLongitude:(double)longitude withPrecision:(int)precision;
+(NSString*)formatCoordinates:(CLLocationCoordinate2D)coordinate withPrecision:(int)precision;
+(NSString*)formatCoordinates:(CLLocationCoordinate2D)coordinate withPrecision:(int)precision
                    separator:(NSString*)separator abbreviated:(BOOL)abbreviated;

/*
 * Mockup object creation methods
 */
+(Event*) createMockupEvent;
+(NSString*) createMockupSelector;
+(Publication*) createMockupPublication;
+(Subscription*) createMockupSubscription;
+(Match*) createMockupMatch;

/*
 * Randomization methods
 */

+(double)nextDoubleBetween:(double)lowerBound and:(double)upperBound;
+(double)nextDouble;
+(long)nextLong:(long)upperBound;

@end
