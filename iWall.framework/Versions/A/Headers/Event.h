//
//  Event.h
//  iWall2
//
//  Created by Garbinato Benoît on 31/12/11.
//  Copyright (c) 2011 Université de Lausanne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Event : NSObject

@property (nonatomic,strong) NSDictionary* properties;
@property (nonatomic,strong) NSArray* propertyNames;

+(id)event;
+(id)withJSONData:(NSDictionary*)data;

-(id)init;
-(id)initWithJSONData:(NSDictionary*)jsonData;

-(BOOL)contains:(NSString*)propertyName;
-(NSString*)getValueDescription:(NSString*)propertyName;
-(NSString*)getTypeDescription:(NSString*)propertyName;
-(void)removeProperty:(NSString*)name;

-(void)setBooleanProperty:(NSString*)name to:(BOOL)value;
-(NSNumber*)getBooleanProperty:(NSString*)name;

-(void)setByteProperty:(NSString*)name to:(int8_t)value;
-(NSNumber*)getByteProperty:(NSString*)name;

-(void)setShortProperty:(NSString*) name to:(int16_t)value;
-(NSNumber*)getShortProperty:(NSString*)name;

-(void)setIntProperty:(NSString*)name to:(int32_t)value;
-(NSNumber*)getIntProperty:(NSString*)name;

- (void)setLongProperty:(NSString*)name to:(int64_t)value;
-(NSNumber*)getLongProperty:(NSString*)name;

-(void)setFloatProperty:(NSString*)name to:(float_t)value;
-(NSNumber*)getFloatProperty:(NSString*)name;

-(void)setDoubleProperty:(NSString*)name to:(double_t)value;
-(NSNumber*)getDoubleProperty:(NSString*)name;

-(void)setStringProperty:(NSString*)name to:(NSString*)value;
-(NSString*)getStringProperty:(NSString*)name;

-(NSString*)describe:(BOOL)typed separator:(NSString*)separator;

@end
