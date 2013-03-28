//
//  ChangeSizeByNBrick.m
//  Catty
//
//  Created by Mattias Rauter on 19.09.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "Changesizebynbrick.h"

@implementation Changesizebynbrick

@synthesize size = _size;

-(id)initWithSizeChangeRate:(NSNumber*)sizeInPercentage
{
    self = [super init];
    if (self)
    {
        self.size = sizeInPercentage;
    }
    return self;
}

- (void)performFromScript:(Script*)script
{
    NSLog(@"Performing: %@", self.description);
    
    [self.object changeSizeByN:self.size.floatValue];
    
    //    float sleepTime = ((float)self.timeToWaitInMilliseconds.intValue)/1000;
    //    NSLog(@"wating for %f seconds", sleepTime);
    //    NSLog(@"---- BEFORE SLEEP -----");
    //    [NSThread sleepForTimeInterval:sleepTime];
    //    NSLog(@"---- AFTER SLEEP ------");
    
}

#pragma mark - Description
- (NSString*)description
{
    return [NSString stringWithFormat:@"ChangeSizeByN (%f%%)", self.size.floatValue];
}

@end
