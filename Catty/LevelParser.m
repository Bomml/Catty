//
//  LevelParser.m
//  Catty
//
//  Created by Christof Stromberger on 19.07.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "LevelParser.h"
#import "GDataXMLNode.h"
#import "Level.h"
#import "Sprite.h"
#import "Costume.h"
#import "Script.h"
#import "Brick.h"
#import "SetCostumeBrick.h"
#import "WaitBrick.h"
#import "StartScript.h"
#import "WhenScript.h"
#import "Sound.h"
#import "PlaceAtBrick.h"
#import "GlideToBrick.h"
#import "NextCostumeBrick.h"
#import "HideBrick.h"
#import "ShowBrick.h"
#import "SetXBrick.h"
#import "SetYBrick.h"
#import "ChangeSizeByNBrick.h"

@interface LevelParser()

@property (nonatomic, strong, getter=theNewSprite) Sprite *newSprite;

- (Costume*)loadCostume:(GDataXMLElement*)gDataCostume;
- (Script*)loadScript:(GDataXMLElement*)gDataScript;

@end

@implementation LevelParser

@synthesize newSprite = _newSprite;

- (Level*)loadLevel:(NSData*)xmlData
{
    NSError *error;
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData 
                                                           options:0 error:&error];
    if (doc == nil) 
        return nil;
    
    Level *level = [[Level alloc] init];
    NSArray *spriteList = [doc.rootElement elementsForName:@"spriteList"];
    NSArray *sprites = [[spriteList objectAtIndex:0] elementsForName:@"Content.Sprite"];
    for (GDataXMLElement *gDataSprite in sprites) 
    {
        self.newSprite = [[Sprite alloc] init];
        
        //retrieving all costumes
        NSArray *costumeDataList = [gDataSprite elementsForName:@"costumeDataList"];
        NSArray *costumes = [[costumeDataList objectAtIndex:0] elementsForName:@"Common.CostumeData"];
        for (GDataXMLElement *gDataCostume in costumes)
        {
            Costume *costume = [self loadCostume:gDataCostume];
//            [self.newSprite.costumesArray addObject:costume];
            [self.newSprite addCostume:costume];
        }
        
        //retrieving all sounds
        NSArray *soundList = [gDataSprite elementsForName:@"soundList"];
        NSArray *sounds = [[soundList objectAtIndex:0] elementsForName:@"Common.SoundInfo"];
        for (GDataXMLElement *gDataSound in sounds)
        {
            Sound *sound = [self loadSound:gDataSound];
//            [self.newSprite.soundsArray addObject:sound];
            [self.newSprite addSound:sound];
        }
        //todo... use sound...
        //for each..
        //add sound to sprite
        
        //retrieving all scripts
        NSArray *scriptList = [gDataSprite elementsForName:@"scriptList"];
        
        //getting all start scripts
        NSArray *scripts = [[scriptList objectAtIndex:0] elementsForName:@"Content.StartScript"];
        for (GDataXMLElement *gDataScript in scripts)
        {
            Script *newScript = [self loadStartScript:gDataScript];
//            [self.newSprite.startScriptsArray addObject:newScript];
            [self.newSprite addStartScript:newScript];
            //[self.newSprite addStartScript:newScript];
        }
        
        //getting all when scripts
        scripts = [[scriptList objectAtIndex:0] elementsForName:@"Content.WhenScript"];
        for (GDataXMLElement *gDataScript in scripts)
        {
            Script *newScript = [self loadWhenScript:gDataScript];
//            [self.newSprite.whenScriptsArray addObject:newScript];
            [self.newSprite addWhenScript:newScript];
            //[self.newSprite addWhenScript:newScript];
        }
        
        NSArray *spriteNames = [gDataSprite elementsForName:@"name"];
        GDataXMLElement *temp = (GDataXMLElement*)[spriteNames objectAtIndex:0];
        self.newSprite.name = temp.stringValue;
        
        [level.spritesArray addObject:self.newSprite];

    }

    //loading level related stuff
    //version name
    NSArray *versionNames = [doc.rootElement elementsForName:@"versionName"];
    GDataXMLElement *temp = (GDataXMLElement*)[versionNames objectAtIndex:0];
    level.versionName = temp.stringValue;
    
    //name
    NSArray *names = [doc.rootElement elementsForName:@"name"];
    temp = (GDataXMLElement*)[names objectAtIndex:0];
    level.name = temp.stringValue;
    
    //screen resolution
    NSArray *screenResolutions = [doc.rootElement elementsForName:@"screenResolution"];
    temp = (GDataXMLElement*)[screenResolutions objectAtIndex:0];
    level.screenResolution = temp.stringValue;
    
    //version code
    NSArray *versionCodes = [doc.rootElement elementsForName:@"versionCode"];
    temp = (GDataXMLElement*)[versionCodes objectAtIndex:0];
    level.versionCode = temp.stringValue;
    
    return level;
}

- (Costume*)loadCostume:(GDataXMLElement*)gDataCostume
{
    Costume *ret = [[Costume alloc] init];
    
    NSArray *costumeFileNames = [gDataCostume elementsForName:@"costumeFileName"]; //old xml version
    //NSArray *costumeFileNames = [gDataCostume elementsForName:@"fileName"];

    GDataXMLElement *temp = (GDataXMLElement*)[costumeFileNames objectAtIndex:0];
    ret.costumeFileName = temp.stringValue;
    
    NSArray *costumeNames = [gDataCostume elementsForName:@"costumeName"];
    //NSArray *costumeNames = [gDataCostume elementsForName:@"name"];

    temp = (GDataXMLElement*)[costumeNames objectAtIndex:0];
    ret.costumeName = temp.stringValue;
    
    return ret;
}

- (Sound*)loadSound:(GDataXMLElement*)gDataSound //todo
{
//    Sound *ret = [[Sound alloc] init];
//    
//    NSArray *soundInfo = [gDataSound elementsForName:@"Common.SoundInfo"];
//    GDataXMLNode *temp = [(GDataXMLElement*)[soundInfo objectAtIndex:0]attributeForName:@"reference"];
//    NSString *referencePath = temp.stringValue; 
//    ret.
//    
//    return ret;
}

- (Script*)loadStartScript:(GDataXMLElement*)gDataScript
{
    StartScript *ret = [[StartScript alloc] init];
    
    NSArray *brickList = [gDataScript elementsForName:@"brickList"];
    
    //retrieving setCostumeBricks
    NSArray *setCostumeBricks = [[brickList objectAtIndex:0] elementsForName:@"Bricks.SetCostumeBrick"];
    for (GDataXMLElement *gDataSetCostumeBrick in setCostumeBricks)
    {
        SetCostumeBrick *brick = [self loadSetCostumeBrick:gDataSetCostumeBrick];
//        brick.sprite = self.newSprite;
//        [ret.bricksArray addObject:brick];
        [ret addBrick:brick];
    }
    
    //retrieving waitBricks
    NSArray *waitBricks = [[brickList objectAtIndex:0] elementsForName:@"Bricks.WaitBrick"];
    for (GDataXMLElement *gDataWaitBrick in waitBricks)
    {
        WaitBrick *brick = [self loadWaitBrick:gDataWaitBrick];
//        brick.sprite = self.newSprite;
//        [ret.bricksArray addObject:brick];
        [ret addBrick:brick];
    }
    
    return ret;
}

- (Script*)loadWhenScript:(GDataXMLElement*)gDataScript
{
    WhenScript *ret = [[WhenScript alloc] init];
    
    NSArray *brickList = [gDataScript elementsForName:@"brickList"];

    
    NSArray *childs = [[brickList objectAtIndex:0] children];
    
    for (GDataXMLElement *element in childs)
    {
        if ([element.name isEqualToString:@"Bricks.SetCostumeBrick"])
        {
            SetCostumeBrick *brick = [self loadSetCostumeBrick:element];
            [ret addBrick:brick];
        }
        else if ([element.name isEqualToString:@"Bricks.WaitBrick"])
        {
            WaitBrick *brick = [self loadWaitBrick:element];
            [ret addBrick:brick];
        }
        else if ([element.name isEqualToString:@"Bricks.PlaceAtBrick"])
        {
            PlaceAtBrick *brick = [self loadPlaceAtBrick:element];
            [ret addBrick:brick];
        }
        else if ([element.name isEqualToString:@"Bricks.GlideToBrick"])
        {
            GlideToBrick *brick = [self loadGlideToBrick:element];
            [ret addBrick:brick];
        }
        else if ([element.name isEqualToString:@"Bricks.ShowBrick"])
        {
            ShowBrick *brick = [[ShowBrick alloc]init];
            [ret addBrick:brick];
        }
        else if ([element.name isEqualToString:@"Bricks.HideBrick"])
        {
            HideBrick *brick = [[HideBrick alloc]init];
            [ret addBrick:brick];
        }
        else if ([element.name isEqualToString:@"Bricks.NextCostumeBrick"])
        {
            NextCostumeBrick *brick = [[NextCostumeBrick alloc]init];
            [ret addBrick:brick];
        }
        else if ([element.name isEqualToString:@"Bricks.SetXBrick"])
        {
            SetXBrick *brick = [self loadSetXBrick:element];
            [ret addBrick:brick];
        }
        else if ([element.name isEqualToString:@"Bricks.SetYBrick"])
        {
            SetYBrick *brick = [self loadSetYBrick:element];
            [ret addBrick:brick];
        }
        else if ([element.name isEqualToString:@"Bricks.ChangeSizeByNBrick"])
        {
            ChangeSizeByNBrick *brick = [self loadChangeSizeByNBrick:element];
            [ret addBrick:brick];
        }
    }
    
    //retrieving setCostumeBricks
//    NSArray *setCostumeBricks = [[brickList objectAtIndex:0] elementsForName:@"Bricks.SetCostumeBrick"];
//    for (GDataXMLElement *gDataSetCostumeBrick in setCostumeBricks)
//    {
//        SetCostumeBrick *brick = [self loadSetCostumeBrick:gDataSetCostumeBrick];
//        brick.sprite = self.newSprite;
//        [ret.bricksArray addObject:brick];
//    }
//    
//    //retrieving waitBricks
//    NSArray *waitBricks = [[brickList objectAtIndex:0] elementsForName:@"Bricks.WaitBrick"];
//    for (GDataXMLElement *gDataWaitBrick in waitBricks)
//    {
//        WaitBrick *brick = [self loadWaitBrick:gDataWaitBrick];
//        brick.sprite = self.newSprite;
//        [ret.bricksArray addObject:brick];
//    }
    
    return ret;
}


//different bricks
//set costume brick
- (SetCostumeBrick*)loadSetCostumeBrick:(GDataXMLElement*)gDataSetCostumeBrick
{
    SetCostumeBrick *ret = [[SetCostumeBrick alloc] init];
    
    NSArray *references = [gDataSetCostumeBrick elementsForName:@"costumeData"];
    GDataXMLNode *temp = [(GDataXMLElement*)[references objectAtIndex:0]attributeForName:@"reference"];
    NSString *referencePath = temp.stringValue;
    
    if ([referencePath length] > 2)
    {
        if([referencePath hasSuffix:@"]"]) //index found
        {
            NSString *indexString = [referencePath substringWithRange:NSMakeRange([referencePath length]-2, 1)];
            ret.indexOfCostumeInArray = [NSNumber numberWithInt:indexString.intValue-1];
        }
        else 
        {
            ret.indexOfCostumeInArray = [NSNumber numberWithInt:0];
        }
    }
    else 
    {
        ret.indexOfCostumeInArray = nil;
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"Parser error! (#1)"]
                                     userInfo:nil];
    }
    
    NSLog(@"Index: %@, Reference: %@", ret.indexOfCostumeInArray, [references objectAtIndex:0]);
    
    return ret;
}

//wait brick
- (WaitBrick*)loadWaitBrick:(GDataXMLElement*)gDataWaitBrick
{
    WaitBrick *ret = [[WaitBrick alloc] init];
    
    NSArray *waitTimes = [gDataWaitBrick elementsForName:@"timeToWaitInMilliSeconds"];
    GDataXMLElement *temp = (GDataXMLElement*)[waitTimes objectAtIndex:0];

    NSLog(@"timeToWait: %@, int: %d", temp.stringValue, temp.stringValue.intValue);
    ret.timeToWaitInMilliseconds = [NSNumber numberWithInt:temp.stringValue.intValue];
    
    return ret;
}

-(PlaceAtBrick*)loadPlaceAtBrick:(GDataXMLElement*)gDataXMLElement
{
    PlaceAtBrick *brick = [[PlaceAtBrick alloc]init];
    
    NSArray *xPositions = [gDataXMLElement elementsForName:@"xPosition"];
    GDataXMLElement *xPosition = (GDataXMLElement*)[xPositions objectAtIndex:0];
    
    NSArray *yPositions = [gDataXMLElement elementsForName:@"yPosition"];
    GDataXMLElement *yPosition = (GDataXMLElement*)[yPositions objectAtIndex:0];
    
    NSLog(@"placeAt: %@/%@", xPosition.stringValue, yPosition.stringValue);
    brick.position = GLKVector3Make(xPosition.stringValue.floatValue, yPosition.stringValue.floatValue, 0);
    
    return brick;
}

-(GlideToBrick*)loadGlideToBrick:(GDataXMLElement*)gDataXMLElement
{    
    GlideToBrick *brick = [[GlideToBrick alloc]init];
    
    NSArray *times = [gDataXMLElement elementsForName:@"durationInMilliSeconds"];
    GDataXMLElement *time = (GDataXMLElement*)[times objectAtIndex:0];
    
    NSArray *xPositions = [gDataXMLElement elementsForName:@"xDestination"];
    GDataXMLElement *xPosition = (GDataXMLElement*)[xPositions objectAtIndex:0];
    
    NSArray *yPositions = [gDataXMLElement elementsForName:@"yDestination"];
    GDataXMLElement *yPosition = (GDataXMLElement*)[yPositions objectAtIndex:0];
    
    NSLog(@"glideTo: %@/%@ in %@ millisecs", xPosition.stringValue, yPosition.stringValue, time.stringValue);
    brick.durationInMilliSecs = time.stringValue.intValue;
    brick.position = GLKVector3Make(xPosition.stringValue.floatValue, yPosition.stringValue.floatValue, 0);
    
    return brick;
}


-(SetXBrick*)loadSetXBrick:(GDataXMLElement*)gDataXMLElement
{
    SetXBrick *brick = [[SetXBrick alloc]init];
    
    NSArray *xPositions = [gDataXMLElement elementsForName:@"xPosition"];
    GDataXMLElement *xPosition = (GDataXMLElement*)[xPositions objectAtIndex:0];
    
    NSLog(@"setX: %@", xPosition.stringValue);
    brick.xPosition = xPosition.stringValue.floatValue;
    
    return brick;
}

-(SetYBrick*)loadSetYBrick:(GDataXMLElement*)gDataXMLElement
{
    SetYBrick *brick = [[SetYBrick alloc]init];
    
    NSArray *yPositions = [gDataXMLElement elementsForName:@"yPosition"];
    GDataXMLElement *yPosition = (GDataXMLElement*)[yPositions objectAtIndex:0];
    
    NSLog(@"setY: %@", yPosition.stringValue);
    brick.yPosition = yPosition.stringValue.floatValue;
    
    return brick;
}

-(ChangeSizeByNBrick*)loadChangeSizeByNBrick:(GDataXMLElement*)gDataXMLElement
{
    ChangeSizeByNBrick *brick = [[ChangeSizeByNBrick alloc]init];
    
    NSArray *sizeChangeRates = [gDataXMLElement elementsForName:@"yPosition"];
    GDataXMLElement *sizeChangeRate = (GDataXMLElement*)[sizeChangeRates objectAtIndex:0];
    
    NSLog(@"change: %@", sizeChangeRate.stringValue);
    brick.sizeInPercentage = sizeChangeRate.stringValue.floatValue;
    
    return brick;
}

@end
