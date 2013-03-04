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

-(id)initWithDegrees:(NSNumber*)degees
{
    self = [super init];
    if (self)
    {
        self.degrees = degees;
    }
    return self;
}

- (void)performFromScript:(Script*)script
{
    NSLog(@"Performing: %@", self.description);
    
    [self.sprite turnLeft:self.degrees.floatValue];
}

#pragma mark - Description
- (NSString*)description
{
    return [NSString stringWithFormat:@"TurnLeft (%f degrees)", self.degrees.floatValue];
}

@end
