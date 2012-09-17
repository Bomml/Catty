//
//  Sprite.h
//  Catty
//
//  Created by Mattias Rauter on 17.04.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "enums.h"

@class Costume;
@class Script;

@interface Sprite : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSMutableArray *costumesArray;
@property (strong, nonatomic) NSMutableArray *soundsArray;
@property (strong, nonatomic) NSMutableArray *startScriptsArray;
@property (strong, nonatomic) NSMutableArray *whenScriptsArray;
@property (assign) GLKVector3 position;
@property (assign) CGSize contentSize;
@property (nonatomic, strong) GLKBaseEffect *effect;

- (id)initWithEffect:(GLKBaseEffect*)effect;
- (void)render;
- (NSString*)description;
- (CGRect)boundingBox;
- (void)start;
- (void)touch:(TouchAction)type;

- (void)changeCostume:(NSNumber*)indexOfCostumeInArray;
- (void)glideToPosition:(GLKVector3)position withinDurationInMilliSecs:(int)durationInMilliSecs;



@end
