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
            [self.newSprite.costumesArray addObject:costume];
        }
        
        //retrieving all sounds
        NSArray *soundList = [gDataSprite elementsForName:@"soundList"];
        //todo... use sound...
        //for each..
        //add sound to sprite
        
        //retrieving all scripts
        NSArray *scriptList = [gDataSprite elementsForName:@"scriptList"];
        
        //getting all start scripts
        NSArray *scripts = [[scriptList objectAtIndex:0] elementsForName:@"Content.StartScript"];
        for (GDataXMLElement *gDataScript in scripts)
        {
            Script *newScript = [self loadScript:gDataScript];
            [self.newSprite addStartScript:newScript];
        }
        
        //getting all when scripts
        scripts = [[scriptList objectAtIndex:0] elementsForName:@"Content.WhenScript"];
        for (GDataXMLElement *gDataScript in scripts)
        {
            Script *newScript = [self loadScript:gDataScript];
            [self.newSprite addWhenScript:newScript];
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
    
    NSArray *costumeFileNames = [gDataCostume elementsForName:@"costumeFileName"];
    GDataXMLElement *temp = (GDataXMLElement*)[costumeFileNames objectAtIndex:0];
    ret.costumeFileName = temp.stringValue;
    
    NSArray *costumeNames = [gDataCostume elementsForName:@"costumeName"];
    temp = (GDataXMLElement*)[costumeNames objectAtIndex:0];
    ret.costumeName = temp.stringValue;
    
    return ret;
}

- (Script*)loadScript:(GDataXMLElement*)gDataScript
{
    Script *ret = [[Script alloc] init];
    
    NSArray *brickList = [gDataScript elementsForName:@"brickList"];
    
    //retrieving setCostumeBricks
    NSArray *setCostumeBricks = [[brickList objectAtIndex:0] elementsForName:@"Bricks.SetCostumeBrick"];
    for (GDataXMLElement *gDataSetCostumeBrick in setCostumeBricks)
    {
        SetCostumeBrick *brick = [self loadSetCostumeBrick:gDataSetCostumeBrick];
        brick.sprite = self.newSprite;
        [ret.bricksArray addObject:brick];
    }
    
    //retrieving waitBricks
    NSArray *waitBricks = [[brickList objectAtIndex:0] elementsForName:@"Bricks.WaitBrick"];
    for (GDataXMLElement *gDataWaitBrick in waitBricks)
    {
        WaitBrick *brick = [self loadWaitBrick:gDataWaitBrick];
        brick.sprite = self.newSprite;
        [ret.bricksArray addObject:brick];
    }
    
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
            ret.indexOfCostumeInArray = [NSNumber numberWithInt:indexString.intValue];
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

    ret.timeToWaitInMilliseconds = [NSNumber numberWithInt:temp.stringValue.intValue];
    
    return ret;
}

@end
