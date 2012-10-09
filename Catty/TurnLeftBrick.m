//
//  TurnLeftBrick.m
//  Catty
//
//  Created by Mattias Rauter on 06.10.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "TurnLeftBrick.h"

@implementation TurnLeftBrick

@synthesize degrees = _degrees;

-(id)initWithDegrees:(float)degees
{
    self = [super init];
    if (self)
    {
        self.degrees = degees;
    }
    return self;
}

- (void)performOnSprite:(Sprite *)sprite fromScript:(Script*)script
{
    NSLog(@"Performing: %@", self.description);
    
    [sprite turnLeft:self.degrees];
}

#pragma mark - Description
- (NSString*)description
{
    return [NSString stringWithFormat:@"TurnLeft (%f degrees)", self.degrees];
}

@end
