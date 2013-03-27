//
//  MatchRepository.h
//  iWall
//
//  Created by Benoît Garbinato on 27/11/12.
//  Copyright (c) 2012 Université de Lausanne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Proxy.h"
#import "Request.h"
#import "Response.h"
#import "Match.h"


/*
 * MatchRepositoryDelegate protocol.
 *
 * Contains the callback methods of the match repository. Needs to be implemented by
 * the requester to receive the answers by the AsynchronousResponse object.
 */
@protocol MatchRepositoryDelegate<ProxyDelegate>

@optional
-(void)storeSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)retrieveMatchesForSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)getMatchesForSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)getPeerIDsSucceededWithResponse:(Response*)response forRequest:(Request*)request;
-(void)purgeMatchesOlderThanSucceededWithResponse:(Response*)response forRequest:(Request*)request;
@end


/*
 * MatchRepository
 *
 * Represent a match repository in Objective-C as defined by the MatchRepository
 * Java interface in the middleware. This class is roughly equalivent to
 * the com.headfirst.iwall.gateway.MatchRepositoryProxy Java class.
 */

@interface MatchRepository : Proxy

+(id)withRepositoryURI:(NSString*)repositoryURI;
-(id)initWithRepositoryURI:(NSString*)repositoryURI;

-(Request*)store:(Match*)match delegate:(id<MatchRepositoryDelegate>)delegate;
-(Request*)retrieveMatchesFor:(NSNumber*)peerID delegate:(id<MatchRepositoryDelegate>)delegate;
-(Request*)getMatchesFor:(NSNumber*)peerID delegate:(id<MatchRepositoryDelegate>)delegate;
-(Request*)getPeerIDs:(id<MatchRepositoryDelegate>)delegate;
-(Request*)purgeMatchesOlderThan:(NSDate*)timestamp delegate:(id<MatchRepositoryDelegate>)delegate;

@end
