//
//  mobilePeerApi.h
//  iWall2
//
//  Created by François Vessaz on 09.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Proxy.h"
#import "Event.h"
#import "Publication.h"
#import "Subscription.h"

@class Subscription;
@class Publication;
@class LocationManager;

/*
 * Predefined durations
 */
#define eternity -1
#define instant   0

/*
 * Location update modes
 */
typedef enum {
	OFF_MODE = 0,
	NORMAL_MODE = 1
} updateModes;

/*
 * MobilePeerDelegate protocol.
 *
 * Contains the callback methods of the mobile peer. Needs to be implemented by
 * the requester to receive the answers by the AsynchronousResponse object.
 */
@protocol MobilePeerDelegate<ProxyDelegate>

@optional
-(void)openSessionSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)openSessionAndCreatePeerSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)closeSessionSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)closeSessionAndDeletePeerSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)publishSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)unpublishSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)subscribeSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)unsubscribeSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)getPublicationSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)getAllPublicationsSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)getSubscriptionSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)getAllSubscriptionsSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)updateLocationSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)isOpenSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)getPeerIDSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)getLocationSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)resetSucceededWithResponse:(Response*)response forRequest:(Request*)request;
@end

/*
 * MobilePeer
 *
 * Represent a mobile peer in Objective-C as defined by the MobilePeer
 * Java interface in the middleware. This class is roughly equalivent to  
 * the com.headfirst.iwall.gateway.MobilePeerProxy Java class.
 */
@interface MobilePeer : Proxy

@property (nonatomic, readonly) NSNumber* peerID;
@property (nonatomic, readonly) LocationManager* locationManager;
@property (nonatomic, readonly) NSString* callbackURI;

+(id)withServerURI:(NSString*)serverURI andCallbackURI:(NSString*)callbackURI;
-(id)initWithServerURI:(NSString*)serverURI andCallbackURI:(NSString*)callbackURI;

// Middleware API | Asynchronous Methods
-(Request*)openSession:(int64_t)peerID delegate:(id<MobilePeerDelegate>)delegate;
-(Request*)openSessionAndCreatePeer:(id<MobilePeerDelegate>)delegate;
-(Request*)openSessionAndCreatePeer:(NSString*)peerName delegate:(id<MobilePeerDelegate>)delegate;
-(Request*)closeSession:(id<MobilePeerDelegate>)delegate;
-(Request*)closeSessionAndDeletePeer:(id<MobilePeerDelegate>)delegate;
-(Request*)publish:(Event*)event onTopic:(NSString*)topic inRange:(double)range isOutward:(BOOL)outward forDuration:(long)duration isMobile:(BOOL)mobile delegate:(id<MobilePeerDelegate>)delegate;
-(Request*)unpublish:(NSNumber*)publicationID delegate:(id<MobilePeerDelegate>)delegate;
-(Request*)subscribe:(NSString*)selector onTopic:(NSString*)topic inRange:(double)range isOutward:(BOOL)outward forDuration:(long)duration isMobile:(BOOL)mobile delegate:(id<MobilePeerDelegate>)delegate;
-(Request*)unsubscribe:(NSNumber*)subscriptionID delegate:(id<MobilePeerDelegate>)delegate;
-(Request*)getPublication:(NSNumber*)publicationID delegate:(id<MobilePeerDelegate>)delegate;
-(Request*)getAllPublications:(id<MobilePeerDelegate>)delegate;
-(Request*)getSubscription:(NSNumber*)subscriptionID delegate:(id<MobilePeerDelegate>)delegate;
-(Request*)getAllSubscriptions:(id<MobilePeerDelegate>)delegate;
-(Request*)isOpen:(id<MobilePeerDelegate>)delegate;
-(Request*)getPeerID:(id<MobilePeerDelegate>)delegate;
-(Request*)getLocation:(id<MobilePeerDelegate>)delegate;
-(Request*)reset:(id<MobilePeerDelegate>)delegate;

// Location management
-(void)setUpdateLocationMode:(updateModes)mode;
-(void)setAccuracy:(double)accuracy;
-(CLLocation*)getLocation;

@end