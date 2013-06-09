/**
 *  Copyright (C) 2010-2013 The Catrobat Team
 *  (http://developer.catrobat.org/credits)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  An additional term exception under section 7 of the GNU Affero
 *  General Public License, version 3, is available at
 *  (http://developer.catrobat.org/license_additional_term)
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see http://www.gnu.org/licenses/.
 */


#import "Script.h"
#import "Brick.h"
#import "SpriteObject.h"
#import "Foreverbrick.h"
#import "Repeatbrick.h"
#import "LoopEndBrick.h"
#import "IfLogicBeginBrick.h"
#import "IfLogicElseBrick.h"
#import "IfLogicEndBrick.h"
#import "NoteBrick.h"


@interface Script()
@property (assign, nonatomic) int currentBrickIndex;
@property (strong, nonatomic) NSMutableArray *startLoopIndexStack;
@property (strong, nonatomic) NSMutableArray *startLoopTimestampStack;
@property (assign, nonatomic) BOOL stop;
@end



@implementation Script

@synthesize brickList = _brickList;
@synthesize action = _action;
@synthesize currentBrickIndex = _currentBrickIndex;
@synthesize startLoopIndexStack = _startLoopIndexStack;
@synthesize startLoopTimestampStack = _startLoopTimestampStack;
@synthesize stop = _stop;
@synthesize object = _object;

- (id)init
{
    if (self = [super init])
    {
        self.action = kTouchActionTap;
        self.currentBrickIndex = 0;
        self.stop = NO;
    }
    return self;
}

#pragma mark - Custom getter and setter
-(NSMutableArray*)brickList
{
    if (_brickList == nil)
        _brickList = [[NSMutableArray alloc] init];
    
    return _brickList;
}
-(NSMutableArray*)startLoopIndexStack
{
    if (_startLoopIndexStack == nil)
        _startLoopIndexStack = [[NSMutableArray alloc] init];
    
    return _startLoopIndexStack;
}
-(NSMutableArray*)startLoopTimestampStack
{
    if (_startLoopTimestampStack == nil)
        _startLoopTimestampStack = [[NSMutableArray alloc]init];

    return _startLoopTimestampStack;
}

-(void)addBrick:(Brick *)brick
{
    [self.brickList addObject:brick];
}

-(void)addBricks:(NSArray *)bricks
{
    [self.brickList addObjectsFromArray:bricks];
}

-(NSArray *)getAllBricks
{
    return [NSArray arrayWithArray:self.brickList];
}


-(void)resetScript
{
    self.currentBrickIndex = -1;
    self.startLoopIndexStack = nil;
    self.startLoopTimestampStack = nil;
}

-(void)stopScript
{
    self.stop = YES;
}

-(void)runScript
{
    //TODO: check loop-condition BEFORE first iteration
            
    [self resetScript];
    if (self.currentBrickIndex < 0)
        self.currentBrickIndex = 0;
    while (!self.stop && self.currentBrickIndex < [self.brickList count]) {
        if (self.currentBrickIndex < 0)
            self.currentBrickIndex = 0;
        Brick *brick = [self.brickList objectAtIndex:self.currentBrickIndex];
        
//        if([sprite.name isEqualToString:@"Spawning"])
//        {          
//            NSLog(@"Brick: %@", [brick description]);
//        }
        
        if ([brick isKindOfClass:[ForeverBrick class]]) {
            
            if (![(ForeverBrick*)brick checkConditionAndDecrementLoopCounter]) {
                // go to end of loop
                int numOfLoops = 1;
                int tmpCounter = self.currentBrickIndex+1;
                while (numOfLoops > 0 && tmpCounter < [self.brickList count]) {
                    brick = [self.brickList objectAtIndex:tmpCounter];
                    if ([brick isKindOfClass:[ForeverBrick class]])
                        numOfLoops += 1;
                    else if ([brick isMemberOfClass:[LoopEndBrick class]])
                        numOfLoops -= 1;
                    tmpCounter += 1;
                }
                self.currentBrickIndex = tmpCounter-1;
            } else {
                [self.startLoopIndexStack addObject:[NSNumber numberWithInt:self.currentBrickIndex]];
                [self.startLoopTimestampStack addObject:[NSNumber numberWithDouble:[[NSDate date]timeIntervalSince1970]]];
            }
            
        } else if ([brick isMemberOfClass:[LoopEndBrick class]]) {
            
            self.currentBrickIndex = ((NSNumber*)[self.startLoopIndexStack lastObject]).intValue-1;
            [self.startLoopIndexStack removeLastObject];
            
            double startTimeOfLoop = ((NSNumber*)[self.startLoopTimestampStack lastObject]).doubleValue;
            [self.startLoopTimestampStack removeLastObject];
            double timeToWait = 0.02f - ([[NSDate date]timeIntervalSince1970] - startTimeOfLoop); // 20 milliseconds
//            NSLog(@"timeToWait (loop): %f", timeToWait);
            if (timeToWait > 0)
                [NSThread sleepForTimeInterval:timeToWait];
            
        } else if([brick isMemberOfClass:[IfLogicBeginBrick class]]) {
            BOOL condition = [(IfLogicBeginBrick*)brick checkCondition];
            if(!condition) {
                
//                int index = [self.brickList indexOfObject:((IfLogicBeginBrick*)brick).ifElseBrick];
//                if(index <= 0 ||index > [self.brickList count]-1) {
//                    abort();
//                }
//                self.currentBrickIndex = index;
                
                
#warning workaround until XML fixed    
                
                BOOL found = NO;
                Brick* elseBrick = nil;
                int ifcount = 0;

                while (self.currentBrickIndex < [self.brickList count] && !found) {
                    self.currentBrickIndex++;
                    elseBrick = [self.brickList objectAtIndex:self.currentBrickIndex];
                    if([elseBrick isMemberOfClass:[IfLogicBeginBrick class]]) {
                        ifcount++;
                    }
                    else if([elseBrick isMemberOfClass:[IfLogicEndBrick class]]) {
                        ifcount--;
                    }
                    else if([elseBrick isMemberOfClass:[IfLogicElseBrick class]] && ifcount == 0) {
                        found = YES;
                    }
                }
            }
        } else if([brick isMemberOfClass:[IfLogicElseBrick class]]) {

            
//            int index = [self.brickList indexOfObject:((IfLogicElseBrick*)brick).ifEndBrick];
//            if(index <= 0 ||index > [self.brickList count]-1) {
//                abort();
//            }
//            self.currentBrickIndex = index;
 
#warning workaround until XML fixed
            int endcount = 1;
            Brick* endBrick = nil;
            
            while (self.currentBrickIndex < [self.brickList count] && ![endBrick isMemberOfClass:[IfLogicEndBrick class]] && endcount != 0) {
                self.currentBrickIndex++;
                endBrick = [self.brickList objectAtIndex:self.currentBrickIndex];
                if([endBrick isMemberOfClass:[IfLogicBeginBrick class]]) {
                    endcount++;
                }
                else if([endBrick isMemberOfClass:[IfLogicEndBrick class]]) {
                    endcount--;
                }
            }
        } else if([brick isMemberOfClass:[IfLogicElseBrick class]]) {
            // No action needed
        }
        else if(![brick isMemberOfClass:[NoteBrick class] ]) {
            [brick performFromScript:self];
        }
        
        self.currentBrickIndex += 1;
        

//        NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!! currentBrickIndex=%d", self.currentBrickIndex);
    }
}

//-(void)glideWithSprite:(Sprite*)sprite toPosition:(GLKVector3)position withinMilliSecs:(int)timeToGlideInMilliSecs
//{
//    [sprite glideToPosition:position withinDurationInMilliSecs:timeToGlideInMilliSecs fromScript:self];
////    [self waitTimeInMilliSecs:timeToGlideInMilliSecs];
//}
//
//-(void)waitTimeInMilliSecs:(float)timeToWaitInMilliSecs
//{
////    NSLog(@"BEFORE wait %f     wait: %f sec", [[NSDate date] timeIntervalSince1970], timeToWaitInMilliSecs/1000.0f);
//    [NSThread sleepForTimeInterval:timeToWaitInMilliSecs/1000.0f];
////    NSLog(@"AFTER wait  %f", [[NSDate date] timeIntervalSince1970]);
//}

#pragma mark - Description
-(NSString*)description
{
    NSMutableString *ret = [[NSMutableString alloc] initWithString:@"Script"];
    
    if ([self.brickList count] > 0)
    {
        [ret appendString:@"Bricks: \r"];
        for (Brick *brick in self.brickList)
        {
            [ret appendFormat:@"%@\r", brick];
        }
    }
    else 
    {
        [ret appendString:@"Bricks array empty!\r"];
    }
    
    return ret;
}

////abstract method (!!!)
//-(void)executeForSprite:(Sprite*)sprite
//{
////    @throw [NSException exceptionWithName:NSInternalInconsistencyException
////                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
////                                 userInfo:nil];
//    
//    //chris: I think startscript and whenscript classes are not really necessary?! why did we create them?!
//    //mattias: we created them to separate scripts, cuz we did not have two membervariables in sprite-class (just ONE "script"-array)
//    //         now we have two arrays and we don't need them anymore...I'll change this later ;)
//    for (Brick *brick in self.bricksArray)
//    {
//        [brick performOnSprite:sprite];
//    }
//}


@end
