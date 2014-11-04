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

#import "VariablesContainer+CBXMLHandler.h"
#import "GDataXMLNode+CustomExtensions.h"
#import "VariablesContainer.h"
#import "CBXMLValidator.h"
#import "OrderedMapTable.h"
#import "CBXMLParser.h"
#import "SpriteObject+CBXMLHandler.h"
#import "UserVariable+CBXMLHandler.h"
#import "CBXMLContext.h"

@implementation VariablesContainer (CBXMLHandler)

+ (instancetype)parseFromElement:(GDataXMLElement*)xmlElement withContext:(CBXMLContext*)context
{
    NSMutableArray *spriteObjectList = context.spriteObjectList;
    [XMLError exceptionIfNil:spriteObjectList message:@"Program not set in context"];

    NSArray *variablesElements = [xmlElement elementsForName:@"variables"];
    [XMLError exceptionIf:[variablesElements count] notEquals:1 message:@"Too many variable-elements given!"];
    GDataXMLElement *variablesElement = [variablesElements firstObject];
    VariablesContainer *varContainer = [VariablesContainer new];

    NSArray *objectVarListElements = [variablesElement elementsForName:@"objectVariableList"];
    if ([objectVarListElements count]) {
        [XMLError exceptionIf:[objectVarListElements count] notEquals:1 message:@"Too many objectVariableList-elements!"];
        GDataXMLElement *objectVarListElement = [objectVarListElements firstObject];
        varContainer.objectVariableList = [[self class] parseAndCreateObjectVariables:objectVarListElement withSpriteObjectList:spriteObjectList];
    }

    NSArray *programVarListElements = [variablesElement elementsForName:@"programVariableList"];
    if ([programVarListElements count]) {
        [XMLError exceptionIf:[programVarListElements count] notEquals:1 message:@"Too many programVariableList-elements!"];
        GDataXMLElement *programVarListElement = [programVarListElements firstObject];
        varContainer.programVariableList = [[self class] parseAndCreateProgramVariables:programVarListElement withSpriteObjectList:spriteObjectList];
    }
    // TODO userBrickVariableList => what do you mean exactly?
    return varContainer;
}

+ (OrderedMapTable*)parseAndCreateObjectVariables:(GDataXMLElement*)objectVarListElement
                             withSpriteObjectList:(NSMutableArray*)spriteObjectList
{
    [XMLError exceptionIfNil:spriteObjectList message:@"Class was not initialized with sprite object list!"];
    NSArray *entries = [objectVarListElement children];
    OrderedMapTable *objectVariableMap = [OrderedMapTable weakToStrongObjectsMapTable];
    for (GDataXMLElement *entry in entries) {
        [XMLError exceptionIfNode:entry isNilOrNodeNameNotEquals:@"entry"];
        NSArray *objectElements = [entry elementsForName:@"object"];
        [XMLError exceptionIf:[objectElements count] notEquals:1 message:@"Too many object-elements given!"];
        GDataXMLElement *objectElement = [objectElements firstObject];
        SpriteObject *spriteObject = nil;
        
        // check if object contains a reference or is declared here!
        if ([CBXMLParser isReferenceElement:objectElement]) {
            GDataXMLNode *referenceAttribute = [objectElement attributeForName:@"reference"];
            NSString *xPath = [referenceAttribute stringValue];
            objectElement = [objectElement singleNodeForCatrobatXPath:xPath];
            [XMLError exceptionIfNil:objectElement message:@"Invalid reference in object. No or too many objects found!"];
            GDataXMLNode *nameAttribute = [objectElement attributeForName:@"name"];
            [XMLError exceptionIfNil:nameAttribute message:@"Object element does not contain a name attribute!"];
            spriteObject = [CBXMLParser findSpriteObjectInArray:spriteObjectList
                                                       withName:[nameAttribute stringValue]];
            [XMLError exceptionIfNil:spriteObject message:@"Fatal error: no sprite object found in list, but should already exist!"];
        } else {
            // OMG!! a sprite object has been defined within the variables list...
            spriteObject = [SpriteObject parseFromElement:objectElement withContext:nil];
            [XMLError exceptionIfNil:spriteObject message:@"Unable to parse sprite object..."];
            [spriteObjectList addObject:spriteObject];
        }

        NSArray *listElements = [entry elementsForName:@"list"];
        GDataXMLElement *listElement = [listElements firstObject];
        NSMutableArray *userVarList = [[NSMutableArray alloc] initWithCapacity:[listElement childCount]];
        for (GDataXMLElement *userVarElement in [listElement children]) {
            [XMLError exceptionIfNode:userVarElement isNilOrNodeNameNotEquals:@"userVariable"];
            UserVariable *userVariable = nil;
            GDataXMLElement *userVariableElement = userVarElement;
            if ([CBXMLParser isReferenceElement:userVarElement]) {
                // OMG!! user variable has already been defined outside the variables list
                GDataXMLNode *referenceAttribute = [objectElement attributeForName:@"reference"];
                NSString *xPath = [referenceAttribute stringValue];
                userVariableElement = [objectElement singleNodeForCatrobatXPath:xPath];
                [XMLError exceptionIfNil:userVariableElement
                                 message:@"Invalid reference in object. No or too many objects found!"];
            }
            userVariable = [UserVariable parseFromElement:userVariableElement withContext:nil];
            [XMLError exceptionIfNil:userVariable message:@"Unable to parse user variable..."];
#warning !! UPDATE THE REFERENCE IN ALL VARIABLE-BRICKS FOR THIS USERVARIABLE IN ALL OBJECTS !!
            [userVarList addObject:userVariable];
        }
        [objectVariableMap setObject:userVarList forKey:spriteObject];
    }
    return objectVariableMap;
}

+ (NSMutableArray*)parseAndCreateProgramVariables:(GDataXMLElement*)programVarListElement
                             withSpriteObjectList:(NSMutableArray*)spriteObjectList
{
    [XMLError exceptionIfNil:spriteObjectList message:@"Class was not initialized with sprite object list!"];
    NSArray *entries = [programVarListElement children];
    NSMutableArray *programVariableList = [NSMutableArray arrayWithCapacity:[programVarListElement childCount]];
    for (GDataXMLElement *userVarElement in entries) {
        [XMLError exceptionIfNode:userVarElement isNilOrNodeNameNotEquals:@"userVariable"];
        UserVariable *userVariable = nil;
        GDataXMLElement *userVariableElement = userVarElement;
        if ([CBXMLParser isReferenceElement:userVariableElement]) {
            // OMG!! user variable has already been defined outside the variables list
            GDataXMLNode *referenceAttribute = [userVariableElement attributeForName:@"reference"];
            NSString *xPath = [referenceAttribute stringValue];
            userVariableElement = [userVariableElement singleNodeForCatrobatXPath:xPath];
            [XMLError exceptionIfNil:userVariableElement
                             message:@"Invalid reference in object. No or too many objects found!"];
        }
        userVariable = [UserVariable parseFromElement:userVariableElement withContext:nil];
        [XMLError exceptionIfNil:userVariable message:@"Unable to parse user variable..."];
#warning !! UPDATE THE REFERENCE IN ALL VARIABLE-BRICKS FOR THIS USERVARIABLE IN ALL OBJECTS !!
        [programVariableList addObject:userVariable];
    }
    return programVariableList;
}

@end
