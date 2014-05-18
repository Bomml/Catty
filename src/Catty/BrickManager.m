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

#import "BrickManager.h"
#import "BrickProtocol.h"

@implementation BrickManager

#pragma mark - construction methods
static BrickManager *sharedBrickManager = nil;

+ (BrickManager*)sharedBrickManager
{
    @synchronized(self) {
        if (sharedBrickManager == nil) {
            sharedBrickManager = [[BrickManager alloc] init];
        }
    }
    return sharedBrickManager;
}

#pragma mark - helpers
- (NSDictionary*)classNameBrickTypeMap
{
    // save map of kClassNameBrickTypeMap statically
    // for performance reasons
    static NSDictionary *classNameBrickTypeMap = nil;
    if (classNameBrickTypeMap == nil) {
        classNameBrickTypeMap = kClassNameBrickTypeMap;
    }
    return classNameBrickTypeMap;
}

- (NSDictionary*)brickTypeClassNameMap
{
    // get inverse map of kClassNameBrickTypeMap
    // and save this map statically for performance reasons
    static NSDictionary *brickTypeClassNameMap = nil;
    if (brickTypeClassNameMap == nil) {
        NSDictionary *classNameBrickTypeMap = [self classNameBrickTypeMap];
        NSMutableDictionary *brickTypeClassNameMutableMap = [NSMutableDictionary
                                                             dictionaryWithCapacity:[classNameBrickTypeMap count]];
        for (NSString *className in classNameBrickTypeMap) {
            [brickTypeClassNameMutableMap setObject:className
                                             forKey:classNameBrickTypeMap[className]];
        }
        brickTypeClassNameMap = [brickTypeClassNameMutableMap copy]; // make NSDictionary out of NSMutableDictionary
    }
    return brickTypeClassNameMap;
}

- (kBrickType)brickTypeForClassName:(NSString*)className
{
    // find right brick type by given class name (use regular map)
    NSDictionary *classNameBrickTypeMap = [self classNameBrickTypeMap];
    NSNumber *brickTypeAsNumber = classNameBrickTypeMap[className];
    if (! brickTypeAsNumber) {
        return kInvalidBrick;
    }
    return (kBrickType)[brickTypeAsNumber unsignedIntegerValue];
}

- (NSString*)classNameForBrickType:(kBrickType)brickType
{
    // find right class name by given brick type (use inverse map)
    NSDictionary *brickTypeClassNameMap = [self brickTypeClassNameMap];
    return brickTypeClassNameMap[@(brickType)];
}

- (kBrickCategoryType)brickCategoryTypeForBrickType:(kBrickType)brickType
{
    return (kBrickCategoryType)(((NSUInteger)brickType) / 100);
}

- (NSArray*)brickClassNamesOrderedByBrickType
{
    // save array statically for performance reasons
    static NSArray *orderedBrickClassNames = nil;
    if (orderedBrickClassNames == nil) {
        // get all brick types in NSMutableArray and sort them
        NSDictionary *brickTypeClassNameMap = [self brickTypeClassNameMap];
        NSArray *allBrickTypes = [brickTypeClassNameMap allKeys];
        NSArray *orderedBrickTypes = [allBrickTypes sortedArrayUsingSelector:@selector(compare:)];

        // collect class names
        NSMutableArray *orderedBrickClassNamesMutable = [NSMutableArray arrayWithCapacity:[orderedBrickTypes count]];
        for (NSNumber *brickType in orderedBrickTypes) {
            [orderedBrickClassNamesMutable addObject:brickTypeClassNameMap[brickType]];
        }
        orderedBrickClassNames = [orderedBrickClassNamesMutable copy]; // make NSArray out of NSMutableArray
    }
    return orderedBrickClassNames;
}

- (NSArray*)selectableBricks
{
    // retrieve all bricks that are selectable and return their objects stored in NSArray
    // and save this NSArray statically for performance reasons
    static NSArray *selectableBricks = nil;
    if (selectableBricks == nil) {
        NSArray *orderedBrickClassNames = [self brickClassNamesOrderedByBrickType];
        NSMutableArray *selectableBricksMutableArray = [NSMutableArray arrayWithCapacity:[orderedBrickClassNames count]];
        for (NSString *className in orderedBrickClassNames) {
            // only add selectable brick/script objects to the array
            id brickOrScript = [[NSClassFromString(className) alloc] init];
            if ([brickOrScript conformsToProtocol:@protocol(BrickProtocol)]) {
                id<BrickProtocol> brick = brickOrScript;
                if (brick.isSelectableForObject) {
                    [selectableBricksMutableArray addObject:brick];
                }
            }
        }
        selectableBricks = [selectableBricksMutableArray copy]; // make NSArray out of NSMutableArray
    }
    return selectableBricks;
}

- (NSArray*)selectableBricksForCategoryType:(kBrickCategoryType)categoryType
{
    NSArray *selectableBricks = [self selectableBricks];
    NSMutableArray *selectableBricksForCategoryMutable = [NSMutableArray arrayWithCapacity:[selectableBricks count]];
    for (id<BrickProtocol> brick in selectableBricks) {
        if (brick.brickCategoryType == categoryType) {
            [selectableBricksForCategoryMutable addObject:brick];
        }
    }
    return [selectableBricksForCategoryMutable copy];
}

- (NSUInteger)numberOfAvailableBricksForCategoryType:(kBrickCategoryType)categoryType
{
    switch (categoryType) {
        case kControlBrick:
            return [kControlBrickHeights count];
        case kMotionBrick:
            return [kMotionBrickHeights count];
        case kSoundBrick:
            return [kSoundBrickHeights count];
        case kLookBrick:
            return [kLookBrickHeights count];
        case kVariableBrick:
            return [kVariableBrickHeights count];
        default:
            break;
    }
    return 0;
}

- (BOOL)isScriptBrickForBrickType:(kBrickType)brickType
{
    kBrickCategoryType categoryType = (kBrickCategoryType)(((NSUInteger)brickType) / 100);
    if (categoryType == kControlBrick) {
        switch (brickType) {
            case kProgramStartedBrick:
            case kTappedBrick:
            case kReceiveBrick:
                return YES;
            default:
                break;
        }
    }
    return NO;
}

- (kBrickType)brickTypeForCategoryType:(kBrickCategoryType)categoryType andBrickIndex:(NSUInteger)index
{
    return (kBrickType)(categoryType * 100 + index);
}

- (NSUInteger)brickIndexForBrickType:(kBrickType)brickType
{
    return (brickType % 100);
}

@end
