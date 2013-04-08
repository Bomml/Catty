//
//  TestParser.m
//  Catty
//
//  Created by Christof Stromberger on 27.04.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "TestParser.h"
#import "enums.h"

#import "Program.h"
#import "Header.h"
#import "SpriteObject.h"
#import "Look.h"
#import "StartScript.h"
#import "WhenScript.h"
#import "BroadcastScript.h"
#import "Brick.h"
#import "SetLookBrick.h"
#import "PlaceAtBrick.h"
#import "GlideToBrick.h"
#import "WaitBrick.h"
#import "NextLookBrick.h"
#import "HideBrick.h"
#import "ShowBrick.h"
#import "SetXBrick.h"
#import "SetYBrick.h"
#import "BroadcastBrick.h"
#import "BroadcastWaitBrick.h"
#import "ComeToFrontBrick.h"
#import "ChangeSizeByNBrick.h"
#import "ForeverBrick.h"
#import "RepeatBrick.h"
#import "LoopEndBrick.h"
#import "TurnLeftBrick.h"
#import "TurnRightBrick.h"

#define IMAGE_FILE_NAME @"tmp.png"

@interface TestParser ()

- (Look*)createCostumeFromPath:(NSString*)path withName:(NSString*)name;
- (Program*)createDefaultLevel;
- (SpriteObject*)createSprite:(NSString*)name withPositionX:(NSInteger)x withPositionY:(NSInteger)y withCostumes:(NSArray*)costumesArray setCostumeIndex:(NSInteger)index;


@end

@implementation TestParser

@synthesize effect = _effect;
@synthesize zIndex = _zIndex;

//
////- (Project*)generateObjectForLevel:(NSString*)path
////{
////    self.zIndex = 0;
////    /// TODO: call xml-parser instead of following lines... I know, wrong place...doesn't matter...
////    
////    NSMutableArray *startScriptsMutable = [[NSMutableArray alloc] init];
////    NSMutableArray *whenScriptsMutable = [[NSMutableArray alloc] init];
////        
////    //creating new Project (with some default values, such as name and version)
////    Project *project = [self createDefaultLevel];
////    
////    //creating background look
////    LookData *costume1 = [self createCostumeFromPath:@"background.png" withName:@"Background"];
////    
////    //creating background sprite
////    Sprite *sprite1 = [self createSprite:@"Background" 
////                           withPositionX:0
////                           withPositionY:0
////                            withCostumes:[[NSArray alloc] initWithObjects:look1, nil] 
////                         setCostumeIndex:0];
////    
////    //creating background script
////    Script *newScript = [[Script alloc]init];
////    
////    //setLook brick for background at startup
////    SetLookBrick *newBrick = [[SetLookBrick alloc]init];
////    newBrick.look = [[LookData alloc]initWithName:@"Object" andPath:[[NSBundle bundleForClass:[self class]] pathForResource:IMAGE_FILE_NAME ofType:nil]];
////
//////    newBrick.sprite = sprite1;
//////    newScript.bricksArray = [[NSArray alloc]initWithObjects:newBrick, nil];
////    [newScript addBrick:newBrick];
////    
////    //check if its a startup script or a when script
//////    if ([newScript isMemberOfClass:[StartScript class]])
////////        [sprite1.startScriptsArray addObject:newScript];
//////        [sprite1 addStartScript:newScript];
//////        //[startScriptsMutable addObject:newScript];
//////    else if ([newScript isMemberOfClass:[WhenScript class]])
////////        [sprite1.whenScriptsArray addObject:newScript];
////        [sprite1 addWhenScript:newScript];
////        //[whenScriptsMutable addObject:newScript];
////    
////    
////    //creating cat looks (normal and ceshire cat)
////    LookData *costume2 = [self createCostumeFromPath:@"normalcat.png" withName:@"Normal cat"];
////    LookData *costume3 = [self createCostumeFromPath:@"ceshirecat.png" withName:@"Ceshire cat"];
////    
////    //creating cat sprite
////    Sprite *sprite2 = [self createSprite:@"Catroid" withPositionX:100 withPositionY:100 
////                            withCostumes:[[NSArray alloc]initWithObjects:look2, look3, nil] setCostumeIndex:0];
////    
////    //creating cat script
////    Script *newStartScript = [[Script alloc]init];
////    
////    //creating cat brick
////    newBrick = [[SetLookBrick alloc]init];
////    newBrick.look = look1; // TODO: define init-costume...
////    
//////    newBrick.sprite = sprite2;
//////    newStartScript.bricksArray = [[NSMutableArray alloc]initWithObjects:newBrick, nil];
////    [newStartScript addBrick:newBrick];
////    
////    //creating new when script for cat (change look on click and change position)
////    Script *newWhenScript = [[Script alloc]init];
////    newWhenScript.action = 0;
////    newBrick = [[SetLookBrick alloc]init];
////    newBrick.look = look2;
////    
//////    newBrick.sprite = sprite2;
////    Brick *placeAtBrick = [[PlaceAtBrick alloc]initWithXPosition:[NSNumber numberWithInt:50] yPosition:[NSNumber numberWithInt:50]];
//////    placeAtBrick.sprite = sprite2;
////    Brick *glideToBrick = [[GlideToBrick alloc]initWithXPosition:[NSNumber numberWithInt:100]
////                                                       yPosition:[NSNumber numberWithInt:100]
////                                          andDurationInMilliSecs:[NSNumber numberWithInt:1000]];
//////    glideToBrick.sprite = sprite2;
////    NSMutableArray *tmpMutableArray = [[NSMutableArray alloc]init];
////    [tmpMutableArray addObject:newBrick];
////    [tmpMutableArray addObject:placeAtBrick];
////    [tmpMutableArray addObject:glideToBrick];
//////    newWhenScript.bricksArray = [NSArray arrayWithArray:tmpMutableArray];    
////    [newWhenScript addBricks:[NSArray arrayWithArray:tmpMutableArray]];
////    
////    
////    //adding scripts to script arrays
////    //[startScriptsMutable addObject:newStartScript];
////    //[whenScriptsMutable addObject:newWhenScript];
////
//////    [sprite2.startScriptsArray addObject:newStartScript];
//////    [sprite2.whenScriptsArray addObject:newWhenScript];
////    [sprite2 addStartScript:newStartScript];
////    [sprite2 addWhenScript:newWhenScript];
////    
////    //adding sprites to level
////    project.spriteList = [[NSMutableArray alloc] initWithObjects: sprite1, sprite2, nil];
////
////    //assuming start and when scripts
//////    project.startScriptsArray = [[NSArray alloc] initWithArray:startScriptsMutable];
//////    project.whenScriptsArray = [[NSArray alloc] initWithArray:whenScriptsMutable];
////    
////    return level;
////}

#pragma mark - private methods
- (Look*)createCostumeFromPath:(NSString*)path withName:(NSString*)name
{
    Look *retCostume = [[Look alloc] initWithName:name andPath:path];
    
    return retCostume;
}

- (Program*)createDefaultLevel
{
    Program *project = [[Program alloc]init];
    project.header.programName = @"Catty1";
    //project.version = 1.1;
    project.header.screenHeight = [NSNumber numberWithInt:0];
    project.header.screenWidth  = [NSNumber numberWithInt:0];
    
    return project;
}

- (SpriteObject*)createSprite:(NSString*)name
          withPositionX:(NSInteger)x 
          withPositionY:(NSInteger)y 
           withCostumes:(NSArray*)costumesArray 
        setCostumeIndex:(NSInteger)index;

{
    SpriteObject *ret = [[SpriteObject alloc]init];
    ret.name = name;
    ret.position = CGPointMake(x, y);
    //[ret placeAt:GLKVector3Make(x, y, self.zIndex++)];
    ret.lookList = costumesArray;
    //[ret addCostumes:costumesArray];
    //[ret changeCostume:[NSNumber numberWithInt:index]];
    
    return ret;
}


// just4debugging
-(Program*)generateDebugProject_GlideTo
{
    Program *project = [[Program alloc]init];
    project.header = [[Header alloc] init];
    project.header.programName  = @"TestParser";
    project.header.screenWidth  = [NSNumber numberWithInt:320];
    project.header.screenHeight = [NSNumber numberWithInt:480];
    
    
    Look *look= [self createCostumeFromPath:@"normalcat.png" withName:@"cat1"];
    
    Setlookbrick *setLookBrick = [[Setlookbrick alloc]init];
    setLookBrick.look = look;
    Glidetobrick *glideBrick1 = [[Glidetobrick alloc]initWithXPosition:[NSNumber numberWithInt:100]
                                                             yPosition:[NSNumber numberWithInt:100]
                                                andDurationInMilliSecs:[NSNumber numberWithInt:3]];
                                 
    Glidetobrick *glideBrick2 =[[Glidetobrick alloc]initWithXPosition:[NSNumber numberWithInt:100]
                                                            yPosition:[NSNumber numberWithInt:-50]
                                               andDurationInMilliSecs:[NSNumber numberWithInt:1]];
                                 
    Waitbrick *waitBrick = [[Waitbrick alloc]init];
    waitBrick.timeToWaitInSeconds = [NSNumber numberWithInt:3];
    Placeatbrick *placeAtBrick = [[Placeatbrick alloc]init];
    
    Startscript *startScript = [[Startscript alloc]init];
    startScript.brickList = [NSArray arrayWithObject:setLookBrick];
    //[startScript addBrick:setLookBrick];
    
    Whenscript *whenScript = [[Whenscript alloc]init];
    whenScript.brickList = [NSArray arrayWithArray:[NSMutableArray arrayWithObjects:glideBrick1, glideBrick2, waitBrick, placeAtBrick, nil]];
    //[whenScript addBricks:[NSMutableArray arrayWithObjects:glideBrick1, glideBrick2, waitBrick, placeAtBrick, nil]];

    
    NSArray *looks = [NSArray arrayWithObject:look];
    
    SpriteObject *sprite = [self createSprite:@"cat" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    sprite.projectPath = [documentsDirectory stringByAppendingString:@"/levels/TestParser/"];
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    [temp addObject:startScript];
    [temp addObject:whenScript];
    sprite.scriptList = temp;
    
    //[sprite addScript:whenScript];
    //[sprite addScript:startScript];
    project.objectList = [NSMutableArray arrayWithObject:sprite];
    
    [self linkSpriteToScripts:project];
    return project;
}

-(Program*)generateDebugProject_nextCostume
{
    Program*project = [[Program alloc]init];
    project.header = [[Header alloc] init];
    project.header.programName = @"nextCostumeTest";
    project.header.screenWidth  = [NSNumber numberWithInt:320];
    project.header.screenHeight = [NSNumber numberWithInt:480];
    
    
    Look *look1= [self createCostumeFromPath:@"normalcat.png" withName:@"cat1"];
    Look *look2 = [self createCostumeFromPath:@"cheshirecat.png" withName:@"cat2"];
    
    Nextlookbrick *nextCostumeBrick1 = [[Nextlookbrick alloc]init];
    Nextlookbrick *nextCostumeBrick2 = [[Nextlookbrick alloc]init];
    
    Waitbrick *waitBrick = [[Waitbrick alloc]init];
    waitBrick.timeToWaitInSeconds = [NSNumber numberWithInt:1];
    
    Whenscript *whenScript = [[Whenscript alloc]init];
    whenScript.brickList= [NSArray arrayWithObjects:nextCostumeBrick1, waitBrick, nextCostumeBrick2, nil];
    
    Startscript *startScript = [[Startscript alloc]init];
    Setlookbrick *setLookBrick = [[Setlookbrick alloc]init];
    setLookBrick.look = look1;
    startScript.brickList = [NSArray arrayWithObjects:setLookBrick, nil];

    
    NSArray *looks = [NSArray arrayWithObjects:look1, look2, nil];
    
    
    SpriteObject *sprite = [self createSprite:@"cat" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    sprite.projectPath = [documentsDirectory stringByAppendingString:@"/levels/TestParser/"];
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    [temp addObject:startScript];
    [temp addObject:whenScript];
    sprite.scriptList = temp;
    
    //[sprite addScript:whenScript];
    //[sprite addScript:startScript];
    project.objectList = [NSMutableArray arrayWithObject:sprite];
    
    [self linkSpriteToScripts:project];
    
    return project;
    
}

-(Program*)generateDebugProject_HideShow
{
    Program *project = [[Program alloc]init];
    project.header = [[Header alloc] init];
    project.header.programName = @"hide'n'show";
    project.header.screenWidth  = [NSNumber numberWithInt:320];
    project.header.screenHeight = [NSNumber numberWithInt:480];
    
    Look *look= [self createCostumeFromPath:@"normalcat.png" withName:@"cat1"];
    
    Setlookbrick *setLookBrick = [[Setlookbrick alloc]init];
    setLookBrick.look = look;
    Startscript *startScript = [[Startscript alloc]init];
    startScript.brickList =[NSArray arrayWithObjects:setLookBrick, nil];
    
    Hidebrick *hideBrick = [[Hidebrick alloc]init];
    Showbrick *showBrick = [[Showbrick alloc]init];
    
    
    Waitbrick *waitBrick = [[Waitbrick alloc]init];
    waitBrick.timeToWaitInSeconds = [NSNumber numberWithInt:1];
    
    
    Whenscript *whenScript = [[Whenscript alloc]init];
    whenScript.brickList = [NSArray arrayWithObjects:hideBrick, waitBrick, showBrick, nil];
    
    
    NSArray *looks = [NSArray arrayWithObjects:look, nil];
    
    SpriteObject *sprite = [self createSprite:@"cat" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    sprite.projectPath = [documentsDirectory stringByAppendingString:@"/levels/TestParser/"];
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    [temp addObject:startScript];
    [temp addObject:whenScript];
    sprite.scriptList = temp;
    
    project.objectList = [NSMutableArray arrayWithObject:sprite];
    
    [self linkSpriteToScripts:project];
    return project;
}
//
//-(Project *)generateDebugProject_SetXY
//{
//    Project *project = [[Project alloc]init];
//    project.programName = @"setX setY";
//    project.screenWidth  = [NSNumber numberWithInt:320];
//    project.screenHeight = [NSNumber numberWithInt:480];
//    
//        
//    LookData *look = [self createCostumeFromPath:@"normalcat.png" withName:@"cat1"];
//    
//    SetXBrick *setXBrick1 = [[SetXBrick alloc]initWithXPosition:-50];
//    SetYBrick *setYBrick1 = [[SetYBrick alloc]initWithYPosition:-100];
//    
//    SetXBrick *setXBrick2 = [[SetXBrick alloc]initWithXPosition:0];
//    SetYBrick *setYBrick2 = [[SetYBrick alloc]initWithYPosition:0];
//    
//    WaitBrick *waitBrick = [[WaitBrick alloc]init];
//    waitBrick.timeToWaitInMilliSeconds = [NSNumber numberWithInt:1000];
//    
//    
//    WhenScript *whenScript = [[WhenScript alloc]init];
//    [whenScript addBricks:[NSMutableArray arrayWithObjects: setXBrick1, waitBrick, setYBrick1, waitBrick, setXBrick2, setYBrick2, nil]];
//    
//    
//    NSArray *looks = [NSArray arrayWithObjects:look, nil];
//    
//    Sprite *sprite = [self createSprite:@"cat" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite addWhenScript:whenScript];
//    
//    project.spritesArray = [NSMutableArray arrayWithObject:sprite];
//    
//        [self linkSpriteToScripts:project];
    //    return project;
//
//}
//
//-(Project *)generateDebugProject_broadcast
//{
//    Project *project = [[Project alloc]init];
//    project.programName = @"broadcast";
//    project.screenWidth  = [NSNumber numberWithInt:320];
//    project.screenHeight = [NSNumber numberWithInt:480];
//    
//    SetLookBrick *setLookBrick = [[SetLookBrick alloc]init];
//    setLookBrick.indexOfCostumeInArray = 0;
//    StartScript *startScript = [[StartScript alloc]init];
//    [startScript addBrick:setLookBrick];
//    
//    NSString *broadcastMessage = @"BROADCAST";
//    
//    //sprite1
//    
//    LookData *look = [self createCostumeFromPath:@"normalcat.png" withName:@"cat1"];
//    
//    BroadcastBrick *broadcastBrick = [[BroadcastBrick alloc]initWithMessage:broadcastMessage];
//    
//    WhenScript *whenScript = [[WhenScript alloc]init];
//    [whenScript addBricks:[NSMutableArray arrayWithObjects: broadcastBrick, nil]];
//    
//    NSArray *looks = [NSArray arrayWithObjects:look, nil];
//    
//    Sprite *sprite1 = [self createSprite:@"cat1" withPositionX:(NSInteger)-70 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite1 addStartScript:startScript];
//    [sprite1 addWhenScript:whenScript];
//    
//    
//    //sprite2
//    
//    HideBrick *hideBrick1 = [[HideBrick alloc]init];
//    WaitBrick *waitBrick1 = [[WaitBrick alloc]init];
//    waitBrick1.timeToWaitInMilliSeconds = [NSNumber numberWithInt:500];
//    ShowBrick *showBrick1 = [[ShowBrick alloc]init];
//    
//    Script *broadcastScript1 = [[Script alloc]init];
//    [broadcastScript1 addBricks:[NSArray arrayWithObjects:hideBrick1, waitBrick1, showBrick1, nil]];
//    
//    Sprite *sprite2 = [self createSprite:@"cat2" withPositionX:(NSInteger)70 withPositionY:(NSInteger)-100 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite2 addStartScript:startScript];
//    [sprite2 addBroadcastScript:broadcastScript1 forMessage:broadcastMessage];
//    
//    
//    //sprite3
//    HideBrick *hideBrick2 = [[HideBrick alloc]init];
//    WaitBrick *waitBrick2 = [[WaitBrick alloc]init];
//    waitBrick2.timeToWaitInMilliSeconds = [NSNumber numberWithInt:500];
//    ShowBrick *showBrick2 = [[ShowBrick alloc]init];
//
//    Script *broadcastScript2 = [[Script alloc]init];
//    [broadcastScript2 addBricks:[NSArray arrayWithObjects:hideBrick2, waitBrick2, showBrick2, nil]];
//    
//    Sprite *sprite3 = [self createSprite:@"cat3" withPositionX:(NSInteger)70 withPositionY:(NSInteger)100 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite3 addStartScript:startScript];
//    [sprite3 addBroadcastScript:broadcastScript2 forMessage:broadcastMessage];
//
//
//    ///
//    
//    project.spritesArray = [NSMutableArray arrayWithObjects:sprite1, sprite2, sprite3, nil];
//    
//        [self linkSpriteToScripts:project];
    //    return project;
//    
//}
//
//-(Project *)generateDebugProject_broadcastWait
//{
//    Project *project = [[Project alloc]init];
//    project.programName = @"broadcastWait";
//    project.screenWidth  = [NSNumber numberWithInt:320];
//    project.screenHeight = [NSNumber numberWithInt:480];
//    
//    SetLookBrick *setLookBrick = [[SetLookBrick alloc]init];
//    setLookBrick.indexOfCostumeInArray = 0;
//    StartScript *startScript = [[StartScript alloc]init];
//    [startScript addBrick:setLookBrick];
//    
//    NSString *broadcastMessage = @"BROADCAST";
//    
//    //sprite1
//    
//    LookData *look1 = [self createCostumeFromPath:@"normalcat.png" withName:@"cat1"];
//    LookData *look2 = [self createCostumeFromPath:@"cheshirecat.png" withName:@"cat2"];
//
//    
//    BroadcastWaitBrick *broadcastWaitBrick = [[BroadcastWaitBrick alloc]initWithMessage:broadcastMessage];
//    NextCostumeBrick   *nextCostumeBrick   = [[NextCostumeBrick   alloc]init];
//
//    WhenScript *whenScript = [[WhenScript alloc]init];
//    [whenScript addBricks:[NSMutableArray arrayWithObjects: broadcastWaitBrick, nextCostumeBrick, nil]];
//    
//    NSArray *looks = [NSArray arrayWithObjects:look1, look2, nil];
//    
//    Sprite *sprite1 = [self createSprite:@"cat1" withPositionX:(NSInteger)-70 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite1 addStartScript:startScript];
//    [sprite1 addWhenScript:whenScript];
//    
//    
//    //sprite2
//    
//    HideBrick *hideBrick = [[HideBrick alloc]init];
//    WaitBrick *waitBrick = [[WaitBrick alloc]init];
//    waitBrick.timeToWaitInMilliSeconds = [NSNumber numberWithInt:500];
//    ShowBrick *showBrick = [[ShowBrick alloc]init];
//    
//    Script *broadcastScript1 = [[Script alloc]init];
//    [broadcastScript1 addBricks:[NSArray arrayWithObjects:hideBrick, waitBrick, showBrick, nil]];
//    
//    Sprite *sprite2 = [self createSprite:@"cat2" withPositionX:(NSInteger)70 withPositionY:(NSInteger)-100 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite2 addStartScript:startScript];
//    [sprite2 addBroadcastScript:broadcastScript1 forMessage:broadcastMessage];
//    
//    
//    //sprite3
////    HideBrick *hideBrick2 = [[HideBrick alloc]init];
////    WaitBrick *waitBrick2 = [[WaitBrick alloc]init];
////    waitBrick2.timeToWaitInMilliSeconds = [NSNumber numberWithInt:500];
////    ShowBrick *showBrick2 = [[ShowBrick alloc]init];
////    
////    Script *broadcastScript2 = [[Script alloc]init];
////    [broadcastScript2 addBricks:[NSArray arrayWithObjects:hideBrick2, waitBrick2, showBrick2, nil]];
////    
////    Sprite *sprite3 = [self createSprite:@"cat3" withPositionX:(NSInteger)70 withPositionY:(NSInteger)100 withCostumes:looks setCostumeIndex:(NSInteger)0];
////    [sprite3 addBroadcastScript:broadcastScript2 forMessage:broadcastMessage];
//    
//    
//    ///
//    
//    project.spritesArray = [NSMutableArray arrayWithObjects:sprite1, sprite2, nil];
//    
//        [self linkSpriteToScripts:project];
    //    return project;
//    
//}
//
//
//-(Project *)generateDebugProject_comeToFront
//{
//    Project *project = [[Project alloc]init];
//    project.programName = @"broadcast";
//    project.screenWidth  = [NSNumber numberWithInt:320];
//    project.screenHeight = [NSNumber numberWithInt:480];
//        
//    //sprite1
//    LookData *look= [self createCostumeFromPath:@"normalcat.png" withName:@"cat1"];
//    ComeToFrontBrick *comeToFrontBrick = [[ComeToFrontBrick alloc]init];
//    
//    WhenScript *whenScript = [[WhenScript alloc]init];
//    [whenScript addBricks:[NSMutableArray arrayWithObjects: comeToFrontBrick, nil]];
//    
//    NSArray *looks = [NSArray arrayWithObjects:look, nil];
//    
//    Sprite *sprite1 = [self createSprite:@"cat1" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite1 addWhenScript:whenScript];
//    
//    //sprite2
//    Sprite *sprite2 = [self createSprite:@"cat2" withPositionX:(NSInteger)50 withPositionY:(NSInteger)50 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite2 addWhenScript:whenScript];
//    
//    //sprite3
//    Sprite *sprite3 = [self createSprite:@"cat3" withPositionX:(NSInteger)-50 withPositionY:(NSInteger)-50 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite3 addWhenScript:whenScript];
//        
//    
//    ///
//    
//    project.spritesArray = [NSMutableArray arrayWithObjects:sprite3, sprite2, sprite1, nil];
//    
//        [self linkSpriteToScripts:project];
    //    return project;
//}
//
//-(Project*)generateDebugProject_changeSizeByN
//{
//    Project *project = [[Project alloc]init];
//    project.programName = @"changeSizeByN";
//    project.screenWidth  = [NSNumber numberWithInt:320];
//    project.screenHeight = [NSNumber numberWithInt:480];
//    
//    LookData *look= [self createCostumeFromPath:@"normalcat.png" withName:@"cat1"];
//    
//    ChangeSizeByNBrick *changeSizeByNBrick1 = [[ChangeSizeByNBrick alloc]initWithSizeChangeRate:50];
//    ChangeSizeByNBrick *changeSizeByNBrick2 = [[ChangeSizeByNBrick alloc]initWithSizeChangeRate:-100];
//    ChangeSizeByNBrick *changeSizeByNBrick3 = [[ChangeSizeByNBrick alloc]initWithSizeChangeRate:50];
//    
//    WaitBrick *waitBrick = [[WaitBrick alloc]init];
//    waitBrick.timeToWaitInMilliSeconds = [NSNumber numberWithInt:500];
//    
//    WhenScript *whenScript = [[WhenScript alloc]init];
//    [whenScript addBricks:[NSMutableArray arrayWithObjects: changeSizeByNBrick1, waitBrick, changeSizeByNBrick2, waitBrick, changeSizeByNBrick3, nil]];
//    
//    
//    NSArray *looks = [NSArray arrayWithObjects:look, nil];
//    
//    Sprite *sprite = [self createSprite:@"cat" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite addWhenScript:whenScript];
//    
//    project.spritesArray = [NSMutableArray arrayWithObject:sprite];
//    
//        [self linkSpriteToScripts:project];
    //    return project;
//    
//}
//
//-(Project *)generateDebugProject_parallelScripts
//{
//    Project *project = [[Project alloc]init];
//    project.programName = @"parallelScripts";
//    project.screenWidth  = [NSNumber numberWithInt:320];
//    project.screenHeight = [NSNumber numberWithInt:480];
//    
//    LookData *look= [self createCostumeFromPath:@"normalcat.png" withName:@"cat1"];
//    
//    StartScript *startScript = [[StartScript alloc]init];
//    PlaceAtBrick *placeAtBrick = [[PlaceAtBrick alloc]initWithPosition:GLKVector3Make(-100, 100, 0)];
//    GlideToBrick *glideToBrick = [[GlideToBrick alloc]initWithPosition:GLKVector3Make(100, 100, 0) andDurationInMilliSecs:5000];
//    [startScript addBrick:placeAtBrick];
//    [startScript addBrick:glideToBrick];
//    
//    
//    WhenScript *whenScript = [[WhenScript alloc]init];
//    GlideToBrick *glideToBrick2 = [[GlideToBrick alloc]initWithPosition:GLKVector3Make(-100, -100, 0) andDurationInMilliSecs:5000];
//    [whenScript addBrick:glideToBrick2];
//    
//    NSArray *looks = [NSArray arrayWithObjects:look, nil];
//    
//    Sprite *sprite = [self createSprite:@"cat" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite addWhenScript:whenScript];
//    [sprite addStartScript:startScript];
//    
//    project.spritesArray = [NSMutableArray arrayWithObject:sprite];
//    
//        [self linkSpriteToScripts:project];
    //    return project;
//}
//
//-(Project *)generateDebugProject_loops
//{
//    Project *project = [[Project alloc]init];
//    project.programName = @"loops";
//    project.screenWidth  = [NSNumber numberWithInt:320];
//    project.screenHeight = [NSNumber numberWithInt:480];
//    
//    LookData *costume1 = [self createCostumeFromPath:@"normalcat.png" withName:@"cat1"];
//    LookData *costume2 = [self createCostumeFromPath:@"cheshirecat.png" withName:@"cat2"];
//    
//    StartScript *startScript = [[StartScript alloc]init];
//    RepeatBrick *loopStart = [[RepeatBrick alloc]initWithNumberOfLoops:5];
//    NextCostumeBrick *nextCostumeBrick = [[NextCostumeBrick alloc]init];
//    WaitBrick *waitBrick = [[WaitBrick alloc]init];
//    waitBrick.timeToWaitInMilliSeconds = [NSNumber numberWithInt:500];
//    EndLoopBrick *loopEnd = [[EndLoopBrick alloc]init];
//    [startScript addBrick:loopStart];
//    [startScript addBrick:nextCostumeBrick];
//    [startScript addBrick:waitBrick];
//    [startScript addBrick:loopEnd];
//    
//    
//    
//    WhenScript *whenScript = [[WhenScript alloc]init];
//    GlideToBrick *glideToBrick2 = [[GlideToBrick alloc]initWithPosition:GLKVector3Make(-100, -100, 0) andDurationInMilliSecs:5000];
//    [whenScript addBrick:glideToBrick2];
//    
//    NSArray *looks = [NSArray arrayWithObjects:look1, look2, nil];
//    
//    Sprite *sprite = [self createSprite:@"cat" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite addWhenScript:whenScript];
//    [sprite addStartScript:startScript];
//    
//    project.spritesArray = [NSMutableArray arrayWithObject:sprite];
//    
//        [self linkSpriteToScripts:project];
    //    return project;
//}
//
-(Program*)generateDebugProject_rotate
{
    Program *project = [[Program alloc]init];
    project.header = [[Header alloc] init];
    project.header.programName = @"rotate";
    project.header.screenWidth  = [NSNumber numberWithInt:320];
    project.header.screenHeight = [NSNumber numberWithInt:480];
    
    Look *look= [self createCostumeFromPath:@"cheshirecat.png" withName:@"cat1"];
    Setlookbrick *setLook = [[Setlookbrick alloc]init];
    setLook.look = look;
    Placeatbrick   *placeAt   = [[Placeatbrick   alloc]initWithXPosition:[NSNumber numberWithFloat:-80.0f] yPosition:[NSNumber numberWithFloat: -120.0f]];
    Turnleftbrick  *turnLeft1 = [[Turnleftbrick  alloc]initWithDegrees:[NSNumber numberWithInt:45]];
    Turnrightbrick *turnRight = [[Turnrightbrick alloc]initWithDegrees:[NSNumber numberWithInt:90]];
    Turnleftbrick  *turnLeft2 = [[Turnleftbrick  alloc]initWithDegrees:[NSNumber numberWithInt:45]];
    
    Waitbrick *waitBrick1 = [[Waitbrick alloc]init];
    waitBrick1.timeToWaitInSeconds = [NSNumber numberWithInt:1];
    Waitbrick *waitBrick2 = [[Waitbrick alloc]init];
    waitBrick2.timeToWaitInSeconds = [NSNumber numberWithInt:1];
    
    Whenscript *whenScript = [[Whenscript alloc]init];
    whenScript.brickList = [NSArray arrayWithObjects:turnLeft1, waitBrick1, turnRight, waitBrick2, turnLeft2, nil];
    
    Startscript *startScript = [[Startscript alloc]init];
    startScript.brickList = [NSArray arrayWithObjects:setLook, placeAt, nil];
    
    NSArray *looks = [NSArray arrayWithObjects:look, nil];
    
    SpriteObject *sprite = [self createSprite:@"cat" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    sprite.projectPath = [documentsDirectory stringByAppendingString:@"/levels/TestParser/"];
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    [temp addObject:startScript];
    [temp addObject:whenScript];
    sprite.scriptList = temp;
    
    project.objectList = [NSMutableArray arrayWithObject:sprite];
    
    [self linkSpriteToScripts:project];
    return project;

    
}

-(Program*)generateDebugProject_rotateFullCircle
{
    Program *project = [[Program alloc]init];
    project.header = [[Header alloc] init];
    project.header.programName = @"rotate";
    project.header.screenWidth  = [NSNumber numberWithInt:320];
    project.header.screenHeight = [NSNumber numberWithInt:480];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    Waitbrick *waitBrick = [[Waitbrick alloc]init];
    waitBrick.timeToWaitInSeconds = [NSNumber numberWithInt:0.1];
    
    Turnrightbrick  *turnRight = [[Turnrightbrick  alloc]initWithDegrees:[NSNumber numberWithInt:10]];


    
    Look *look= [self createCostumeFromPath:@"cheshirecat.png" withName:@"cat1"];
    Setlookbrick *setLook = [[Setlookbrick alloc]init];
    setLook.look = look;
    
    NSArray *looks = [NSArray arrayWithObjects:look, nil];
    

    
    // sprite 1
    Placeatbrick   *placeAt1 = [[Placeatbrick   alloc]initWithXPosition:[NSNumber numberWithFloat:80.0f] yPosition:[NSNumber numberWithFloat: 120.0f]];
    Turnleftbrick  *turnLeft = [[Turnleftbrick  alloc]initWithDegrees:[NSNumber numberWithInt:10]];

    NSMutableArray *bricks1 = [NSMutableArray arrayWithCapacity:73];
    [bricks1 addObject:setLook];
    for (int i=0; i<36; i++) {
        [bricks1 addObject:turnLeft];
        [bricks1 addObject:waitBrick];
    }
    
    Whenscript *whenScript1 = [[Whenscript alloc]init];
    whenScript1.brickList = bricks1;
 

    Startscript *startScript1 = [[Startscript alloc]init];
    startScript1.brickList = [NSArray arrayWithObjects:setLook, placeAt1, nil];
    
    SpriteObject *sprite1 = [self createSprite:@"cat1" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
    sprite1.projectPath = [documentsDirectory stringByAppendingString:@"/levels/TestParser/"];
    sprite1.scriptList = [NSArray arrayWithObjects:startScript1, whenScript1, nil];
//
    
    
    // sprite 2
    
    Look *look2= [self createCostumeFromPath:@"cheshirecat.png" withName:@"cat2"];
    Setlookbrick *setLook2 = [[Setlookbrick alloc]init];
    setLook2.look = look2;
    NSArray *looks2 = [NSArray arrayWithObjects:look2, nil];
    
    Placeatbrick   *placeAt2 = [[Placeatbrick   alloc]initWithXPosition:[NSNumber numberWithFloat:-80.0f] yPosition:[NSNumber numberWithFloat: -120.0f]];
    
    NSMutableArray *bricks2 = [NSMutableArray arrayWithCapacity:73];
    [bricks2 addObject:setLook2];
    for (int i=0; i<36; i++) {
        [bricks2 addObject:turnRight];
        [bricks2 addObject:waitBrick];
    }
    
    Whenscript *whenScript2 = [[Whenscript alloc]init];
    whenScript2.brickList = bricks2;
    
    Startscript *startScript2 = [[Startscript alloc]init];
    startScript2.brickList = [NSArray arrayWithObjects:setLook2, placeAt2, nil];
    
    SpriteObject *sprite2 = [self createSprite:@"cat2" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks2 setCostumeIndex:(NSInteger)0];
    sprite2.projectPath = [documentsDirectory stringByAppendingString:@"/levels/TestParser/"];
    sprite2.scriptList = [NSArray arrayWithObjects:startScript2, whenScript2, nil];

    project.objectList = [NSMutableArray arrayWithObjects:sprite1, sprite2, nil];
    
    [self linkSpriteToScripts:project];
    return project;
    
}
//
//-(Project*)generateDebugProject_rotateAndMove
//{
//    Project *project = [[Project alloc]init];
//    project.programName = @"rotate";
//    project.screenWidth  = [NSNumber numberWithInt:320];
//    project.screenHeight = [NSNumber numberWithInt:480];
//    
//    SetLookBrick *setLook = [[SetLookBrick alloc]init];
//    setLook.indexOfCostumeInArray = 0;
//    
//    LookData *look= [self createCostumeFromPath:@"cheshirecat.png" withName:@"cat1"];
//    NSArray *looks = [NSArray arrayWithObjects:look, nil];
//    
//    WaitBrick *waitBrick = [[WaitBrick alloc]init];
//    waitBrick.timeToWaitInMilliSeconds = [NSNumber numberWithInt:50];
//    
//    
//    LoopBrick *loopBrick = [[LoopBrick alloc]init];
//    EndLoopBrick *endLoopBrick = [[EndLoopBrick alloc]init];
//    
//    
//    
//    TurnLeftBrick  *turnLeft = [[TurnLeftBrick  alloc]initWithDegrees:10];
//    
//    NSMutableArray *bricks = [NSMutableArray arrayWithCapacity:75];
//    [bricks addObject:setLook];
//    [bricks addObject:loopBrick];
//    for (int i=0; i<36; i++) {
//        [bricks addObject:turnLeft];
//        [bricks addObject:waitBrick];
//    }
//    [bricks addObject:endLoopBrick];
//    
//    
//    WhenScript *whenScript = [[WhenScript alloc]init];
//    [whenScript addBrick:[[GlideToBrick alloc]initWithPosition:GLKVector3Make( 100.0f,    0.0f, 0.0f) andDurationInMilliSecs:500/2]];
//    [whenScript addBrick:[[GlideToBrick alloc]initWithPosition:GLKVector3Make( 100.0f, -100.0f, 0.0f) andDurationInMilliSecs:500/2]];
//    [whenScript addBrick:[[GlideToBrick alloc]initWithPosition:GLKVector3Make(-100.0f, -100.0f, 0.0f) andDurationInMilliSecs:500]];
//    [whenScript addBrick:[[GlideToBrick alloc]initWithPosition:GLKVector3Make(-100.0f,  100.0f, 0.0f) andDurationInMilliSecs:500]];
//    [whenScript addBrick:[[GlideToBrick alloc]initWithPosition:GLKVector3Make( 100.0f,  100.0f, 0.0f) andDurationInMilliSecs:500]];
//    [whenScript addBrick:[[GlideToBrick alloc]initWithPosition:GLKVector3Make( 100.0f,    0.0f, 0.0f) andDurationInMilliSecs:500/2]];
//    [whenScript addBrick:[[GlideToBrick alloc]initWithPosition:GLKVector3Make(   0.0f,    0.0f, 0.0f) andDurationInMilliSecs:500/2]];
//    
//    StartScript *startScript = [[StartScript alloc]init];
//    [startScript addBricks:[NSArray arrayWithArray:bricks]];
//    
//    Sprite *sprite = [self createSprite:@"cat" withPositionX:(NSInteger)0 withPositionY:(NSInteger)0 withCostumes:looks setCostumeIndex:(NSInteger)0];
//    [sprite addWhenScript:whenScript];
//    [sprite addStartScript:startScript];
//    
//    
//    
//    ////
//    project.spritesArray = [NSMutableArray arrayWithObjects:sprite, nil];
//    
//        [self linkSpriteToScripts:project];
    //    return project;
//    
//}


-(void)linkSpriteToScripts:(Program*)project
{
    for (SpriteObject *sprite in project.objectList) {
        for (Script *script in sprite.scriptList) {
            for (Brick *brick in script.brickList) {
                brick.object = sprite;
            }
        }
    }
}

@end
