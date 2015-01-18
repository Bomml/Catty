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

#import "XMLSerializerAbstractTest.h"

@interface XMLSerializerHeaderTests : XMLSerializerAbstractTest

@end

@implementation XMLSerializerHeaderTests

- (void)testHeader
{
    Program *program = [self getProgramForXML:@"ValidProgram"];
    Header *header = program.header;
    BOOL equal = [self isXMLElement:[header xmlElementWithContext:nil] equalToXMLElementForXPath:@"//program/header" inProgramForXML:@"ValidProgram"];
    XCTAssertTrue(equal, @"XMLElement invalid!");
}

- (void)testFormulaAndMoveNStepsBrick
{
    Program *program = [self getProgramForXML:@"ValidProgramAllBricks"];
    MoveNStepsBrick *brick = (MoveNStepsBrick*)[((Script*)[((SpriteObject*)[program.objectList objectAtIndex:0]).scriptList objectAtIndex:0]).brickList objectAtIndex:5];
    BOOL equal = [self isXMLElement:[brick xmlElementWithContext:nil] equalToXMLElementForXPath:@"//program/objectList/object[1]/scriptList/script[1]/brickList/brick[6]" inProgramForXML:@"ValidProgramAllBricks"];
    XCTAssertTrue(equal, @"XMLElement invalid!");
}

/*
- (void)testPointedToBrickWithoutSpriteObject
{
    Program *program = [self getProgramForXML:@"PointToBrickWithoutSpriteObject"];
    XCTAssertNotNil(program, @"Program must not be nil!");
    
    SpriteObject *moleTwo = [program.objectList objectAtIndex:1];
    XCTAssertNotNil(moleTwo, @"SpriteObject must not be nil!");
    XCTAssertTrue([moleTwo.name isEqualToString:@"Mole 2"], @"Invalid object name!");
    
    Script *script = [moleTwo.scriptList objectAtIndex:0];
    XCTAssertNotNil(script, @"Script must not be nil!");
    
    PointToBrick *pointToBrick = [script.brickList objectAtIndex:7];
    XCTAssertNotNil(pointToBrick, @"PointToBrick must not be nil!");

    BOOL equal = [self isXMLElement:[pointToBrick xmlElementWithContext:nil] equalToXMLElementForXPath:@"//program/objectList/object[2]/scriptList/script[1]/brickList/brick[8]" inProgramForXML:@"PointToBrickWithoutSpriteObject"];
    XCTAssertTrue(equal, @"XMLElement invalid!");
}*/

@end

