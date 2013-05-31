//
//  StageViewController.m
//  Catty
//
//  Created by Mattias Rauter on 03.04.13.
//
//

#import "StageViewController.h"
#import "Parser.h"
#import "Program.h"
#import "SpriteObject.h"
#import "BroadcastWaitHandler.h"
#import "Brick.h"
#import "Script.h"
#import "StartScript.h"
#import "WhenScript.h"
#import "BroadcastScript.h"
#import "Stage.h"
#import "ProgramLoadingInfo.h"
#import "Util.h"
#import "ProgramDefines.h"
#import "TestParser.h"
#import "Sparrow.h"
#import "ProgramManager.h"
#import "SensorHandler.h"
#import "Logger.h"

@interface StageViewController () <SpriteManagerDelegate>

@property (nonatomic, assign) BOOL firstDrawing;
@property (nonatomic, assign) CGSize projectSize;
@property (nonatomic, strong) BroadcastWaitHandler *broadcastWaitHandler;
@property (nonatomic, strong) Program* program;


@end

@implementation StageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.firstDrawing = YES;
        self.broadcastWaitHandler = [[BroadcastWaitHandler alloc]init];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [Util setLastProgram:self.programLoadingInfo.visibleName];
    
    UIButton* backButton = [[UIButton alloc] initWithFrame:CGRectMake(10.0f, 7.0f, 33.0f, 44.0f)];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIImage* backImage = [UIImage imageNamed:@"back"];
    [backButton setImage:backImage forState:UIControlStateNormal];
    [self.navigationController.view.superview addSubview:backButton];
    [self.navigationController.tabBarController.view.superview addSubview:backButton];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[SensorHandler sharedSensorHandler] stopSensors];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}



- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [super glkView:view drawInRect:rect];
    if (self.firstDrawing) {
        
        // just for test parser
        TestParser *testparser = [[TestParser alloc] init];
//        Program *program = nil;
        
//        self.program = [testparser generateDebugProject_GlideTo];
//        self.program = [testparser generateDebugProject_nextCostume];
//        self.program = [testparser generateDebugProject_HideShow];
//        self.program = [testparser generateDebugProject_SetXY];
//        self.program = [testparser generateDebugProject_broadcast];
//        self.program = [testparser generateDebugProject_broadcastWait];
//        self.program = [testparser generateDebugProject_comeToFront];
//        self.program = [testparser generateDebugProject_goNStepsBack];
//        self.program = [testparser generateDebugProject_pointToDirection];
//        self.program = [testparser generateDebugProject_setBrightness];
//        self.program = [testparser generateDebugProject_changeSizeByN];
//        self.program = [testparser generateDebugProject_parallelScripts];
//        self.program = [testparser generateDebugProject_loops];
//        self.program = [testparser generateDebugProject_rotate];
//        self.program = [testparser generateDebugProject_rotateFullCircle];
//        self.program = [testparser generateDebugProject_rotateAndMove];
//        self.program = [testparser generateDebugProject_transparency];
        
        self.projectSize = CGSizeMake(self.program.header.screenWidth.floatValue, self.program.header.screenHeight.floatValue); // (normally set in loadProgram)

        
        
        
        // parse Program
        Stage *stage = nil;
        self.program = [self loadProgram];
        [[ProgramManager sharedProgramManager] setProgram:self.program];
        
        if ([self.root isKindOfClass:[Stage class]]) {
            stage = (Stage*)self.root;
            stage.program = self.program;
        } else {
            abort();
        }
    
        
        
        
//////////////////////////////////// START DEBUG
        //setting effect
        for (SpriteObject *sprite in self.program.objectList)
        {
            sprite.spriteManagerDelegate = self;
            sprite.broadcastWaitDelegate = self.broadcastWaitHandler;
            
            // TODO: change!
            for (Script *script in sprite.scriptList) {
                for (Brick *brick in script.brickList) {
                    brick.object = sprite;
                }
            }
            // debug:
            NSLog(@"----------------------");
            NSLog(@"Sprite: %@", sprite.name);
            NSLog(@" ");
            NSLog(@"StartScript:");
            for (Script *script in sprite.scriptList) {
                if ([script isKindOfClass:[Startscript class]]) {
                    for (Brick *brick in [script getAllBricks]) {
                        NSLog(@"  %@", [brick description]);
                    }
                }
            }
            for (Script *script in sprite.scriptList) {
                if ([script isKindOfClass:[Whenscript class]]) {
                    NSLog(@" ");
                    NSLog(@"WhenScript:");
                    for (Brick *brick in [script getAllBricks]) {
                        NSLog(@"  %@", [brick description]);
                    }
                }
            }
            for (Script *script in sprite.scriptList) {
                if ([script isKindOfClass:[Broadcastscript class]]) {
                    NSLog(@" ");
                    NSLog(@"BroadcastScript:");
                    for (Brick *brick in [script getAllBricks]) {
                        NSLog(@"  %@", [brick description]);
                    }
                }
            }
        }
//////////////////////////////////////////////// END DEBUG
        
        
        
                
        
        float screenWidth  = [UIScreen mainScreen].bounds.size.width;
        float screenHeight = [UIScreen mainScreen].bounds.size.height;
        
        
        float scaleFactor = 1.0f;
        if (self.projectSize.width > 0 && self.projectSize.height > 0) {
            float scaleX = screenWidth  / self.projectSize.width;
            float scaleY = screenHeight / self.projectSize.height;
            scaleFactor = MIN(scaleX, scaleY);
        }
        
        int xOffset = (screenWidth  - (self.projectSize.width  * scaleFactor)) / 2.0f;
        int yOffset = (screenHeight - (self.projectSize.height * scaleFactor)) / 2.0f;
        

        
        NSLog(@"Scale screen size:");
        NSLog(@"  Device:    %f / %f    (%f)", screenWidth, screenHeight, screenWidth/screenHeight);
        NSLog(@"  Project:   %f / %f    (%f)", self.projectSize.width, self.projectSize.height, self.projectSize.width/self.projectSize.height);
        NSLog(@"  Scale-Factor: %f",   scaleFactor);
        NSLog(@"  Offset:    %d / %d", xOffset, yOffset);
        
        float width  = screenWidth  - (2 * xOffset);
        float height = screenHeight - (2 * yOffset);
        
        
        Sparrow.stage.width  = self.projectSize.width;      // = XML-Project-width
        Sparrow.stage.height = self.projectSize.height;     // = XML-Project-heigth
        self.view.frame = CGRectMake(xOffset, yOffset, width, height);  // STAGE!!! TODO: calculat ratio and offset
        self.navigationController.view.frame = CGRectMake(xOffset, yOffset, width, height);

        self.firstDrawing = NO;
        
                
//        stage.pivotX = Sparrow.stage.width  / 2.0f;
//        stage.pivotY = Sparrow.stage.height / 2.0f;
//        stage.x = Sparrow.stage.width  / 2.0f;
//        stage.y = Sparrow.stage.height / 2.0f;
        
        
        [stage start];
    }
}


-(void)initView
{
    
}


- (Program*)loadProgram
{
    
    [Logger debug:@"Try to load project '%@'", self.programLoadingInfo.visibleName];
    [Logger debug:@"Path: %@", self.programLoadingInfo.basePath];
        

    NSString *xmlPath = [NSString stringWithFormat:@"%@", self.programLoadingInfo.basePath];
    
    [Logger debug:@"XML-Path: %@", xmlPath];
    
    Parser *parser = [[Parser alloc]init];
    Program *program = [parser generateObjectForLevel:[xmlPath stringByAppendingFormat:@"%@", kProgramCodeFileName]];
                        
    if(!program) {
        [Logger error:@"Program could not be loaded!"];
        [NSException raise:@"Invalid Program" format:@"Program %@ could not be loaded!",  self.programLoadingInfo.visibleName];
    }
    

    [Logger debug:@"ProjectResolution: width/height:  %f / %f", program.header.screenWidth.floatValue, program.header.screenHeight.floatValue];

    self.projectSize = CGSizeMake(program.header.screenWidth.floatValue, program.header.screenHeight.floatValue);

    //setting effect
    for (SpriteObject *sprite in program.objectList)
    {
        sprite.spriteManagerDelegate = self;
        sprite.broadcastWaitDelegate = self.broadcastWaitHandler;
        sprite.projectPath = xmlPath;   //self.levelLoadingInfo.basePath;

        // TODO: change!
        for (Script *script in sprite.scriptList) {
            for (Brick *brick in script.brickList) {
                brick.object = sprite;
            }
        }




        // debug:
        [Logger debug:@"----------------------"];
        NSLog(@"Sprite: %@", sprite.name);
        NSLog(@" ");
        NSLog(@"StartScript:");
        for (Script *script in sprite.scriptList) {
            if ([script isKindOfClass:[Startscript class]]) {
                for (Brick *brick in [script getAllBricks]) {
                    NSLog(@"  %@", [brick description]);
                }
            }
        }
        for (Script *script in sprite.scriptList) {
            if ([script isKindOfClass:[Whenscript class]]) {
                NSLog(@" ");
                NSLog(@"WhenScript:");
                for (Brick *brick in [script getAllBricks]) {
                    NSLog(@"  %@", [brick description]);
                }
            }
        }
        for (Script *script in sprite.scriptList) {
            if ([script isKindOfClass:[Broadcastscript class]]) {
                NSLog(@" ");
                NSLog(@"BroadcastScript:");
                for (Brick *brick in [script getAllBricks]) {
                    NSLog(@"  %@", [brick description]);
                }
            }
        }
    }
    return program;
}

-(void)stopAllSounds
{
    for(SpriteObject* sprite in self.program.objectList)
    {
        [sprite stopAllSounds];
    }
}


- (void)backButtonPressed:(UIButton *)sender
{
    // stop program
    for (SpriteObject *sprite in self.program.objectList) {
        [sprite stopAllScripts];
        [sprite stopAllSounds];
    }
    
    [self.program.objectList removeAllObjects];
    self.program = nil;
    
    // dismiss view controller
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame];
    [sender removeFromSuperview];
    [self.navigationController popViewControllerAnimated:YES];
}




@end
