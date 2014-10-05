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
#import "BrickFormulaProtocol.h"
#import "UIColor+CatrobatUIColorExtensions.h"

@interface FormulaEditorButton ()

@property (nonatomic) NSInteger formulaAtLineNumber;
@property (nonatomic) NSInteger formulaAtParamNumber;

@end

@implementation FormulaEditorButton

- (id)initWithFrame:(CGRect)frame AndBrickCell:(BrickCell*)brickCell AndLineNumber:(NSInteger)lineNumber AndParameterNumber:(NSInteger)paramNumber;
{
    self = [super initWithFrame:frame];
    
    if(self) {
        self.brickCell = brickCell;
        self.formulaAtParamNumber = paramNumber;
        self.formulaAtLineNumber = lineNumber;
        
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont systemFontOfSize:kBrickTextFieldFontSize];
        
        if([self.brickCell.brick respondsToSelector:@selector(getFormulaForLineNumber: AndParameterNumber:)]) {
            [self setTitle:[[self getFormula] getDisplayString] forState:UIControlStateNormal];
        } else {
            [self setTitle:@"error" forState:UIControlStateNormal];
        }
        
        [self sizeToFit];
        CGRect labelFrame = self.frame;
        labelFrame.size.height = self.frame.size.height;
        self.frame = labelFrame;
        
        [self addBorder];
        [self addTarget:brickCell.delegate action:@selector(openFormulaEditor:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self;
}

#define maxLength 15

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    if([title length] > maxLength) {
        title = [NSString stringWithFormat:@"%@...", [title substringToIndex:maxLength]];
    }
    
    title = [NSString stringWithFormat:@" %@ ", title];
    [super setTitle:title forState:state];
}

- (Formula*)getFormula
{
    Brick<BrickFormulaProtocol> *formulaBrick = (Brick<BrickFormulaProtocol> *)self.brickCell.brick;
    return [formulaBrick getFormulaForLineNumber:self.formulaAtLineNumber AndParameterNumber:self.formulaAtParamNumber];
}

- (void)updateFormula:(InternFormula*)internFormula
{
    if(internFormula != nil) {
        InternFormulaParser *internFormulaParser = [internFormula getInternFormulaParser];
        Formula *formula = [[Formula alloc] initWithFormulaElement:[internFormulaParser parseFormula]];
        
        if([internFormulaParser getErrorTokenIndex] == FORMULA_PARSER_OK) {
            BrickCell<BrickFormulaProtocol> *formulaBrickCell = (BrickCell<BrickFormulaProtocol>*) self.brickCell.brick;
            [formulaBrickCell setFormula:formula ForLineNumber:self.formulaAtLineNumber AndParameterNumber:self.formulaAtParamNumber];
            [self.brickCell setupBrickCell];
        }
    }
}

#define borderWidth 1.0
#define borderHeight 4
#define borderTransparency 0.9
#define borderPadding 3.5

- (void)addBorder
{
    UIColor *borderColor = kBrickCategoryStrokeColors[self.brickCell.brick.brickCategoryType];
    
    CAShapeLayer *border = [[CAShapeLayer alloc] init];
    UIBezierPath *borderPath = [[UIBezierPath alloc] init];
    
    CGPoint startPoint = CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds) - borderPadding);
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds) - borderPadding - borderHeight);
    [borderPath moveToPoint:startPoint];
    [borderPath addLineToPoint:endPoint];
    
    startPoint = CGPointMake(0, CGRectGetMaxY(self.bounds) - borderPadding);
    endPoint = CGPointMake(0, CGRectGetMaxY(self.bounds) - borderPadding - borderHeight);
    [borderPath moveToPoint:startPoint];
    [borderPath addLineToPoint:endPoint];
    
    startPoint = CGPointMake(-borderWidth / 2, CGRectGetMaxY(self.bounds) - borderPadding);
    endPoint = CGPointMake(CGRectGetMaxX(self.bounds) + borderWidth / 2, CGRectGetMaxY(self.bounds) - borderPadding);
    [borderPath moveToPoint:startPoint];
    [borderPath addLineToPoint:endPoint];
    
    border.frame = self.bounds;
    border.path = borderPath.CGPath;
    border.strokeColor = borderColor.CGColor;
    border.lineWidth = borderWidth;
    [border setOpacity:borderTransparency];
    
    [self.layer addSublayer:border];
}

@end
