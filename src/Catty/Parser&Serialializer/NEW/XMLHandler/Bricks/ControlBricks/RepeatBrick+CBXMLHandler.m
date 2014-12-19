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

#import "RepeatBrick+CBXMLHandler.h"
#import "CBXMLContext.h"
#import "CBXMLOpenedNestingBricksStack.h"
#import "CBXMLParserHelper.h"
#import "GDataXMLNode+CustomExtensions.h"
#import "Formula+CBXMLHandler.h"

@implementation RepeatBrick (CBXMLHandler)

+ (instancetype)parseFromElement:(GDataXMLElement*)xmlElement withContext:(CBXMLContext*)context
{
 [CBXMLParserHelper validateXMLElement:xmlElement forNumberOfChildNodes:1];
 RepeatBrick *repeatBrick = [self new];
 Formula *formula = [CBXMLParserHelper formulaInXMLElement:xmlElement forCategoryName:@"TIMES_TO_REPEAT"];
 repeatBrick.timesToRepeat = formula;

 // add opening nesting brick on stack
 [context.openedNestingBricksStack pushAndOpenNestingBrick:repeatBrick];
 return repeatBrick;
}

- (GDataXMLElement*)xmlElementWithContext:(CBXMLContext*)context
{
 GDataXMLElement *brick = [GDataXMLNode elementWithName:@"brick"];
 [brick addAttribute:[GDataXMLNode elementWithName:@"type" stringValue:@"RepeatBrick"]];
 GDataXMLElement *formulaList = [GDataXMLNode elementWithName:@"formulaList"];
 GDataXMLElement *formula = [self.timesToRepeat xmlElementWithContext:context];
 [formula addAttribute:[GDataXMLNode elementWithName:@"category" stringValue:@"TIMES_TO_REPEAT"]];
 [formulaList addChild:formula];
 [brick addChild:formulaList];

 // add opening nesting brick on stack
 [context.openedNestingBricksStack pushAndOpenNestingBrick:self];
 return brick;
}

@end
