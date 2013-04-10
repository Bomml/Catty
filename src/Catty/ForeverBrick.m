//
//  LoopBrick.m
//  Catty
//
//  Created by Mattias Rauter on 27.09.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "Foreverbrick.h"

@implementation Foreverbrick


- (void)performFromScript:(Script*)script
{
    NSLog(@"Performing: %@", self.description);
}

-(BOOL)checkConditionAndDecrementLoopCounter
{
    return YES;
}

#pragma mark - Description
- (NSString*)description
{
    return [NSString stringWithFormat:@"ForeverLoop"];
}



@end
