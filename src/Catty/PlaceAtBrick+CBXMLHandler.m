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

#import "PlaceAtBrick+CBXMLHandler.h"
#import "CBXMLValidator.h"
#import "GDataXMLNode+CustomExtensions.h"
#import "Formula+CBXMLHandler.h"
#import "CBXMLParserHelper.h"

@implementation PlaceAtBrick (CBXMLHandler)

+ (instancetype)parseFromElement:(GDataXMLElement*)xmlElement withContext:(CBXMLContext*)context
{
    [CBXMLParserHelper validateXMLElement:xmlElement forNumberOfChildNodes:1 AndFormulaListWithTotalNumberOfFormulas:2];
    Formula *formulaXPosition = [CBXMLParserHelper formulaInXMLElement:xmlElement forCategoryName:@"X_POSITION"];
    Formula *formulaYPosition = [CBXMLParserHelper formulaInXMLElement:xmlElement forCategoryName:@"Y_POSITION"];

    PlaceAtBrick *placeAtBrick = [self new];
    placeAtBrick.xPosition = formulaXPosition;
    placeAtBrick.yPosition = formulaYPosition;
    return placeAtBrick;
}

- (GDataXMLElement*)xmlElement
{
    GDataXMLElement *brick = [GDataXMLNode elementWithName:@"brick"];
    [brick addAttribute:[GDataXMLNode elementWithName:@"type" stringValue:@"PlaceAtBrick"]];
    GDataXMLElement *formulaList = [GDataXMLNode elementWithName:@"formulaList"];
    GDataXMLElement *formula = [self.xPosition xmlElement];
    [formula addAttribute:[GDataXMLNode elementWithName:@"category" stringValue:@"Y_POSITION"]];
    [formulaList addChild:formula];
    formula = [self.yPosition xmlElement];
    [formula addAttribute:[GDataXMLNode elementWithName:@"category" stringValue:@"X_POSITION"]];
    [formulaList addChild:formula];
    [brick addChild:formulaList];
    return brick;
}


@end
