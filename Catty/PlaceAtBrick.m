//
//  PlaceAtBrick.m
//  Catty
//
//  Created by Mattias Rauter on 13.07.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "PlaceAtBrick.h"

@implementation PlaceAtBrick

@synthesize position = _position;

#pragma mark - init methods
-(id)initWithPosition:(GLKVector3)position
{
    self = [super init];
    if (self)
    {
        self.position = position;
    }
    return self;
}

#pragma mark - override
-(void)performOnSprite:(Sprite *)sprite
{
    NSLog(@"Set positino of sprite %@ to %f / % f / %f", sprite.name, self.position.x, self.position.y, self.position.z);
    sprite.position = self.position;
}

@end
