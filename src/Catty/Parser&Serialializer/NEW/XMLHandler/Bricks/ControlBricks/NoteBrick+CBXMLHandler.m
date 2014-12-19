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

#import "NoteBrick+CBXMLHandler.h"
#import "CBXMLValidator.h"
#import "CBXMLParserHelper.h"
#import "GDataXMLNode+CustomExtensions.h"
#import "Formula+CBXMLHandler.h"
#import "FormulaElement.h"

@implementation NoteBrick (CBXMLHandler)

+ (instancetype)parseFromElement:(GDataXMLElement*)xmlElement withContext:(CBXMLContext*)context
{
    [CBXMLParserHelper validateXMLElement:xmlElement forNumberOfChildNodes:1 AndFormulaListWithTotalNumberOfFormulas:1];
    Formula *formula = [CBXMLParserHelper formulaInXMLElement:xmlElement forCategoryName:@"NOTE"];
    [XMLError exceptionIf:formula.formulaTree.type notEquals:STRING
                  message:@"FormulaElement contains unknown type %lu! Should be STRING!",
     (unsigned long)formula.formulaTree.type];
    [XMLError exceptionIfNil:formula.formulaTree.value message:@"FormulaElement contains no value!!"];
    
    NoteBrick *noteBrick = [self new];
    noteBrick.note = formula.formulaTree.value;
    return noteBrick;
}

- (GDataXMLElement*)xmlElementWithContext:(CBXMLContext*)context
{
    Formula *speakFormula = [Formula new];
    FormulaElement *formulaElement = [FormulaElement new];
    formulaElement.type = STRING;
    formulaElement.value = self.note;
    speakFormula.formulaTree = formulaElement;
    
    GDataXMLElement *brick = [GDataXMLNode elementWithName:@"brick"];
    [brick addAttribute:[GDataXMLNode elementWithName:@"type" stringValue:@"NoteBrick"]];
    GDataXMLElement *formulaList = [GDataXMLNode elementWithName:@"formulaList"];
    GDataXMLElement *formula = [speakFormula xmlElementWithContext:context];
    [formula addAttribute:[GDataXMLNode elementWithName:@"category" stringValue:@"NOTE"]];
    [formulaList addChild:formula];
    [brick addChild:formulaList];
    return brick;
}

@end
