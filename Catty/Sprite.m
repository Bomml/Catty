//
//  Sprite.m
//  Catty
//
//  Created by Mattias Rauter on 17.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Sprite.h"
#import "Costume.h"

typedef struct {
    CGPoint geometryVertex;
    CGPoint textureVertex;
} TexturedVertex;

typedef struct {
    TexturedVertex bottomLeftCorner;
    TexturedVertex bottomRightCorner;
    TexturedVertex topLeftCorner;
    TexturedVertex topRightCorner;
} TexturedQuad;


@interface Sprite()

@property (assign) TexturedQuad quad;
@property (nonatomic, strong) GLKTextureInfo *textureInfo;

@end

@implementation Sprite

// public synthesizes
@synthesize name = _name;
@synthesize costumesArray = _costumesArray;
@synthesize soundsArray = _soundsArray;
@synthesize position = _position;
@synthesize contentSize = _contentSize;
@synthesize indexOfCurrentCostumeInArray = _indexOfCurrentCostumeInArray;
@synthesize effect = _effect;

// private synthesizes
@synthesize quad = _quad;
@synthesize textureInfo = _textureInfo;


// Methods
- (id)initWithEffect:(GLKBaseEffect*)effect
{
    self = [super init];
    if (self)
    {
        self.effect = effect;
    }
    return self;
}

-(void)setIndexOfCurrentCostumeInArray:(int)indexOfCurrentCostumeInArray
{
    _indexOfCurrentCostumeInArray = indexOfCurrentCostumeInArray;
    
    NSString *fileName = ((Costume*)[self.costumesArray objectAtIndex:self.indexOfCurrentCostumeInArray]).filePath;
    
    NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES],
                              GLKTextureLoaderOriginBottomLeft, 
                              nil];
    
    NSError *error;    
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    
    self.textureInfo = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if (self.textureInfo == nil) {
        NSLog(@"Error loading file: %@", [error localizedDescription]);
        return;
    }
    
    self.contentSize = CGSizeMake(self.textureInfo.width, self.textureInfo.height);
    
    
    TexturedQuad newQuad;
    newQuad.bottomLeftCorner.geometryVertex = CGPointMake(0, 0);
    newQuad.bottomRightCorner.geometryVertex = CGPointMake(self.textureInfo.width, 0);
    newQuad.topLeftCorner.geometryVertex = CGPointMake(0, self.textureInfo.height);
    newQuad.topRightCorner.geometryVertex = CGPointMake(self.textureInfo.width, self.textureInfo.height);
    
    newQuad.bottomLeftCorner.textureVertex = CGPointMake(0, 0);
    newQuad.bottomRightCorner.textureVertex = CGPointMake(1, 0);
    newQuad.topLeftCorner.textureVertex = CGPointMake(0, 1);
    newQuad.topRightCorner.textureVertex = CGPointMake(1, 1);
    self.quad = newQuad;

}

- (GLKMatrix4) modelMatrix {
    
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;    
    modelMatrix = GLKMatrix4Translate(modelMatrix, self.position.x, self.position.y, 0);
    //modelMatrix = GLKMatrix4Translate(modelMatrix, -self.contentSize.width/2, -self.contentSize.height/2, 0);
    return modelMatrix;
}

- (void)render { 
    
    if (!self.effect)
        NSLog(@"Sprite.m => render => NO effect set!!!");
    
    self.effect.texture2d0.name = self.textureInfo.name;
    self.effect.texture2d0.enabled = YES;
    
    self.effect.transform.modelviewMatrix = self.modelMatrix;
    
    [self.effect prepareToDraw];
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    long offset = (long)&_quad;        
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedVertex), (void *) (offset + offsetof(TexturedVertex, geometryVertex)));
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedVertex), (void *) (offset + offsetof(TexturedVertex, textureVertex)));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


@end
