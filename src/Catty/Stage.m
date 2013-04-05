//
//  Game.m
//  AppScaffold
//

#import "Stage.h" 
#import "Program.h"
#import "SPStage.h"
#import "SpriteObject.h"

// --- private interface ---------------------------------------------------------------------------

@interface Stage ()


@property (nonatomic, strong) SPImage *tmpImage;

- (void)setup;
////- (void)onImageTouched:(SPTouchEvent *)event;
////- (void)onResize:(SPResizeEvent *)event;

@end


// --- class implementation ------------------------------------------------------------------------

@implementation Stage
{
    SPSprite *_contents;
}

- (id)init
{
    if ((self = [super init])) {
    }
    return self;
}

- (void)dealloc
{
    // release any resources here
    [Media releaseAtlas];
    [Media releaseSound];
}



-(void)start
{
    [self setup];
    for (SpriteObject *obj in self.program.objectList) {
        [obj start];
        [obj addEventListener:@selector(onImageTouched:) atObject:obj forType:SP_EVENT_TYPE_TOUCH];
        [self addChild:obj];
    }
}


- (void)setup
{

//    SPSprite *blub = [SPSprite sprite];
//
//    SPImage *img = [[SPImage alloc] initWithTexture:[Media atlasTexture:@"sparrow"]];
//    int origWidth = img.width;
//    int origHeight = img.height;
//    
//    img.width = 300;
//    img.height = 300;
//    
////    img.scaleX = img.scaleY = 1.0f;
//    img.x = img.width /2.0f + 400;
//    img.y = img.height/2.0f + 700;
//    img.pivotX = origWidth /2.0f;
//    img.pivotY = origHeight/2.0f;
//
//    img.rotation = SP_D2R(180);
//
//    
//    
//    
//    
//    [self addChild:img];
//    
//    [img addEventListener:@selector(onImageTouched:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
//
//    self.tmpImage = img;
//    
//    // This is where the code of your game will start. 
//    // In this sample, we add just a few simple elements to get a feeling about how it's done.
//    
//    [SPAudioEngine start];  // starts up the sound engine
//    
//    
//    // The Application contains a very handy "Media" class which loads your texture atlas
//    // and all available sound files automatically. Extend this class as you need it --
//    // that way, you will be able to access your textures and sounds throughout your 
//    // application, without duplicating any resources.
//    
//    [Media initAtlas];      // loads your texture atlas -> see Media.h/Media.m
//    [Media initSound];      // loads all your sounds    -> see Media.h/Media.m
//    
//    
//    // Create some placeholder content: a background image, the Sparrow logo, and a text field.
//    // The positions are updated when the device is rotated. To make that easy, we put all objects
//    // in one sprite (_contents): it will simply be rotated to be upright when the device rotates.
//
//    _contents = [SPSprite sprite];
//    [self addChild:_contents];
//    
//    SPImage *background = [[SPImage alloc] initWithContentsOfFile:@"background.jpg"];
//    background.pivotX = background.width /2.0f;
//    background.pivotY = background.height/2.0f;
//    background.x = Sparrow.stage.width /2.0f;
//    background.y = Sparrow.stage.height/2.0f;
//    [_contents addChild:background];
    //NSString *text = @"To find out how to create your own game out of this scaffold, "
    //                 @"have a look at the 'First Steps' section of the Sparrow website!";
    
//    SPTextField *textField = [[SPTextField alloc] initWithWidth:280 height:80 text:text];
//    textField.x = (background.width - textField.width) / 2;
//    textField.y = (background.height / 2) - 135;
//    [_contents addChild:textField];

//    SPImage *image = [[SPImage alloc] initWithTexture:[Media atlasTexture:@"sparrow"]];
//    image.pivotX = (int)image.width  / 2.0f;
//    image.pivotY = (int)image.height / 2.0f;
//    image.x = Sparrow.stage.width  / 2.0f;
//    image.y = Sparrow.stage.height / 2.0f + 40.0f;
//    [_contents addChild:image];
    
//    [self updateLocations];
    
    // play a sound when the image is touched
//    [image addEventListener:@selector(onImageTouched:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
    
    // and animate it a little
    /*SPTween *tween = [SPTween tweenWithTarget:image time:1.5 transition:SP_TRANSITION_EASE_IN_OUT];
    [tween animateProperty:@"y" targetValue:image.y + 30];
    [tween animateProperty:@"rotation" targetValue:0.1];
    tween.repeatCount = 0; // repeat indefinitely
    tween.reverse = YES;
    [Sparrow.juggler addObject:tween];*/
    

    // The controller autorotates the game to all supported device orientations. 
    // Choose the orienations you want to support in the Xcode Target Settings ("Summary"-tab).
    // To update the game content accordingly, listen to the "RESIZE" event; it is dispatched
    // to all game elements (just like an ENTER_FRAME event).
    // 
    // To force the game to start up in landscape, add the key "Initial Interface Orientation"
    // to the "App-Info.plist" file and choose any landscape orientation.
    
    //[self addEventListener:@selector(onResize:) atObject:self forType:SP_EVENT_TYPE_RESIZE];
    
    // Per default, this project compiles as a universal application. To change that, enter the 
    // project info screen, and in the "Build"-tab, find the setting "Targeted device family".
    //
    // Now choose:  
    //   * iPhone      -> iPhone only App
    //   * iPad        -> iPad only App
    //   * iPhone/iPad -> Universal App
    // 
    // Sparrow's minimum deployment target is iOS 5.
}



@end
