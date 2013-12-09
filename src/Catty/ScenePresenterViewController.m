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

#import "ScenePresenterViewController.h"
#import "Scene.h"
#import "ProgramLoadingInfo.h"
#import "Parser.h"
#import "ProgramDefines.h"
#import "Program.h"
#import "Util.h"
#import "Script.h"
#import "SpriteObject.h"
#import "SpriteManagerDelegate.h"
#import "Brick.h"
#import "BroadcastWaitHandler.h"
#import "AudioManager.h"
#import "ProgramManager.h"
#import "SensorHandler.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <Accelerate/Accelerate.h>
#import "UIColor+CatrobatUIColorExtensions.h"
#import "Util.h"
#import "SaveToProjectActivity.h"


#define kWidthSlideMenu 150
#define kPlaceOfButtons 17
#define kSlidingStartArea 40
#define kIphone5ScreenHeight 568.0f
#define kIphone4ScreenHeight 480.0f
#define kContinueButtonSize 85
#define kContinueOffset 15
#define kMenuButtonSize 44
#define kMenuIPhone4GapSize 30
#define KMenuIPhone5GapSize 35
#define kMenuIPhone4ContinueGapSize 40
#define kMenuIPhone5ContinueGapSize 45
#define kMenuLabelWidth 50
#define kMenuLabelHeight 20
#define kPlaceofLabels (kPlaceOfButtons-29)
#define kPlaceofContinueLabel (kPlaceOfButtons)
#define kDontResumeSounds 4

@interface ScenePresenterViewController ()<UIActionSheetDelegate>
//{
//    BOOL menuOpen;
//    Scene *scene;
//}

@property (nonatomic) BOOL menuOpen;
@property (nonatomic, strong) Scene *scene;
@property (nonatomic, strong) BroadcastWaitHandler *broadcastWaitHandler;
@property (nonatomic) CGPoint firstGestureTouchPoint;
@property (nonatomic) UIImage* snapshotImage;
@property (nonatomic,strong)UIView* gridView;

@end

@implementation ScenePresenterViewController
@synthesize program = _program;
@synthesize skView = _skView;
@synthesize menuBtn;
@synthesize menuContinueButton = _menuContinueButton;
@synthesize menuScreenshotButton = _menuScreenshotButton;
@synthesize menuRestartButton =_menuRestartButton;
@synthesize menuAxisButton = _menuAxisButton;

# pragma getters and setters
- (BroadcastWaitHandler*)broadcastWaitHandler
{
    // lazy instantiation
    if (! _broadcastWaitHandler) {
        _broadcastWaitHandler = [[BroadcastWaitHandler alloc] init];
    }
    return _broadcastWaitHandler;
}

- (UIView*)gridView
{
    // lazy instantiation
    if (! _gridView) {
        _gridView = [[UIView alloc]initWithFrame:CGRectMake(0,0,[Util getScreenWidth],[Util getScreenHeight])];
        _gridView.hidden = YES;
    }
    return _gridView;
}

- (void)setProgram:(Program *)program
{
    // setting effect
    for (SpriteObject *sprite in program.objectList)
    {
        //sprite.spriteManagerDelegate = self;
        sprite.broadcastWaitDelegate = self.broadcastWaitHandler;
        
        // NOTE: if there are still some runNextAction tasks in a queue
        // then these actions must not be executed because the Scene is not available any more.
        // This problem caused the app to crash sometimes in the past.
        // Now these lines fix this issue.
        for (Script *script in sprite.scriptList) {
            script.allowRunNextAction = YES;
            for (Brick *brick in script.brickList) {
                brick.object = sprite;
            }
        }
    }
    _program = program;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //    ///MENU_BUTTON
    //    self.menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    //    menuBtn.frame = CGRectMake(8.0f, 10.0f, 34.0f, 24.0f);
    //    [menuBtn setBackgroundImage:[UIImage imageNamed:@"menuButton"] forState:UIControlStateNormal];
    //    [menuBtn addTarget:self action:@selector(revealMenu:) forControlEvents:UIControlEventTouchUpInside];
    //    [self.view addSubview:self.menuBtn];
    
    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)]];
    [self setUpMenuButtons];
    
    /// MenuImageBackground
    UIImage *menuBackgroundImage = [UIImage imageNamed:@"stage_dialog_background_middle.png"];
    UIImage *newBackgroundImage = [[UIImage alloc] init];
    
    if ([Util getScreenHeight] == kIphone4ScreenHeight) {
        CGSize size = CGSizeMake(kWidthSlideMenu, kIphone4ScreenHeight);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        [menuBackgroundImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        newBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    else{
        CGSize size = CGSizeMake(kWidthSlideMenu, kIphone5ScreenHeight);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        [menuBackgroundImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        newBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    
    UIColor *background = [[UIColor alloc] initWithPatternImage:newBackgroundImage];
    
    //UIColor *background =[UIColor darkBlueColor];
    self.menuView.backgroundColor = background;
    
    [self setUpMenuFrames];
    [self setUpLabels];
    [self setUpGridView];
    [self revealMenu:nil];
    [self configureScene];
    [self continueLevel:nil withDuration:1];
    [self.view bringSubviewToFront:self.menuView];
}


-(void)setUpLabels
{
    if ([Util getScreenHeight]==kIphone5ScreenHeight) {
        self.menuBackLabel         =[[UILabel alloc] initWithFrame:
                                     CGRectMake(-(kPlaceofLabels-kWidthSlideMenu),(kIphone5ScreenHeight/2)-(kContinueButtonSize/2)-(KMenuIPhone5GapSize)-kMenuIPhone5ContinueGapSize-(kMenuButtonSize)-10, 100, kMenuButtonSize)];
        self.menuRestartLabel       =[[UILabel alloc] initWithFrame:
                                      CGRectMake(-(kPlaceofLabels-kWidthSlideMenu),(kIphone5ScreenHeight/2)-(kContinueButtonSize/2)-kMenuIPhone5ContinueGapSize-10,100, kMenuButtonSize)];
        self.menuContinueLabel      = [[UILabel alloc] initWithFrame:
                                       CGRectMake(-(kPlaceofLabels-kWidthSlideMenu),(kIphone5ScreenHeight/2)+(kContinueButtonSize/2)-10,  kContinueButtonSize, kMenuButtonSize)];
        self.menuScreenshotLabel    = [[UILabel alloc] initWithFrame:
                                       CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone5ScreenHeight/2)+(kContinueButtonSize/2)+kMenuIPhone5ContinueGapSize+kMenuButtonSize-10,  100, kMenuButtonSize)];
        self.menuAxisLabel          = [[UILabel alloc] initWithFrame:
                                       CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone5ScreenHeight/2)+                    (kContinueButtonSize/2)+(KMenuIPhone5GapSize)+kMenuIPhone5ContinueGapSize+(2*kMenuButtonSize)-10,  100, kMenuButtonSize)];
    }
    if ([Util getScreenHeight]==kIphone4ScreenHeight) {
        self.menuBackLabel          =[[UILabel alloc] initWithFrame:
                                      CGRectMake(-(kPlaceofLabels-kWidthSlideMenu),(kIphone4ScreenHeight/2)-(kContinueButtonSize/2)-(kMenuIPhone4GapSize)-kMenuIPhone4ContinueGapSize-(kMenuButtonSize)-10, 100, kMenuButtonSize)];
        self.menuRestartLabel       =[[UILabel alloc] initWithFrame:
                                      CGRectMake(-(kPlaceofLabels-kWidthSlideMenu),(kIphone4ScreenHeight/2)-(kContinueButtonSize/2)-kMenuIPhone4ContinueGapSize-10,100, kMenuButtonSize)];
        self.menuContinueLabel      = [[UILabel alloc] initWithFrame:
                                       CGRectMake(-(kPlaceofLabels-kWidthSlideMenu),(kIphone4ScreenHeight/2)+(kContinueButtonSize/2)-10,  kContinueButtonSize, kMenuButtonSize)];
        self.menuScreenshotLabel    = [[UILabel alloc] initWithFrame:
                                       CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone4ScreenHeight/2)+(kContinueButtonSize/2)+kMenuIPhone4ContinueGapSize+kMenuButtonSize-10,  100, kMenuButtonSize)];
        self.menuAxisLabel          = [[UILabel alloc] initWithFrame:
                                       CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone4ScreenHeight/2)+(kContinueButtonSize/2)+(kMenuIPhone4GapSize)+kMenuIPhone4ContinueGapSize+(2*kMenuButtonSize)-10,  100, kMenuButtonSize)];
    }
    
    [self setupLabel:NSLocalizedString(@"Back", nil)
             andView:self.menuBackLabel];
    [self setupLabel:NSLocalizedString(@"Restart", nil)
             andView:self.menuRestartLabel];
    [self setupLabel:NSLocalizedString(@"Continue",nil)
             andView:self.menuContinueLabel];
    [self setupLabel:NSLocalizedString(@"Screenshot",nil)
             andView:self.menuScreenshotLabel];
    [self setupLabel:NSLocalizedString(@"Grid",nil)
             andView:self.menuAxisLabel];
}

-(void)setupLabel:(NSString*)name andView:(UILabel*)label
{
    label.text = name;
    label.textColor = [UIColor lightGrayColor];
    label.font = [UIFont fontWithName:@"Helvetica Neue" size:(14.0)];
    label.textAlignment = NSTextAlignmentCenter;
    [self.menuView addSubview:label];
    [self.menuView bringSubviewToFront:label];
}

-(void)setUpMenuButtons
{
//    [self setupButtonWithButton:self.menuBackButton
//                ImageNameNormal:[UIImage imageNamed:@"stage_dialog_button_back"]
//        andImageNameHighlighted:[UIImage imageNamed:@"stage_dialog_button_back_pressed"]
//                    andSelector:@selector(stopLevel:)
//     ];

    self.menuBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.menuBackButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_back"] forState:UIControlStateNormal];
    [self.menuBackButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_back_pressed"] forState:UIControlStateHighlighted];
    [self.menuBackButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_back_pressed"] forState:UIControlStateSelected];
    [self.menuBackButton  addTarget:self action:@selector(stopLevel:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.menuView addSubview:self.menuBackButton];
    
    self.menuContinueButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.menuContinueButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_continue"] forState:UIControlStateNormal];
    [self.menuContinueButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_continue_pressed"] forState:UIControlStateHighlighted];
    [self.menuContinueButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_continue_pressed"] forState:UIControlStateSelected];
    [self.menuContinueButton  addTarget:self action:@selector(continueLevel:withDuration:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.menuView addSubview:self.menuContinueButton];
    
    
    self.menuScreenshotButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [_menuScreenshotButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_screenshot"] forState:UIControlStateNormal];
    [_menuScreenshotButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_screenshot_pressed"] forState:UIControlStateHighlighted];
    [_menuScreenshotButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_screenshot_pressed"] forState:UIControlStateSelected];
    [_menuScreenshotButton addTarget:self action:@selector(takeScreenshot:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.menuView addSubview:self.menuScreenshotButton];
    
    
    self.menuRestartButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [_menuRestartButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_restart"] forState:UIControlStateNormal];
    [_menuRestartButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_restart_pressed"] forState:UIControlStateHighlighted];
    [_menuRestartButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_restart_pressed"] forState:UIControlStateSelected];
    [_menuRestartButton addTarget:self action:@selector(restartLevel:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.menuView addSubview:self.menuRestartButton];
    
    self.menuAxisButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [_menuAxisButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_toggle_axis"] forState:UIControlStateNormal];
    [_menuAxisButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_toggle_axis_pressed"] forState:UIControlStateHighlighted];
    [_menuAxisButton setBackgroundImage:[UIImage imageNamed:@"stage_dialog_button_toggle_axis_pressed"] forState:UIControlStateSelected];
    [_menuAxisButton addTarget:self action:@selector(showHideAxis:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.menuView addSubview:self.menuAxisButton];
    
}

-(void)setupButtonWithButton:(UIButton*)button ImageNameNormal:(UIImage*)stateNormal andImageNameHighlighted:(UIImage*)stateHighlighted andSelector:(SEL)myAction
{
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:stateNormal
                      forState:UIControlStateNormal];
    [button setBackgroundImage:stateHighlighted
                      forState:UIControlStateHighlighted];
    [button setBackgroundImage:stateHighlighted
                      forState:UIControlStateSelected];
    [button addTarget:self
               action:@selector(myAction)
     forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.menuView addSubview:button];
    [self.menuView bringSubviewToFront:button];

}

-(void)setUpMenuFrames
{
    ///StartPosition
    if ([Util getScreenHeight]==kIphone4ScreenHeight) {
        self.menuBackButton.frame = CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone4ScreenHeight/2)-(kContinueButtonSize/2)-(kMenuIPhone4GapSize)-(2*kMenuButtonSize)-kMenuIPhone4ContinueGapSize, kMenuButtonSize, kMenuButtonSize);
        
        self.menuRestartButton.frame = CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone4ScreenHeight/2)-(kContinueButtonSize/2)-kMenuIPhone4ContinueGapSize-(kMenuButtonSize),  kMenuButtonSize, kMenuButtonSize);
        self.menuContinueButton.frame = CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone4ScreenHeight/2)-(kContinueButtonSize/2),  kContinueButtonSize, kContinueButtonSize);
        self.menuScreenshotButton.frame = CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone4ScreenHeight/2)+(kContinueButtonSize/2)+kMenuIPhone4ContinueGapSize,  kMenuButtonSize, kMenuButtonSize);
        self.menuAxisButton.frame = CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone4ScreenHeight/2)+(kContinueButtonSize/2)+(kMenuIPhone4GapSize)+kMenuIPhone4ContinueGapSize+(kMenuButtonSize),  kMenuButtonSize, kMenuButtonSize);
    }
    if ([Util getScreenHeight]==kIphone5ScreenHeight) {
        self.menuBackButton.frame = CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone5ScreenHeight/2)-(kContinueButtonSize/2)-(KMenuIPhone5GapSize)-kMenuIPhone5ContinueGapSize-(2*kMenuButtonSize), kMenuButtonSize, kMenuButtonSize);
        self.menuRestartButton.frame = CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone5ScreenHeight/2)-(kContinueButtonSize/2)-kMenuIPhone5ContinueGapSize-(kMenuButtonSize),  kMenuButtonSize, kMenuButtonSize);
        self.menuContinueButton.frame = CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone5ScreenHeight/2)-(kContinueButtonSize/2),  kContinueButtonSize, kContinueButtonSize);
        self.menuScreenshotButton.frame = CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone5ScreenHeight/2)+(kContinueButtonSize/2)+kMenuIPhone5ContinueGapSize,  kMenuButtonSize, kMenuButtonSize);
        self.menuAxisButton.frame = CGRectMake(-(kPlaceOfButtons-kWidthSlideMenu),(kIphone5ScreenHeight/2)+(kContinueButtonSize/2)+(KMenuIPhone5GapSize)+kMenuIPhone5ContinueGapSize+(kMenuButtonSize),  kMenuButtonSize, kMenuButtonSize);
    }
    
    self.menuView.frame = CGRectMake(0, 0, 0, self.menuView.frame.size.height);
}

-(void)setUpGridView
{
    self.gridView.backgroundColor = [UIColor clearColor];
    UIView *xArrow = [[UIView alloc] initWithFrame:CGRectMake(0,[Util getScreenHeight]/2,[Util getScreenWidth],1)];
    xArrow.backgroundColor = [UIColor redColor];
    [self.gridView addSubview:xArrow];
    UIView *yArrow = [[UIView alloc] initWithFrame:CGRectMake([Util getScreenWidth]/2,0,1,[Util getScreenHeight])];
    yArrow.backgroundColor = [UIColor redColor];
    [self.gridView addSubview:yArrow];
    //nullLabel
    UILabel *nullLabel = [[UILabel alloc] initWithFrame:CGRectMake([Util getScreenWidth]/2 + 5, [Util getScreenHeight]/2 + 5, 10, 15)];
    nullLabel.text = @"0";
    nullLabel.textColor = [UIColor redColor];
    [self.gridView addSubview:nullLabel];
    //positveWidth
    UILabel *positiveWidth = [[UILabel alloc] initWithFrame:CGRectMake([Util getScreenWidth]- 40, [Util getScreenHeight]/2 + 5, 30, 15)];
    positiveWidth.text = [NSString stringWithFormat:@"%d",(int)self.program.header.screenWidth.floatValue/2];
    positiveWidth.textColor = [UIColor redColor];
    [self.gridView addSubview:positiveWidth];
    //negativWidth
    UILabel *negativeWidth = [[UILabel alloc] initWithFrame:CGRectMake(5, [Util getScreenHeight]/2 + 5, 40, 15)];
    negativeWidth.text = [NSString stringWithFormat:@"-%d",(int)self.program.header.screenWidth.floatValue/2];
    negativeWidth.textColor = [UIColor redColor];
    [self.gridView addSubview:negativeWidth];
    //positveHeight
    UILabel *positiveHeight = [[UILabel alloc] initWithFrame:CGRectMake([Util getScreenWidth]/2 + 5, [Util getScreenHeight] - 20, 40, 15)];
    positiveHeight.text = [NSString stringWithFormat:@"-%d",(int)self.program.header.screenHeight.floatValue/2];
    positiveHeight.textColor = [UIColor redColor];
    [self.gridView addSubview:positiveHeight];
    //negativHeight
    UILabel *negativeHeight = [[UILabel alloc] initWithFrame:CGRectMake([Util getScreenWidth]/2 + 5,5, 40, 15)];
    negativeHeight.text = [NSString stringWithFormat:@"%d",(int)self.program.header.screenHeight.floatValue/2];
    negativeHeight.textColor = [UIColor redColor];
    [self.gridView addSubview:negativeHeight];
    
    [self.skView addSubview:self.gridView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.menuOpen = NO;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void) configureScene
{
    SKView *skView = (SKView*) self.skView;
    [self.view addSubview:skView];
#ifdef DEBUG
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
#endif
    
    //Program* program = [self loadProgram];
    CGSize programSize = CGSizeMake(self.program.header.screenWidth.floatValue, self.program.header.screenHeight.floatValue);
    self.scene = [[Scene alloc] initWithSize:programSize andProgram:self.program];
    self.scene.scaleMode = SKSceneScaleModeAspectFit;
    [skView presentScene:self.scene];
    [[ProgramManager sharedProgramManager] setProgram:self.program];
}


-(void)dealloc
{
    [[AudioManager sharedAudioManager] stopAllSounds];
    [[SensorHandler sharedSensorHandler] stopSensors];
    
    // NOTE: if there are still some runNextAction tasks in a queue
    // then these actions must not be executed because the Scene is not available any more.
    // This problem caused the app to crash sometimes in the past.
    // Now these lines fix this issue.
    for (SpriteObject *sprite in self.program.objectList)
    {
        sprite.broadcastWaitDelegate = nil;
        for (Script *script in sprite.scriptList) {
            script.allowRunNextAction = NO;
        }
    }
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 0) {
        
        [self.navigationController popViewControllerAnimated:YES];
        
    }
}

- (void)backButtonPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)revealMenu:(UIButton*)sender
{
    SKView * view= (SKView*)_skView;
    view.paused=YES;
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [[AudioManager sharedAudioManager] pauseAllSounds];
    
    [UIView animateWithDuration:0.6
                          delay:0.3
                        options: UIViewAnimationOptionTransitionFlipFromLeft
                     animations:^{[self revealAnimation];}
                     completion:^(BOOL finished){
                         self.menuOpen = YES;
                     }];
}

-(void)revealAnimation
{
    [self.view bringSubviewToFront:self.menuView];
    self.menuView.frame = CGRectMake(0, 0, kWidthSlideMenu, self.menuView.frame.size.height);
    
    self.menuBackButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2),self.menuBackButton.frame.origin.y, self.menuBackButton.frame.size.width, self.menuBackButton.frame.size.height);
    self.menuBackLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2),self.menuBackLabel.frame.origin.y,self.menuBackLabel.frame.size.width,self.menuBackLabel.frame.size.height);
    
    self.menuContinueButton.frame = CGRectMake(kPlaceOfButtons+kContinueOffset,self.menuContinueButton.frame.origin.y, self.menuContinueButton.frame.size.width, self.menuContinueButton.frame.size.height);
    self.menuContinueLabel.frame = CGRectMake(kPlaceofContinueLabel+kContinueOffset,self.menuContinueLabel.frame.origin.y,self.menuContinueLabel.frame.size.width,self.menuContinueLabel.frame.size.height);
    
    self.menuScreenshotButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2),self.menuScreenshotButton.frame.origin.y, self.menuScreenshotButton.frame.size.width, self.menuScreenshotButton.frame.size.height);
    self.menuScreenshotLabel.frame =CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2),self.menuScreenshotLabel.frame.origin.y,self.menuScreenshotLabel.frame.size.width,self.menuScreenshotLabel.frame.size.height);
    
    self.menuRestartButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2),self.menuRestartButton.frame.origin.y, self.menuRestartButton.frame.size.width, self.menuRestartButton.frame.size.height);
    self.menuRestartLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2),self.menuRestartLabel.frame.origin.y,self.menuRestartLabel.frame.size.width,self.menuRestartLabel.frame.size.height);
    
    self.menuAxisButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2),self.menuAxisButton.frame.origin.y, self.menuAxisButton.frame.size.width, self.menuAxisButton.frame.size.height);
    self.menuAxisLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2),self.menuAxisLabel.frame.origin.y,self.menuAxisLabel.frame.size.width,self.menuAxisLabel.frame.size.height);
    
    self.menuBtn.hidden=YES;
    
}

-(void)goback:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}



#pragma button functions

- (void)stopLevel:(UIButton *)sender
{
    self.skView = nil;
    [self.navigationController setToolbarHidden:NO];
    [self.navigationController popViewControllerAnimated:YES];
    
    [self.controller.navigationController setToolbarHidden:NO];
    [self.controller.navigationController setNavigationBarHidden:NO];
    
}

- (void)continueLevel:(UIButton *)sender withDuration:(float)duration
{
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    float animateDuration;
    if (duration != 1) {
        animateDuration= 0.4;
    }
    else{
        animateDuration = duration;
    }
    [UIView animateWithDuration:animateDuration
                          delay:0.1
                        options: UIViewAnimationOptionTransitionFlipFromRight
                     animations:^{[self continueAnimation];}
                     completion:^(BOOL finished){
                         self.menuOpen = NO;
                     }];
    SKView * view= (SKView*)_skView;
    view.paused=NO;
    //[[AVAudioSession sharedInstance] setActive:YES error:nil];
    if (duration != kDontResumeSounds) {
        [[AudioManager sharedAudioManager] resumeAllSounds];
    }
}

-(void)continueAnimation
{
    self.menuView.frame = CGRectMake(0, 0, 0, self.menuView.frame.size.height);
    self.menuBackButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuBackButton.frame.origin.y, self.menuBackButton.frame.size.width, self.menuBackButton.frame.size.height);
    self.menuBackLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuBackLabel.frame.origin.y, self.menuBackLabel.frame.size.width, self.menuBackLabel.frame.size.height);
    
    self.menuContinueButton.frame = CGRectMake(kPlaceOfButtons+kContinueOffset-kWidthSlideMenu,self.menuContinueButton.frame.origin.y, self.menuContinueButton.frame.size.width, self.menuContinueButton.frame.size.height);
    self.menuContinueLabel.frame = CGRectMake(kPlaceofContinueLabel+kContinueOffset-kWidthSlideMenu,self.menuContinueLabel.frame.origin.y, self.menuContinueLabel.frame.size.width, self.menuContinueLabel.frame.size.height);
    
    self.menuScreenshotButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuScreenshotButton.frame.origin.y, self.menuScreenshotButton.frame.size.width, self.menuScreenshotButton.frame.size.height);
    self.menuScreenshotLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuScreenshotLabel.frame.origin.y, self.menuScreenshotLabel.frame.size.width, self.menuScreenshotLabel.frame.size.height);
    
    self.menuRestartButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuRestartButton.frame.origin.y, self.menuRestartButton.frame.size.width, self.menuRestartButton.frame.size.height);
    self.menuRestartLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuRestartLabel.frame.origin.y, self.menuRestartLabel.frame.size.width, self.menuRestartLabel.frame.size.height);
    
    self.menuAxisButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuAxisButton.frame.origin.y, self.menuAxisButton.frame.size.width, self.menuAxisButton.frame.size.height);
    self.menuAxisLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuAxisLabel.frame.origin.y, self.menuAxisLabel.frame.size.width, self.menuAxisLabel.frame.size.height);
    
    //self.menuBtn.hidden=NO;
}



- (BOOL)loadProgram:(ProgramLoadingInfo*)loadingInfo
{
    NSDebug(@"Try to load project '%@'", loadingInfo.visibleName);
    NSDebug(@"Path: %@", loadingInfo.basePath);
    NSString *xmlPath = [NSString stringWithFormat:@"%@", loadingInfo.basePath];
    NSDebug(@"XML-Path: %@", xmlPath);
    Program *program = [[[Parser alloc] init] generateObjectForLevel:[xmlPath stringByAppendingFormat:@"%@", kProgramCodeFileName]];
    
    if (! program)
        return NO;
    
    NSDebug(@"ProjectResolution: width/height:  %f / %f", program.header.screenWidth.floatValue, program.header.screenHeight.floatValue);
    
    // setting effect
    for (SpriteObject *sprite in program.objectList)
    {
        //sprite.spriteManagerDelegate = self;
        //sprite.broadcastWaitDelegate = self.broadcastWaitHandler;
        
        // TODO: change!
        for (Script *script in sprite.scriptList) {
            for (Brick *brick in script.brickList) {
                brick.object = sprite;
            }
        }
    }
    self.program = program;
    [Util setLastProgram:self.program.header.programName];
    return YES;
}


-(void)restartLevel:(UIButton*) sender
{
    ///Reset Scene
    self.scene = nil;
    self.scene.scaleMode = SKSceneScaleModeAspectFit;
    SKView * view= (SKView*)self.skView;
    view.paused=NO;
    BOOL check = [self loadProgram:[Util programLoadingInfoForProgramWithName:[Util lastProgram]]];
    if (check) {
        [view presentScene:self.scene];
        [self configureScene];
        [self continueLevel:nil withDuration:kDontResumeSounds];
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can't restart level!",nil)
                                                        message:nil
                                                       delegate:self.menuView
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
}


-(void)showHideAxis:(UIButton *)sender
{
    if(self.gridView.hidden == NO)
    {
        self.gridView.hidden = YES;
    }
    else{
        self.gridView.hidden = NO;
    }
    
}


- (void)takeScreenshot:(UIButton *)sender
{
    /// Screenshot function
    UIGraphicsBeginImageContextWithOptions(self.skView.bounds.size, NO, [UIScreen mainScreen].scale);
    [self.skView drawViewHierarchyInRect:self.skView.bounds afterScreenUpdates:NO];
    self.snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self showSaveScreenshotActionSheet];
    
}
- (void)showSaveScreenshotActionSheet
{
    //  NSString *actionSheetTitle = NSLocalizedString(@"Save Screenshot to:",@"Action sheet menu title");
    //  NSString *buttonSaveToCameraRoll = NSLocalizedString(@"Camera Roll",nil);
    //  NSString *buttonSaveToProject = NSLocalizedString(@"Project",nil);
    //  NSString *cancelTitle = NSLocalizedString(@"Cancel",nil);
    //  UIActionSheet *actionSheet = [[UIActionSheet alloc]
    //                                initWithTitle:actionSheetTitle
    //                                delegate:self
    //                                cancelButtonTitle:cancelTitle
    //                                destructiveButtonTitle:nil
    //                                otherButtonTitles:buttonSaveToCameraRoll, buttonSaveToProject,  nil];
    //  [actionSheet showInView:self.menuView];
    
    UIImage *imageToShare = self.snapshotImage;
    NSString* path = [self.program projectPath];
    NSArray *itemsToShare = @[imageToShare];
    
    SaveToProjectActivity *saveToProjectActivity = [[SaveToProjectActivity alloc] initWithImagePath:path];
    NSArray *activities = @[saveToProjectActivity];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:activities];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact,UIActivityTypePostToFlickr,UIActivityTypePostToFacebook,UIActivityTypePostToVimeo,UIActivityTypePostToWeibo,UIActivityTypePostToTwitter,UIActivityTypeMail]; //or whichever you don't need
    [self presentViewController:activityVC animated:YES completion:nil];
}
//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//  NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
//  if ([buttonTitle isEqualToString:NSLocalizedString(@"Camera Roll",nil)]) {
//    /// Write to Camera Roll
//    UIImageWriteToSavedPhotosAlbum(self.snapshotImage, nil, nil, nil);
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Screenshot saved to CameraRoll!",nil)
//                                                    message:nil
//                                                   delegate:self.menuView
//                                          cancelButtonTitle:NSLocalizedString(@"OK",nil)
//                                          otherButtonTitles:nil];
//    [alert show];
//  }
//  if ([buttonTitle isEqualToString:NSLocalizedString(@"Project",nil)]) {
//    NSString* path = [self.program projectPath];
//    NSString *pngFilePath = [NSString stringWithFormat:@"%@/manual_screenshot.png",path];
//    NSData *data = [NSData dataWithData:UIImagePNGRepresentation(self.snapshotImage)];
//    [data writeToFile:pngFilePath atomically:YES];
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Screenshot saved to Project!",nil)
//                                                    message:nil
//                                                   delegate:self.menuView
//                                          cancelButtonTitle:NSLocalizedString(@"OK",nil)
//                                          otherButtonTitles:nil];
//    [alert show];
//
//  }
//
//}


#pragma PanGestureHandler
- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
    CGPoint translate = [gesture translationInView:gesture.view];
    translate.y = 0.0;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.firstGestureTouchPoint = [gesture locationInView:gesture.view];
    }
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        if (translate.x > 0.0 && translate.x < kWidthSlideMenu && self.menuOpen == NO && self.firstGestureTouchPoint.x < kSlidingStartArea)
        {
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{[self handlePositvePan:translate];}
                             completion:^(BOOL finished) {
                                 //self.menuOpen = YES;
                                 //[[AudioManager sharedAudioManager] pauseAllSounds];
                             }];
        }
        
        else if (translate.x < 0.0 && translate.x > -kWidthSlideMenu && self.menuOpen == YES)
        {
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{[self handleNegativePan:translate];}
                             completion:^(BOOL finished) {
                                 //                         SKView * view= (SKView*)_skView;
                                 //                         view.paused=NO;
                                 //                         [[AudioManager sharedAudioManager] resumeAllSounds];
                                 //                         self.menuOpen = NO;
                             }];
        }
    }
    
    if (gesture.state == UIGestureRecognizerStateCancelled ||
        gesture.state == UIGestureRecognizerStateEnded ||
        gesture.state == UIGestureRecognizerStateFailed)
    {
        
        if (translate.x > 0.0 && self.menuOpen == NO && self.firstGestureTouchPoint.x < kSlidingStartArea)
        {
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{[self handleCancelledPositive:translate];}
                             completion:^(BOOL finished) {
                                 self.menuOpen = YES;
                                 //pause Scene
                                 SKView * view= (SKView*)_skView;
                                 view.paused=YES;
                                 //view.userInteractionEnabled = NO;
                                 [[AudioManager sharedAudioManager] pauseAllSounds];
                             }];
        }
        else if (translate.x < 0.0  && self.menuOpen == YES)
        {
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{[self handleCancelledNegative:translate];}
                             completion:^(BOOL finished) {
                                 SKView * view= (SKView*)_skView;
                                 view.paused=NO;
                                 //view.userInteractionEnabled = YES;
                                 self.menuOpen= NO;
                                 //[[AVAudioSession sharedInstance] setActive:YES error:nil];
                                 [[AudioManager sharedAudioManager] resumeAllSounds];
                             }];
        }
        
        
    }
}


-(void)handlePositvePan:(CGPoint)translate
{
    [self.view bringSubviewToFront:self.menuView];
    //                         UIColor *background = [UIColor darkBlueColor];//[[UIColor alloc] initWithPatternImage:snapshotImage];
    //                         self.menuView.backgroundColor = background;
    
    //                         SKView * view= (SKView*)_skView;
    //                         view.paused=YES;
    
    self.menuView.frame = CGRectMake(0, 0, translate.x, self.menuView.frame.size.height);
    self.menuBackButton.frame = CGRectMake(translate.x+kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuBackButton.frame.origin.y, self.menuBackButton.frame.size.width, self.menuBackButton.frame.size.height);
    self.menuBackLabel.frame = CGRectMake(translate.x+kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuBackLabel.frame.origin.y, self.menuBackLabel.frame.size.width, self.menuBackLabel.frame.size.height);
    
    self.menuContinueButton.frame = CGRectMake(translate.x+kContinueOffset+kPlaceOfButtons-kWidthSlideMenu,self.menuContinueButton.frame.origin.y, self.menuContinueButton.frame.size.width, self.menuContinueButton.frame.size.height);
    self.menuContinueLabel.frame =CGRectMake(translate.x+kContinueOffset+kPlaceofContinueLabel-kWidthSlideMenu,self.menuContinueLabel.frame.origin.y, self.menuContinueLabel.frame.size.width, self.menuContinueLabel.frame.size.height);
    
    self.menuScreenshotButton.frame = CGRectMake(translate.x+kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuScreenshotButton.frame.origin.y, self.menuScreenshotButton.frame.size.width, self.menuScreenshotButton.frame.size.height);
    self.menuScreenshotLabel.frame = CGRectMake(translate.x+kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuScreenshotLabel.frame.origin.y, self.menuScreenshotLabel.frame.size.width, self.menuScreenshotLabel.frame.size.height);
    
    self.menuRestartButton.frame = CGRectMake(translate.x+kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuRestartButton.frame.origin.y, self.menuRestartButton.frame.size.width, self.menuRestartButton.frame.size.height);
    self.menuRestartLabel.frame = CGRectMake(translate.x+kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuRestartLabel.frame.origin.y, self.menuRestartLabel.frame.size.width, self.menuRestartLabel.frame.size.height);
    
    self.menuAxisButton.frame = CGRectMake(translate.x+kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuAxisButton.frame.origin.y, self.menuAxisButton.frame.size.width, self.menuAxisButton.frame.size.height);
    self.menuAxisLabel.frame =CGRectMake(translate.x+kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuAxisLabel.frame.origin.y, self.menuAxisLabel.frame.size.width, self.menuAxisLabel.frame.size.height);
    
    self.menuBtn.hidden=YES;
}

-(void)handleNegativePan:(CGPoint)translate
{
    self.menuView.frame = CGRectMake(0, 0, kWidthSlideMenu+translate.x, self.menuView.frame.size.height);
    self.menuBackButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)+translate.x,self.menuBackButton.frame.origin.y, self.menuBackButton.frame.size.width, self.menuBackButton.frame.size.height);
    self.menuBackLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)+translate.x,self.menuBackLabel.frame.origin.y, self.menuBackLabel.frame.size.width, self.menuBackLabel.frame.size.height);
    
    self.menuContinueButton.frame = CGRectMake(kPlaceOfButtons+kContinueOffset+translate.x,self.menuContinueButton.frame.origin.y, self.menuContinueButton.frame.size.width, self.menuContinueButton.frame.size.height);
    self.menuContinueLabel.frame =CGRectMake(kPlaceofContinueLabel+kContinueOffset+translate.x,self.menuContinueLabel.frame.origin.y, self.menuContinueLabel.frame.size.width, self.menuContinueLabel.frame.size.height);
    
    self.menuScreenshotButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)+translate.x,self.menuScreenshotButton.frame.origin.y, self.menuScreenshotButton.frame.size.width, self.menuScreenshotButton.frame.size.height);
    self.menuScreenshotLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)+translate.x,self.menuScreenshotLabel.frame.origin.y, self.menuScreenshotLabel.frame.size.width, self.menuScreenshotLabel.frame.size.height);
    
    self.menuRestartButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)+translate.x,self.menuRestartButton.frame.origin.y, self.menuRestartButton.frame.size.width, self.menuRestartButton.frame.size.height);
    self.menuRestartLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)+translate.x,self.menuRestartLabel.frame.origin.y, self.menuRestartLabel.frame.size.width, self.menuRestartLabel.frame.size.height);
    
    self.menuAxisButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)+translate.x,self.menuAxisButton.frame.origin.y, self.menuAxisButton.frame.size.width, self.menuAxisButton.frame.size.height);
    self.menuAxisLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)+translate.x,self.menuAxisLabel.frame.origin.y, self.menuAxisLabel.frame.size.width, self.menuAxisLabel.frame.size.height);
    
    self.menuBtn.hidden=NO;
}

-(void)handleCancelledPositive:(CGPoint)translate
{
    [self.view bringSubviewToFront:self.menuView];
    //                         UIColor *background = [UIColor darkBlueColor];//[[UIColor alloc] initWithPatternImage:snapshotImage];
    //                         self.menuView.backgroundColor = background;
    
    self.menuView.frame = CGRectMake(0, 0, kWidthSlideMenu, self.menuView.frame.size.height);
    self.menuBackButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2),self.menuBackButton.frame.origin.y, self.menuBackButton.frame.size.width, self.menuBackButton.frame.size.height);
    self.menuBackLabel.frame =CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2),self.menuBackLabel.frame.origin.y, self.menuBackLabel.frame.size.width, self.menuBackLabel.frame.size.height);
    
    self.menuContinueButton.frame = CGRectMake(kPlaceOfButtons+kContinueOffset,self.menuContinueButton.frame.origin.y, self.menuContinueButton.frame.size.width, self.menuContinueButton.frame.size.height);
    self.menuContinueLabel.frame = CGRectMake(kPlaceofContinueLabel+kContinueOffset,self.menuContinueLabel.frame.origin.y, self.menuContinueLabel.frame.size.width, self.menuContinueLabel.frame.size.height);
    
    self.menuScreenshotButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2),self.menuScreenshotButton.frame.origin.y, self.menuScreenshotButton.frame.size.width, self.menuScreenshotButton.frame.size.height);
    self.menuScreenshotLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2),self.menuScreenshotLabel.frame.origin.y, self.menuScreenshotLabel.frame.size.width, self.menuScreenshotLabel.frame.size.height);
    
    self.menuRestartButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2),self.menuRestartButton.frame.origin.y, self.menuRestartButton.frame.size.width, self.menuRestartButton.frame.size.height);
    self.menuRestartLabel.frame =CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2),self.menuRestartLabel.frame.origin.y, self.menuRestartLabel.frame.size.width, self.menuRestartLabel.frame.size.height);
    
    
    self.menuAxisButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2),self.menuAxisButton.frame.origin.y, self.menuAxisButton.frame.size.width, self.menuAxisButton.frame.size.height);
    self.menuAxisLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2),self.menuAxisLabel.frame.origin.y, self.menuAxisLabel.frame.size.width, self.menuAxisLabel.frame.size.height);
    
    self.menuBtn.hidden=YES;

}


-(void)handleCancelledNegative:(CGPoint)translate
{
    self.menuView.frame = CGRectMake(0, 0, 0, self.menuView.frame.size.height);
    self.menuBackButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuBackButton.frame.origin.y, self.menuBackButton.frame.size.width, self.menuBackButton.frame.size.height);
    self.menuBackLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuBackLabel.frame.origin.y, self.menuBackLabel.frame.size.width, self.menuBackLabel.frame.size.height);
    
    self.menuContinueButton.frame = CGRectMake(kPlaceOfButtons+kContinueOffset-kWidthSlideMenu,self.menuContinueButton.frame.origin.y, self.menuContinueButton.frame.size.width, self.menuContinueButton.frame.size.height);
    self.menuContinueLabel.frame = CGRectMake(kPlaceofContinueLabel+kContinueOffset-kWidthSlideMenu,self.menuContinueLabel.frame.origin.y, self.menuContinueLabel.frame.size.width, self.menuContinueLabel.frame.size.height);
    
    self.menuScreenshotButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuScreenshotButton.frame.origin.y, self.menuScreenshotButton.frame.size.width, self.menuScreenshotButton.frame.size.height);
    self.menuScreenshotLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuScreenshotLabel.frame.origin.y, self.menuScreenshotLabel.frame.size.width, self.menuScreenshotLabel.frame.size.height);
    
    self.menuRestartButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuRestartButton.frame.origin.y, self.menuRestartButton.frame.size.width, self.menuRestartButton.frame.size.height);
    self.menuRestartLabel.frame =CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuRestartLabel.frame.origin.y, self.menuRestartLabel.frame.size.width, self.menuRestartLabel.frame.size.height);
    
    self.menuAxisButton.frame = CGRectMake(kPlaceOfButtons+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuAxisButton.frame.origin.y, self.menuAxisButton.frame.size.width, self.menuAxisButton.frame.size.height);
    self.menuAxisLabel.frame = CGRectMake(kPlaceofLabels+((kContinueButtonSize-kMenuButtonSize)/2)-kWidthSlideMenu,self.menuAxisLabel.frame.origin.y, self.menuAxisLabel.frame.size.width, self.menuAxisLabel.frame.size.height);
    self.menuBtn.hidden=NO;

}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch* touch in touches) {
        CGPoint location = [touch locationInView:self.skView];
        NSDebug(@"StartTouch1");
        if ([self.scene touchedwith:touches withX:location.x andY:location.y]) {
            break;
        }
    }
    
}



@end

