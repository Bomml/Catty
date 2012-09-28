//
//  ChangeVolumeByBrick.m
//  Catty
//
//  Created by Dominik Ziegler on 9/27/12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "ChangeVolumeByBrick.h"

@implementation ChangeVolumeByBrick


@synthesize percent = _percent;



-(id)initWithValueInPercent:(float)percent
{
    self = [super init];
    if (self)
    {
        self.percent = percent;
    }
    return self;
}



- (void)performOnSprite:(Sprite *)sprite fromScript:(Script *)script
{
    NSLog(@"Performing: %@", self.description);
    
    [sprite changeVolumeBy:_percent/100.0f];
}


#pragma mark - Description
- (NSString*)description
{
    return [NSString stringWithFormat:@"Change Volume by: %f%%)", _percent];
}




@end
