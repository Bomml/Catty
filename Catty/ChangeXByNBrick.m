//
//  ChangeXByBrick.m
//  Catty
//
//  Created by Mattias Rauter on 19.09.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "ChangeXByNBrick.h"

@implementation ChangeXByNBrick

@synthesize xMovement = _xMovement;

-(id)initWithChangeValueForX:(NSNumber*)x
{
    self = [super init];
    if (self)
    {
        self.xMovement = x;
    }
    return self;
}

- (void)performOnSprite:(Sprite *)sprite fromScript:(Script*)script
{
    NSLog(@"Performing: %@", self.description);
    
    [sprite changeXBy:self.xMovement.intValue];
}

#pragma mark - Description
- (NSString*)description
{
    return [NSString stringWithFormat:@"ChangeXBy (%d)", self.xMovement.intValue];
}

@end
