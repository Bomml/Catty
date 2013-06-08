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

#import "SPImage.h"
#import "SPTouchEvent.h"

@class Script;
@class Look;
@class Sound;
@protocol SpriteManagerDelegate;
@protocol BroadcastWaitDelegate;


@interface SpriteObject : SPImage

@property (strong, nonatomic) NSString *name;

@property (assign, nonatomic) CGSize originalSize;
@property (assign, nonatomic) CGPoint position;

@property (weak, nonatomic) id<SpriteManagerDelegate> spriteManagerDelegate;
@property (weak, nonatomic) id<BroadcastWaitDelegate> broadcastWaitDelegate;

@property (strong, nonatomic) NSString *projectPath; //for image-path!!!

@property (strong, nonatomic) NSMutableArray *lookList;
@property (strong, nonatomic) NSMutableArray *soundList;

@property (nonatomic, strong) NSMutableArray *scriptList;

@property (nonatomic, assign) CGFloat zIndex;



- (NSString*)description;

// events
- (void)start;
- (void)scriptFinished:(Script*)script;
- (void)cleanup;
- (void)onImageTouched:(SPTouchEvent*)event;

- (void)performBroadcastWaitScript_calledFromBroadcastWaitDelegate_withMessage:(NSString *)message;


// actions
- (void)changeLook:(Look*)look;
- (void)nextLook;
- (void)glideToPosition:(CGPoint)position withDurationInSeconds:(float)durationInSeconds fromScript:(Script*)script;
- (void)hide;
- (void)show;
- (void)broadcast:(NSString*)message;
- (void)broadcastAndWait:(NSString*)message;
- (void)comeToFront;
- (void)changeSizeByNInPercent:(float)sizePercentageRate;
- (void)changeXBy:(float)x;
- (void)changeYBy:(float)y;
- (void)stopAllSounds;
- (void)setSizeToPercentage:(float)sizeInPercentage;
- (void)goNStepsBack:(int)n;
- (void)setTransparencyInPercent:(float)transparencyInPercent;
- (void)changeTransparencyInPercent:(float)increaseInPercent;
- (void)playSound:(Sound*)sound;
- (void)speakSound:(Sound*)sound;
- (void)setVolumeToInPercent:(float)volumeInPercent;
- (void)changeVolumeInPercent:(float)volumeInPercent;
- (void)turnLeft:(float)degrees;
- (void)turnRight:(float)degrees;
- (void)pointInDirection:(float)degrees;
- (void)changeBrightness:(float)factor;
- (void)moveNSteps:(float)steps;
- (void)ifOnEdgeBounce;

@end
