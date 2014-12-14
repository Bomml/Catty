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

#import "IfLogicBeginBrick+CBXMLHandler.h"
#import "GDataXMLNode+CustomExtensions.h"
#import "CBXMLValidator.h"
#import "CBXMLParser.h"
#import "CBXMLContext.h"
#import "CBXMLOpenedNestingBricksStack.h"
#import "CBXMLParserHelper.h"
#import "Formula+CBXMLHandler.h"

@implementation IfLogicBeginBrick (CBXMLHandler)

+ (instancetype)parseFromElement:(GDataXMLElement*)xmlElement withContext:(CBXMLContext*)context
{
    [CBXMLParserHelper validateXMLElement:xmlElement forNumberOfChildNodes:1];
    IfLogicBeginBrick *ifLogicBeginBrick = [self new];
    Formula *formula = [CBXMLParserHelper formulaInXMLElement:xmlElement forCategoryName:@"IF_CONDITION"];
    ifLogicBeginBrick.ifCondition = formula;

    // add opening nesting brick on stack
    [context.openedNestingBricksStack pushAndOpenNestingBrick:ifLogicBeginBrick];
    return ifLogicBeginBrick;
}

- (GDataXMLElement*)xmlElementWithContext:(CBXMLContext*)context
{
    GDataXMLElement *xmlElement = [GDataXMLNode elementWithName:@"brick"];
    [xmlElement addAttribute:[GDataXMLNode elementWithName:@"type" stringValue:@"IfLogicBeginBrick"]];
    GDataXMLElement *formulaList = [GDataXMLNode elementWithName:@"formulaList"];
    GDataXMLElement *formula = [self.ifCondition xmlElementWithContext:context];
    [formula addAttribute:[GDataXMLNode elementWithName:@"category" stringValue:@"IF_CONDITION"]];
    [formulaList addChild:formula];
    [xmlElement addChild:formulaList];

    // add opening nesting brick on stack
    [context.openedNestingBricksStack pushAndOpenNestingBrick:self];
    return xmlElement;
}

@end
