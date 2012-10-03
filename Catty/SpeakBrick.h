//
//  SpeakBrick.h
//  Catty
//
//  Created by Dominik Ziegler on 10/3/12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "Brick.h"

@interface SpeakBrick : Brick

@property (nonatomic, strong) NSString *text;

-(id)initWithText:(NSString*)text;


@end
