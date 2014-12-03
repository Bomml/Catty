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

#import <Foundation/Foundation.h>
#import "Functions.h"
#import "Operators.h"

@class SpriteObject;

typedef enum {
    OPERATOR,
    FUNCTION,
    NUMBER,
    SENSOR,
    USER_VARIABLE,
    BRACKET,
    STRING
} ElementType;

@interface FormulaElement : NSObject

@property (nonatomic, assign) ElementType type;
@property (nonatomic, strong) NSString* value;
@property (nonatomic, strong) FormulaElement* leftChild;
@property (nonatomic, strong) FormulaElement* rightChild;
@property (nonatomic, weak) FormulaElement* parent;

- (id)initWithType:(NSString*)type
             value:(NSString*)value
         leftChild:(FormulaElement*)leftChild
        rightChild:(FormulaElement*)rightChild
            parent:(FormulaElement*)parent;


- (double)interpretRecursiveForSprite:(SpriteObject*)sprite;

- (NSArray*)XMLChildElements;
- (BOOL)isEqualToFormulaElement:(FormulaElement*)formulaElement;
- (NSString*)stringForElementType:(ElementType)type;

@end
