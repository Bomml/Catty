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
//#import "ProgramLoadingInfo.h"
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
#import "SlidingViewController.h"
#import "MenuViewController.h"
#import "MenuButtonViewController.h"
#import "SceneViewController.h"

@interface ScenePresenterViewController ()

@property (nonatomic, strong) BroadcastWaitHandler *broadcastWaitHandler;

@end

@implementation ScenePresenterViewController
@synthesize program = _program;
@synthesize skView = _skView;
@synthesize menuBtn;

# pragma getters and setters
- (BroadcastWaitHandler*)broadcastWaitHandler
{
    // lazy instantiation
    if (! _broadcastWaitHandler) {
        _broadcastWaitHandler = [[BroadcastWaitHandler alloc] init];
    }
    return _broadcastWaitHandler;
}

- (void)setProgram:(Program *)program
{
    // setting effect
    for (SpriteObject *sprite in program.objectList)
    {
        //sprite.spriteManagerDelegate = self;
        sprite.broadcastWaitDelegate = self.broadcastWaitHandler;
        //sprite.projectPath = xmlPath;
        
        // TODO: change!
        for (Script *script in sprite.scriptList) {
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
    
    
//Shadow
//    self.view.layer.shadowOpacity = 0.95f;
//    self.view.layer.shadowRadius = 10.0f;
//    self.view.layer.shadowColor = self.view.backgroundColor.CGColor;
    
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    [self configureScene];
    
    self.menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    menuBtn.frame = CGRectMake(8.0f, 10.0f, 34.0f, 24.0f);
    [menuBtn setBackgroundImage:[UIImage imageNamed:@"menuButton"] forState:UIControlStateNormal];
    [menuBtn addTarget:self action:@selector(revealMenu:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.menuBtn];
    
//    UIButton* backButton = [[UIButton alloc] initWithFrame:CGRectMake(10.0f, 7.0f, 33.0f, 44.0f)];
//    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//    UIImage* backImage = [UIImage imageNamed:@"back"];
//    [backButton setImage:backImage forState:UIControlStateNormal];
//    [self.view addSubview:backButton];
    

    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuButtonViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"MenuButton"];
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void) configureScene
{
    
    SKView * skView =(SKView*)_skView;
    [self.view addSubview:skView];
    //[self.view bringSubviewToFront:skView];
#ifdef DEBUG
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
#endif
    
    //Program* program = [self loadProgram];
    CGSize programSize = CGSizeMake(self.program.header.screenWidth.floatValue, self.program.header.screenHeight.floatValue);
    
    Scene * scene = [[Scene alloc] initWithSize:programSize andProgram:self.program];
    scene.scaleMode = SKSceneScaleModeAspectFit;
    [skView presentScene:scene];
    [[ProgramManager sharedProgramManager] setProgram:self.program];
}

/*
 - (Program*)loadProgram
 {
 
 NSDebug(@"Try to load project '%@'", self.programLoadingInfo.visibleName);
 NSDebug(@"Path: %@", self.programLoadingInfo.basePath);
 
 
 NSString *xmlPath = [NSString stringWithFormat:@"%@", self.programLoadingInfo.basePath];
 
 NSDebug(@"XML-Path: %@", xmlPath);
 
 Parser *parser = [[Parser alloc]init];
 Program *program = [parser generateObjectForLevel:[xmlPath stringByAppendingFormat:@"%@", kProgramCodeFileName]];
 
 if(!program) {
 
 NSString *popuperrormessage = [NSString stringWithFormat:@"Program %@ could not be loaded!",self.programLoadingInfo.visibleName];
 
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Program"
 message:popuperrormessage
 delegate:self
 cancelButtonTitle:@"OK"
 otherButtonTitles:nil];
 [alert show];
 
 }
 
 
 NSDebug(@"ProjectResolution: width/height:  %f / %f", program.header.screenWidth.floatValue, program.header.screenHeight.floatValue);
 
 
 //setting effect
 for (SpriteObject *sprite in program.objectList)
 {
 //sprite.spriteManagerDelegate = self;
 sprite.broadcastWaitDelegate = self.broadcastWaitHandler;
 sprite.projectPath = xmlPath;
 
 // TODO: change!
 for (Script *script in sprite.scriptList) {
 for (Brick *brick in script.brickList) {
 brick.object = sprite;
 }
 }
 }
 return program;
 }
 */

-(void)dealloc
{
    [[AudioManager sharedAudioManager] stopAllSounds];
    [[SensorHandler sharedSensorHandler] stopSensors];
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
    [self.slidingViewController anchorTopViewTo:Right];

//    SKView * view= (SKView*)self.view;
//    view.paused=YES;
}




@end

