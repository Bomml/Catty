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

#import <UIKit/UIKit.h>
#import "ProgramDefines.h"
#import "UIDefines.h"
#import "ScriptDeleteButton.h"
#import "BrickCellProtocol.h"
#import "BrickShapeFactory.h"
#import "UIColor+CatrobatUIColorExtensions.h"

@class Brick;
@class BrickCellInlineView;
@protocol BrickProtocol;

@interface BrickCell : UICollectionViewCell<BrickCellProtocol>

@property (nonatomic, strong) id<BrickProtocol> brick;
@property (nonatomic, strong) NSArray *brickCategoryColors;
@property (nonatomic) BOOL enabled;
- (kBrickShapeType)brickShapeType;
+ (CGFloat)cellHeight;

- (void)hookUpSubViews:(NSArray *)inlineViewSubViews; // abstract
- (void)renderSubViews;
- (BOOL)isScriptBrick;

// TODO: review that
@property (nonatomic, strong) ScriptDeleteButton *deleteButton;
@property (nonatomic, assign) BOOL hideDeleteButton;
- (void)setBrickEditing:(BOOL)editing;
- (void)animateBrick:(BOOL)animate;

@end
