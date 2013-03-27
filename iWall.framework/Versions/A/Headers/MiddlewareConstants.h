//
//  MiddlewareConstants.h
//  iWall
//
//  Created by Garbinato Benoît on 26/12/11.
//  Copyright (c) 2011 Université de Lausanne. All rights reserved.
//

#ifndef iWall_MiddlewareConstants_h
#define iWall_MiddlewareConstants_h

/*
 * Basic Protocol Stuff
 */
#define contentType             @"application/json; charset=utf-8"

/*
 * Keys for Piggybacked Fields | See com.headfirst.iwall.gateway.Header [java]
 */
#define piggybackedPeerID               @"iwall-peerID"
#define piggybackedLatitude             @"iwall-latitude"
#define piggybackedLongitude            @"iwall-longitude"
#define piggybackedAltitude             @"iwall-altitude"
#define piggybackedTimestamp            @"iwall-timestamp"
#define piggybackedHorizontalAccuracy   @"iwall-horizontalAccuracy"
#define piggybackedVerticalAccuracy     @"iwall-verticalAccuracy"
#define piggybackedCallbackURI          @"iwall-callbackURI"


/*
 * Keys for Operation Names | See com.headfirst.iwall.gateway.Operation [java]
 */
#define openSessionOperation                  @"openSession"
#define closeSessionOperation                 @"closeSession"
#define openSessionAndCreatePeerOperation     @"openSessionAndCreatePeer"
#define closeSessionAndDeletePeerOperation    @"closeSessionAndDeletePeer"
#define isOpenOperation                       @"isOpen"
#define getPeerIDOperation                    @"getPeerID"
#define publishOperation                      @"publish"
#define subscribeOperation                    @"subscribe"
#define unpublishOperation                    @"unpublish"
#define unsubscribeOperation                  @"unsubscribe"
#define resetOperation                        @"reset"
#define getLocationOperation                  @"getLocation"
#define getPublicationOperation               @"getPublication"
#define getAllPublicationsOperation           @"getAllPublications"
#define getSubscriptionOperation              @"getSubscription"
#define getAllSubscriptionsOperation          @"getAllSubscriptions"
#define updateLocationOperation               @"updateLocation"
#define getPeerNameOperation                  @"getPeerName"
#define setPeerNameOperation                  @"setPeerName"
#define onMatchOperation                      @"onMatch"
#define releaseOperation                      @"release"
#define storeOperation                        @"store"
#define retrieveMatchesForOperation           @"retrieveMatchesFor"
#define getMatchesForOperation                @"getMatchesFor"
#define getPeerIDsOperation                   @"getPeerIDs"
#define purgeMatchesOlderThanOperation        @"purgeMatchesOlderThan"
#define undefinedOperation                    @"undefined"

/*
 * Keys for Parameters & Return Values | See com.headfirst.iwall.gateway.Invocation [java]
 */
#define peerNameParameter             @"peerName"
#define peerIDParameter               @"peerID"
#define publicationParameter          @"publication"
#define subscriptionParameter         @"subscription"
#define allPublicationsParameter      @"allPublications"
#define allSubscriptionsParameter     @"allSubscriptions"
#define publicationIDParameter        @"publicationID"
#define subscriptionIDParameter       @"subscriptionID"
#define publisherIDParameter          @"publisherID"
#define subscriberIDParameter         @"subscriberID"
#define topicParameter                @"topic"
#define selectorParameter             @"selector"
#define eventParameter                @"event"
#define mobileParameter               @"mobile"
#define outwardParameter              @"outward"
#define openParameter                 @"open"
#define rangeParameter                @"range"
#define outwardParameter              @"outward"
#define durationParameter             @"duration"
#define timestampParameter            @"timestamp"
#define matchParameter                @"match"
#define locationParameter             @"location"
#define latitudeParameter             @"latitude"
#define longitudeParameter            @"longitude"
#define altitudeParameter             @"altitude"
#define horizontalAccuracyParameter   @"horizontalAccuracy"
#define verticalAccuracyParameter     @"verticalAccuracy"
#define latestMatchesParameter        @"latestMatches"

/*
 * Reified Concepts | See com.headfirst.iwall.gateway.Invocation [java]
 */
#define invocationOperation            @"operation"
#define invocationSuccess              @"success"
#define invocationException            @"error"
#define invocationExceptionMessage     @"message"
#define propertyType                   @"type"
#define propertyValue                  @"value"

/*
 * Event Property Types | See com.headfirst.iwall.PropertyList [java]
 */
#define BOOLEAN  @"BOOLEAN"
#define STRING   @"STRING"
#define BYTE     @"BYTE" 
#define SHORT    @"SHORT"
#define INT      @"INT" 
#define LONG     @"LONG" 
#define FLOAT    @"FLOAT" 
#define DOUBLE   @"DOUBLE"

/*
 * Error Handling
 */

#define iWallMiddlewareErrorDomain       @"com.headfirst.iwall.ErrorDomain"
#define iWallMiddlewareErrorResponseKey  @"response"
#define iWallMiddlewareInvocationError   666

#endif
