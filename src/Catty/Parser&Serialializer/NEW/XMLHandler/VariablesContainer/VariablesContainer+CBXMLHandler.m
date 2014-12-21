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
#import "GDataXMLElement+CustomExtensions.h"
#import "VariablesContainer.h"
#import "CBXMLValidator.h"
#import "OrderedMapTable.h"
#import "CBXMLParserHelper.h"
#import "SpriteObject+CBXMLHandler.h"
#import "UserVariable+CBXMLHandler.h"
#import "CBXMLContext.h"
#import "CBXMLSerializerHelper.h"

@implementation VariablesContainer (CBXMLHandler)

#pragma mark - Parsing
+ (instancetype)parseFromElement:(GDataXMLElement*)xmlElement withContext:(CBXMLContext*)context
{
    NSArray *variablesElements = [xmlElement elementsForName:@"variables"];
    [XMLError exceptionIf:[variablesElements count] notEquals:1 message:@"Too many variable-elements given!"];
    GDataXMLElement *variablesElement = [variablesElements firstObject];
    VariablesContainer *varContainer = [VariablesContainer new];
    
    NSArray *objectVarListElements = [variablesElement elementsForName:@"objectVariableList"];
    if ([objectVarListElements count]) {
        [XMLError exceptionIf:[objectVarListElements count] notEquals:1 message:@"Too many objectVariableList-elements!"];
        GDataXMLElement *objectVarListElement = [objectVarListElements firstObject];
        varContainer.objectVariableList = [[self class] parseAndCreateObjectVariables:objectVarListElement
                                                                          withContext:context];
    }

    NSArray *programVarListElements = [variablesElement elementsForName:@"programVariableList"];
    if ([programVarListElements count]) {
        [XMLError exceptionIf:[programVarListElements count] notEquals:1
                      message:@"Too many programVariableList-elements!"];
        GDataXMLElement *programVarListElement = [programVarListElements firstObject];
        
        varContainer.programVariableList = [[self class] parseAndCreateProgramVariables:programVarListElement
                                                                            withContext:context];
    }
    return varContainer;
}

+ (OrderedMapTable*)parseAndCreateObjectVariables:(GDataXMLElement*)objectVarListElement
                                      withContext:(CBXMLContext*)context
{
    NSArray *entries = [objectVarListElement children];
    OrderedMapTable *objectVariableMap = [OrderedMapTable weakToStrongObjectsMapTable];
    for (GDataXMLElement *entry in entries) {
        [XMLError exceptionIfNode:entry isNilOrNodeNameNotEquals:@"entry"];
        NSArray *objectElements = [entry elementsForName:@"object"];
        [XMLError exceptionIf:[objectElements count] notEquals:1 message:@"Too many object-elements given!"];
        GDataXMLElement *objectElement = [objectElements firstObject];
        SpriteObject *spriteObject = nil;
        
        // check if object contains a reference or is declared here!
        if ([CBXMLParserHelper isReferenceElement:objectElement]) {
            GDataXMLNode *referenceAttribute = [objectElement attributeForName:@"reference"];
            NSString *xPath = [referenceAttribute stringValue];
            objectElement = [objectElement singleNodeForCatrobatXPath:xPath];
            [XMLError exceptionIfNil:objectElement message:@"Invalid reference in object. No or too many objects found!"];
            GDataXMLNode *nameAttribute = [objectElement attributeForName:@"name"];
            [XMLError exceptionIfNil:nameAttribute message:@"Object element does not contain a name attribute!"];
            spriteObject = [CBXMLParserHelper findSpriteObjectInArray:context.spriteObjectList
                                                             withName:[nameAttribute stringValue]];
            [XMLError exceptionIfNil:spriteObject message:@"Fatal error: no sprite object found in list, but should already exist!"];
        } else {
            // OMG!! a sprite object has been defined within the variables list...
            spriteObject = [SpriteObject parseFromElement:objectElement withContext:nil];
            [XMLError exceptionIfNil:spriteObject message:@"Unable to parse sprite object..."];
            [context.spriteObjectList addObject:spriteObject];
        }

        NSArray *listElements = [entry elementsForName:@"list"];
        GDataXMLElement *listElement = [listElements firstObject];
        NSMutableArray *userVarList = [[NSMutableArray alloc] initWithCapacity:[listElement childCount]];
        for (GDataXMLElement *userVarElement in [listElement children]) {
            [XMLError exceptionIfNode:userVarElement isNilOrNodeNameNotEquals:@"userVariable"];
            GDataXMLElement *userVariableElement = userVarElement;
            if ([CBXMLParserHelper isReferenceElement:userVarElement]) {
                // OMG!! user variable has already been defined outside the variables list
                GDataXMLNode *referenceAttribute = [userVarElement attributeForName:@"reference"];
                NSString *xPath = [referenceAttribute stringValue];
                userVariableElement = [userVarElement singleNodeForCatrobatXPath:xPath];
                [XMLError exceptionIfNil:userVariableElement
                                 message:@"Invalid reference in object. No or too many objects found!"];
            }
            UserVariable *compareUserVariable = [UserVariable parseFromElement:userVariableElement withContext:nil];
            [XMLError exceptionIfNil:compareUserVariable message:@"Unable to parse user variable..."];
            UserVariable *alreadyExistingUserVariable = [CBXMLParserHelper findUserVariableInArray:context.userVariableList
                                                                                          withName:compareUserVariable.name];
            UserVariable *userVariableToAdd = nil;
            if (alreadyExistingUserVariable) {
                userVariableToAdd = alreadyExistingUserVariable;
            } else {
                userVariableToAdd = compareUserVariable;
                [context.userVariableList addObject:userVariableToAdd];
            }
            [userVarList addObject:userVariableToAdd];
        }
        [objectVariableMap setObject:userVarList forKey:spriteObject];
    }
    return objectVariableMap;
}

+ (NSMutableArray*)parseAndCreateProgramVariables:(GDataXMLElement*)programVarListElement
                                      withContext:(CBXMLContext*)context
{
    NSArray *entries = [programVarListElement children];
    NSMutableArray *programVariableList = [NSMutableArray arrayWithCapacity:[programVarListElement childCount]];
    for (GDataXMLElement *userVarElement in entries) {
        [XMLError exceptionIfNode:userVarElement isNilOrNodeNameNotEquals:@"userVariable"];
        GDataXMLElement *userVariableElement = userVarElement;
        if ([CBXMLParserHelper isReferenceElement:userVariableElement]) {
            // OMG!! user variable has already been defined outside the variables list
            GDataXMLNode *referenceAttribute = [userVariableElement attributeForName:@"reference"];
            NSString *xPath = [referenceAttribute stringValue];
            userVariableElement = [userVariableElement singleNodeForCatrobatXPath:xPath];
            [XMLError exceptionIfNil:userVariableElement
                             message:@"Invalid reference in object. No or too many objects found!"];
        }
        UserVariable *compareUserVariable = [UserVariable parseFromElement:userVariableElement withContext:nil];
        [XMLError exceptionIfNil:compareUserVariable message:@"Unable to parse user variable..."];
        UserVariable *alreadyExistingUserVariable = [CBXMLParserHelper findUserVariableInArray:context.userVariableList
                                                                                      withName:compareUserVariable.name];
        UserVariable *userVariableToAdd = nil;
        if (alreadyExistingUserVariable) {
            userVariableToAdd = alreadyExistingUserVariable;
        } else {
            userVariableToAdd = compareUserVariable;
            [context.userVariableList addObject:userVariableToAdd];
        }
        [programVariableList addObject:userVariableToAdd];
    }
    return programVariableList;
}

#pragma mark - Serialization
- (GDataXMLElement*)xmlElementWithContext:(CBXMLContext*)context
{
    GDataXMLElement *xmlElement = [GDataXMLElement elementWithName:@"variables" context:context];
    GDataXMLElement *objectVariableListXmlElement = [GDataXMLElement elementWithName:@"objectVariableList" context:context];
    NSUInteger totalNumOfObjectVariables = [self.objectVariableList count];

    for (NSUInteger index = 0; index < totalNumOfObjectVariables; ++index) {
        GDataXMLElement *entryXmlElement = [GDataXMLElement elementWithName:@"entry" context:context];
        GDataXMLElement *entryToObjectReferenceXmlElement = [GDataXMLElement elementWithName:@"object" context:context];
        id spriteObject = [self.objectVariableList keyAtIndex:index];
        [XMLError exceptionIf:[spriteObject isKindOfClass:[SpriteObject class]] equals:NO
                      message:@"Instance in objectVariableList at index: %lu is no SpriteObject", index];
        NSString *referencePath = [CBXMLSerializerHelper relativeXPathToObject:(SpriteObject*)spriteObject
                                                                       context:context];
        [entryToObjectReferenceXmlElement addAttribute:[GDataXMLNode attributeWithName:@"reference"
                                                                            stringValue:referencePath]];
        [entryXmlElement addChild:entryToObjectReferenceXmlElement context:context];

        GDataXMLElement *listXmlElement = [GDataXMLElement elementWithName:@"list" context:context];
        NSArray *variables = [self.objectVariableList objectAtIndex:index];
        for (id variable in variables) {
            [XMLError exceptionIf:[variable isKindOfClass:[UserVariable class]] equals:NO
                          message:@"Invalid user variable instance given"];
            GDataXMLElement *userVariableXmlElement = [GDataXMLElement elementWithName:@"userVariable" context:context];
            // TODO: determine XPath...
            [userVariableXmlElement addAttribute:[GDataXMLNode attributeWithName:@"reference" stringValue:@""]];
            [listXmlElement addChild:userVariableXmlElement context:context];
        }
        [entryXmlElement addChild:listXmlElement context:context];
        [objectVariableListXmlElement addChild:entryXmlElement context:context];
    }

    if (totalNumOfObjectVariables) {
        [xmlElement addChild:objectVariableListXmlElement context:context];
    }

    GDataXMLElement *programVariableListXmlElement = [GDataXMLElement elementWithName:@"programVariableList" context:context];
    for (id variable in self.programVariableList) {
        [XMLError exceptionIf:[variable isKindOfClass:[UserVariable class]] equals:NO
                      message:@"Invalid user variable instance given"];
        GDataXMLElement *userVariableXmlElement = [GDataXMLElement elementWithName:@"userVariable" context:context];
        // TODO: determine XPath...
        [userVariableXmlElement addAttribute:[GDataXMLNode attributeWithName:@"reference" stringValue:@""]];
        [programVariableListXmlElement addChild:userVariableXmlElement context:context];
    }

    if ([self.programVariableList count]) {
        [xmlElement addChild:programVariableListXmlElement context:context];
    }

    GDataXMLElement *userBrickVariableListXmlElement = [GDataXMLElement elementWithName:@"userBrickVariableList" context:context];
    // TODO: implement userBrickVariables here...
    [xmlElement addChild:userBrickVariableListXmlElement context:context];

    return xmlElement;
}

@end
