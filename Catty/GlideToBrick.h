//
//  GlideToBrick.h
//  Catty
//
//  Created by Mattias Rauter on 16.07.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "Brick.h"

@interface GlideToBrick : Brick

@property (nonatomic, assign) GLKVector3 position;

#warning @mattias: changed to nsnumber instead of float
@property (nonatomic, strong) NSNumber *durationInMilliSeconds;

#warning @mattias: I've added these properties
@property (nonatomic, strong) NSNumber *xDestination;
@property (nonatomic, strong) NSNumber *yDestination;

-(id)initWithPosition:(GLKVector3)position andDurationInMilliSecs:(NSNumber*)durationInMilliSecs;

@end
