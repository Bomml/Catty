/**
 *  Copyright (C) 2010-2014 The Catrobat Team
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
#import "BrickProtocol.h"

@class BrickCell, SingleBrickSelectionView, BrickProtocol;

@protocol SingleBrickSelectionViewDelegate <NSObject>

@optional
- (void)singleBrickSelectionView:(SingleBrickSelectionView *)singleBrickSelectionView
                  didSelectBrick:(id<BrickProtocol>)brick replicantBrickView:(UIView *)brickView;

- (void)singleBrickSelectionView:(SingleBrickSelectionView *)singleBrickSelectionView
                  didShowWithBrick:(id<BrickProtocol>)brick replicantBrickView:(UIView *)brickView;


@end

@interface SingleBrickSelectionView : UIView
@property (strong, nonatomic) UIView *dimview;
@property (nonatomic, weak) id<SingleBrickSelectionViewDelegate> delegate;


- (void)showSingleBrickSelectionViewWithBrickCell:(BrickCell *)brickCell fromView:(UIView *)fromView
                                        belowView:(UIView *)belowView completion:(void(^)())completionBlock;

@end
