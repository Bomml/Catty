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

#import "FormulaElement+CBXMLHandler.h"
#import "CBXMLValidator.h"
#import "GDataXMLNode+CustomExtensions.h"

@implementation FormulaElement (CBXMLHandler)

+ (instancetype)parseFromElement:(GDataXMLElement*)xmlElement withContext:(CBXMLContext*)context
{
    GDataXMLElement *typeElement = [xmlElement childWithElementName:@"type"];
    [XMLError exceptionIfNil:xmlElement message:@"No type element found..."];
    NSString *type = [typeElement stringValue];
    
    GDataXMLElement *valueElement = [xmlElement childWithElementName:@"value"];
    NSString *stringValue = [valueElement stringValue];
    
    FormulaElement *formulaTree = [[FormulaElement alloc] initWithType:type value:stringValue leftChild:nil rightChild:nil parent:nil];
    
    GDataXMLElement *rightChildElement = [xmlElement childWithElementName:@"rightChild"];
    if(rightChildElement)
    {
        FormulaElement *rightChildFormula = [self parseFromElement:rightChildElement withContext:context];
        formulaTree.rightChild = rightChildFormula;
    }
    
    GDataXMLElement *leftChildElement = [xmlElement childWithElementName:@"leftChild"];
    if(leftChildElement)
    {
        FormulaElement *leftChildFormula = [self parseFromElement:leftChildElement withContext:context];
        formulaTree.leftChild = leftChildFormula;
    }
    
    return formulaTree;
}

@end
