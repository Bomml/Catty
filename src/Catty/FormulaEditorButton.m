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

#import "FormulaEditorButton.h"
#import "Formula.h"
#import "UIColor+CatrobatUIColorExtensions.h"
#import "BrickFormulaProtocol.h"

@interface FormulaEditorButton ()

@property (nonatomic, strong) CAShapeLayer *border;

@end

@implementation FormulaEditorButton

static Formula *activeFormula;

- (id)initWithFrame:(CGRect)frame AndBrickCell:(BrickCell*)brickCell AndFormula:(Formula *)formula
{
    self = [super initWithFrame:frame];
    
    if(self) {
        self.brickCell = brickCell;
        self.formula = formula;
        
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont systemFontOfSize:kBrickTextFieldFontSize];

        [self setTitle:[formula getDisplayString] forState:UIControlStateNormal];
    
        [self sizeToFit];
        CGRect labelFrame = self.frame;
        labelFrame.size.height = self.frame.size.height;
        self.frame = labelFrame;
        
        [self addTarget:brickCell.delegate action:@selector(openFormulaEditor:) forControlEvents:UIControlEventTouchUpInside];
        
        if([[FormulaEditorButton getActiveFormula] isEqual:formula]) {
            [self drawBorder:YES];
        } else {
            [self drawBorder:NO];
        }
    }
    
    return self;
}

+ (Formula*)getActiveFormula
{
    return activeFormula;
}

+ (void)setActiveFormula:(Formula*)formula
{
    activeFormula = formula;
}

#define FORMULA_MAX_LENGTH 15

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    if([title length] > FORMULA_MAX_LENGTH) {
        title = [NSString stringWithFormat:@"%@...", [title substringToIndex:FORMULA_MAX_LENGTH]];
    }
    
    title = [NSString stringWithFormat:@" %@ ", title];
    [super setTitle:title forState:state];
}

#define BORDER_WIDTH 1.0
#define BORDER_HEIGHT 4
#define BORDER_TRANSPARENCY 0.9
#define BORDER_PADDING 3.8

- (void)drawBorder:(BOOL)isActive
{
    if(self.border)
        [self.border removeFromSuperlayer];
    
    self.border = [[CAShapeLayer alloc] init];
    
    UIBezierPath *borderPath = [[UIBezierPath alloc] init];
    
    CGPoint startPoint = CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds) - BORDER_PADDING);
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds) - BORDER_PADDING - BORDER_HEIGHT);
    [borderPath moveToPoint:startPoint];
    [borderPath addLineToPoint:endPoint];
    
    startPoint = CGPointMake(0, CGRectGetMaxY(self.bounds) - BORDER_PADDING);
    endPoint = CGPointMake(0, CGRectGetMaxY(self.bounds) - BORDER_PADDING - BORDER_HEIGHT);
    [borderPath moveToPoint:startPoint];
    [borderPath addLineToPoint:endPoint];
    
    startPoint = CGPointMake(-BORDER_WIDTH / 2, CGRectGetMaxY(self.bounds) - BORDER_PADDING);
    endPoint = CGPointMake(CGRectGetMaxX(self.bounds) + BORDER_WIDTH / 2, CGRectGetMaxY(self.bounds) - BORDER_PADDING);
    [borderPath moveToPoint:startPoint];
    [borderPath addLineToPoint:endPoint];
    
    self.border.frame = self.bounds;
    self.border.path = borderPath.CGPath;
    self.border.lineWidth = BORDER_WIDTH;
    [self.border setOpacity:BORDER_TRANSPARENCY];
    
    if(isActive) {
        
        self.border.strokeColor = [UIColor cellBlueColor].CGColor;
        
        self.border.shadowColor = [UIColor lightBlueColor].CGColor;
        self.border.shadowRadius = 1;
        self.border.shadowOpacity = 1.0;
        self.border.shadowOffset = CGSizeMake(0, 0);
        
    } else {
        
        UIColor *borderColor = kBrickCategoryStrokeColors[self.brickCell.brick.brickCategoryType];
        self.border.strokeColor = borderColor.CGColor;
        
    }
    
    [self.layer addSublayer:self.border];
}

@end
