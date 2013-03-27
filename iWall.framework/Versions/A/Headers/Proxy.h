//
//  Proxy.h
//  iWall
//
//  Created by Benoît Garbinato on 26/11/12.
//  Copyright (c) 2012 Université de Lausanne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Request.h"
#import "Response.h"

/*
 * ProxyDeletage protocol.
 *
 * Contains the callback methods of the proxy. Needs to be implemented by
 * the requester to receive the answers by the AsynchronousResponse object.
 */

@protocol ProxyDelegate
@required
-(void)invocationFailedWithError:(NSError*)error forRequest:(Request*)request;

@end

@interface NSError (iWall)
@property (nonatomic,readonly) Response* iWallResponse;
@property (nonatomic,readonly) BOOL iWallInvocationError;
@end

/*
 * Proxy
 *
 * Factors out the json-based protocol on which the MobilePeer proxy
 * and the MatchRepository proxy are based to communicate with their
 * respective web-based services
 */

@interface Proxy : NSObject

@property (nonatomic,readonly) NSString* serverURI;

-(id)initWithServerURI:(NSString*)serverURI;

-(Request*)send:(Request*)request delegate:(id)delegate;
- (void)piggybackHeaderInfo:(NSMutableURLRequest*)httpRequest;
- (void)unpiggybackHeaderInfo:(NSHTTPURLResponse*)response;

@end
