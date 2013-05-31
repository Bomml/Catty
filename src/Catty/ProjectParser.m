/**
 *  Copyright (C) 2010-2013 The Catrobat Team
 *  (<http://developer.catrobat.org/credits>)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  An additional term exception under section 7 of the GNU Affero
 *  General Public License, version 3, is available at
 *  http://developer.catrobat.org/license_additional_term
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "ProjectParser.h"
#import "GDataXMLNode.h"
#import "Program.h"
#import "VariablesContainer.h"
#import <objc/runtime.h>
#import <Foundation/NSObjCRuntime.h>
#import "Sound.h"
#import "Formula.h"
#import "FormulaElement.h"
#import "Script.h"
#import "UserVariable.h"
#import "XMLObjectReference.h"
#import "OrderedMapTable.h"


// test
#import "SpriteObject.h"


#define kCatroidXMLPrefix               @"org.catrobat.catroid.content."
#define kCatroidXMLSpriteList           @"spriteList"
#define kParserObjectTypeString         @"T@\"NSString\""
#define kParserObjectTypeNumber         @"T@\"NSNumber\""
#define kParserObjectTypeArray          @"T@\"NSArray\""
#define kParserObjectTypeMutableArray   @"T@\"NSMutableArray\""
#define kParserObjectTypeMutableDictionary @"T@\"NSMutableDictionary\""
#define kParserObjectTypeDate           @"T@\"NSDate\""

// TODO: fix the user defined warnings below and remove this in final version
#define kParserObjectTypeSprite         @"T@\"SpriteObject\""
#define kParserObjectTypeLookData       @"T@\"Look\""
#define kParserObjectTypeLoopEndBrick   @"T@\"Loopendbrick\""
#define kParserObjectTypeSound          @"T@\"Sound\""
#define kParserObjectTypeHeader         @"T@\"Header\""
#define kParserObjectTypeUserVariable   @"T@\"Uservariable\""
#define kParserObjectTypeFormula        @"T@\"Formula\""
#define kParserObjectTypeIfElseBrick    @"T@\"Iflogicelsebrick\""
#define kParserObjectTypeIfEndBrick     @"T@\"Iflogicendbrick\""
#define kParserObjectTypeIfBeginBrick   @"T@\"Iflogicbeginbrick\""
#define kParserObjectTypeElseBrick      @"T@\"Elsebrick\""
#define kParserObjectTypeVariables      @"T@\"VariablesContainer\""

@interface ProjectParser()

- (id)parseNode:(GDataXMLElement*)node withParent:(XMLObjectReference*)parent;
- (id)getSingleValue:(GDataXMLElement*)element ofType:(NSString*)propertyType;

// just temp
//#error todo
/*@property (nonatomic, strong) NSMutableDictionary *lookDict;
@property (nonatomic, strong) NSString *path;*/
@property (nonatomic, strong) id currentActiveSprite;
@property (nonatomic, strong) Program* program;

@end

@implementation ProjectParser   



// -----------------------------------------------------------------------------
// loadProject:
// This method passes the root element of the XML document into the parseNode:
// method, which in turn builds up the entire project 'tree' and returns it.
// Then this method returns this 'tree' that is stored as a Project object to
// the caller.
// [in] xmlData: The XML file as NSData*
// [out] This method returns the project 'tree' as Project object
- (id)loadProject:(NSData*)xmlData {
    // sanity checks
    if (!xmlData) { return nil; }
    
    NSError *error;
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData 
                                                           options:0
                                                            error:&error];
    // sanity checks
    if (error || !doc) { return nil; }

    // parse and return Project object
    Program* program = nil;
    @try
    {
        NSInfo(@"Loading Project...");
        program = [self parseNode:doc.rootElement withParent:nil];
        NSInfo(@"Loading done...");
    }
    @catch(NSException* ex)
    {
        NSError(@"Program could not be loaded! %@", [ex description]);
    }
    return program;
}



// -----------------------------------------------------------------------------
// parseNode:
// This method is used to parse a generic GDataXMLElement (node) and their
// children. First, the method instantiates a new object using introspection
// with the name of the current node. IMPORTANT: This means, that each XML tag
// must be present as class in this project. Otherwise the application aborts.
// This procedure is done recursively for each child of this node and so on.
// Each attribute in the XML file is then used to assign a value to a
// corresponding property in the introspected class/object.
// [in] node: The current GDataXMLElement node of the XML file
- (id)parseNode:(GDataXMLElement*)node withParent:(XMLObjectReference*)parent {
    
    
    if (!node) { return nil; }
    
    int i = 0;
    if ([node.name isEqualToString:@"Program"]) {
        i = 1+1;
    }
    
    // instantiate object based on node name (= class name)
    NSString *className = [[node.name componentsSeparatedByString:@"."] lastObject]; // this is just because of org.catrobat.catroid.bla...
    if (!className) {                                                                // Maybe we can remove this when the XML is finished?
        className = node.name;
    }
    
    // check for first character uppercase
    className = [className capitalizedString];
    
    if ([className isEqualToString:@"Object"] || [className isEqualToString:@"Pointedobject"]) {
        // ... introspect from "Object"... glory idea...
        // I'm so proud of you XML Team...
        className = @"SpriteObject";
    }
    
    if([className isEqualToString:@"Ifelsebrick"] || [className isEqualToString:@"Elsebrick"]) {
        className = @"Iflogicelsebrick";
    }
    
    if([className isEqualToString:@"Ifbeginbrick"] || [className isEqualToString:@"Beginbrick"]) {
        className = @"Iflogicbeginbrick";
    }
    
    if([className isEqualToString:@"Ifendbrick"]) {
        className = @"Iflogicendbrick";
    }
    
    if([className isEqualToString:@"Loopendlessbrick"]) {
        className = @"Loopendbrick";
    }
    
    
    id object = [[NSClassFromString(className) alloc] init];
    if (!object) {
        [NSException raise:@"ClassNotFoundException" format:@"Implementation of <%@> NOT FOUND!", className];
    }
    
    if([object isKindOfClass:[Program class]]) {
        self.program = object;
    }
    
    
    // just an educated gues...
    if ([object isKindOfClass:[SpriteObject class]]) {
        self.currentActiveSprite = object;
    }
    
    
    XMLObjectReference* ref = [[XMLObjectReference alloc] initWithParent:parent andObject:object];
    
    
    for (GDataXMLElement *child in node.children) {

        // maybe check node.childCount == 0?
        
        objc_property_t property = class_getProperty([object class], [child.name UTF8String]);
        if (property) { // check if property exists
            NSString *propertyType = [NSString stringWithUTF8String:property_getTypeString(property)];
            NSDebug(@"Property type: %@", propertyType);
            
            if ([propertyType isEqualToString:kParserObjectTypeArray]) {
                [NSException raise:@"WrongPropertyException" format:@"We need to keep the references at all time, please use NSMutableArray for property: %@", child.name];
            }
            else if([propertyType isEqualToString:kParserObjectTypeMutableArray]) {

                NSMutableArray* arr = [object valueForKey:child.name];
                
                if(!arr) {
                    arr = [[NSMutableArray alloc] initWithCapacity:child.childCount];
                    [object setValue:arr forKey:child.name];
                }
                
                XMLObjectReference* arrayReference = [[XMLObjectReference alloc] initWithParent:ref andObject:arr];
                
                for (GDataXMLElement *arrElement in child.children) {
                    if([self isReferenceElement:arrElement]) {
                        id object = [self parseReferenceElement:arrElement withParent:arrayReference];
                        if(object) {
                            [arr addObject:object];
                        } else {
                            NSWarn(@"Reference Element, could not be parsed!");
                        }
                    } else {
                        [arr addObject:[self parseNode:arrElement withParent:arrayReference]];
                    }
                }
                
            }
            else {
                // NOT ARRAY
                
                id value = [self getSingleValue:child ofType:propertyType withParent:ref];
                [object setValue:value forKey:child.name];
            }
            
        }
        else {
            [NSException raise:@"PropertyNotFoundException" format:@"property <%@> does NOT exist in our implementation of <%@>", child.name, className];
        }
    }
    
    return object;
}



// -----------------------------------------------------------------------------
// getSingleValue:ofType:
// This method extracts a single value of a given GDataXMLElement for the
// corresponding (given) type, such as NSString, NSArray and so on.
- (id)getSingleValue:(GDataXMLElement*)element ofType:(NSString*)propertyType withParent:(XMLObjectReference*)parent{
    // sanity checks
    if (!element || !propertyType) { return nil; }
    
    

    // check type
    if ([propertyType isEqualToString:kParserObjectTypeString]) {
        return element.stringValue;
    }
    else if ([propertyType isEqualToString:kParserObjectTypeNumber]) {
        
        NSString *temp = nil;
        NSArray* formulaTrees = [element elementsForName:@"formulaTree"];
        if(formulaTrees) {
#warning this should not be necessary any more!
            abort();
        }
        else {
            temp = element.stringValue;
        }
        return [NSNumber numberWithFloat:temp.floatValue];

    }
    else if ([propertyType isEqualToString:kParserObjectTypeDate]) {
        NSString *temp = element.stringValue;
#warning todo: we should parse the date here
        // but we only set nil... becaue it is easier actually... :-P
        return nil;
    }
#warning JUST FOR DEBUG PURPOSES!
    // todo: set the corresponding SPRITE!!! (and lookdata) => xstream notation
    else if ([propertyType isEqualToString:kParserObjectTypeSprite]) {
        
        if([self isReferenceElement:element]) {
            return [self parseReferenceElement:element withParent:parent];
        }
        else {
            id object =  [self parseNode:element withParent:parent];
            return object;
        }

    }
    else if ([propertyType isEqualToString:kParserObjectTypeLookData]) {
        // sanity check
        if (self.currentActiveSprite && [self.currentActiveSprite isKindOfClass:[SpriteObject class]]) {
            SpriteObject *sprite = (SpriteObject*)self.currentActiveSprite;
            NSString *refString = [element attributeForName:@"reference"].stringValue;
            if (!refString || [refString isEqualToString:@""]) {
               return [self parseNode:element withParent:parent];
            }
            
            // sanity check
            if (!sprite.lookList || sprite.lookList.count == 0) {
                // SHOULD NOT HAPPEN! NO LOOKS FOUND IN THIS SPRITE
                abort(); // todo
            }
            
            if (![refString hasSuffix:@"]"]) {
                return [sprite.lookList objectAtIndex:0];
            }
            else {
                NSRange rr2 = [refString rangeOfString:@"["];
                NSRange rr3 = [refString rangeOfString:@"]"];
                int lengt = rr3.location - rr2.location - rr2.length;
                int location = rr2.location + rr2.length;
                NSRange aa;
                aa.location = location;
                aa.length = lengt;
                NSString *indexString = [refString substringWithRange:aa];
                NSInteger index = indexString.integerValue;
                
                index--;
                
                // sanity check
                if (index+1 > sprite.lookList.count) {
                    // SHOULD NOT HAPPEN!
                    abort();
                }
                
                return [sprite.lookList objectAtIndex:index];
                
            }
        }
    }
    else if ([propertyType isEqualToString:kParserObjectTypeSound]) {
        
        NSString *ref = [element attributeForName:@"reference"].stringValue;        
        Sound *sound = [self parseNode:element withParent:parent];
        
        
        return sound; // TODO!
    }
    else if ([propertyType isEqualToString:kParserObjectTypeHeader]) {
        return [self parseNode:element withParent:parent];
    }
    else if ([propertyType isEqualToString:kParserObjectTypeLoopEndBrick]) {
        if([self isReferenceElement:element]) {
            return [self parseReferenceElement:element withParent:parent];
        }
        else {
            return [self parseNode:element withParent:parent];
        }
    }
    else if([propertyType isEqualToString:kParserObjectTypeUserVariable]) {
        if([self isReferenceElement:element]) {
            return [self parseReferenceElement:element withParent:parent];
        }
        else {
            return [self parseNode:element withParent:parent];
        }
    }
    else if([propertyType isEqualToString:kParserObjectTypeFormula]) {
        return [self parseFormula:element];
    }
    else if ([propertyType isEqualToString:kParserObjectTypeIfElseBrick]) {
        return [self parseNode:element withParent:parent];
    }
    else if ([propertyType isEqualToString:kParserObjectTypeIfEndBrick]) {
        return [self parseNode:element withParent:parent];
    }
    else if ([propertyType isEqualToString:kParserObjectTypeIfBeginBrick]) {
        return [self parseNode:element withParent:parent];
    }
    else if ([propertyType isEqualToString:kParserObjectTypeVariables]) {
        return [self parseVariablesContainer:element withParent:parent];
    }
    else {
        [NSException raise:@"UnknownPropertyException" format:@"Property Type: %@ not found", propertyType];
    }
    
    return nil;
}


-(id) parseFormula:(GDataXMLElement*)element
{
    NSArray* formulaTrees = [element elementsForName:@"formulaTree"];
    if(formulaTrees) {
        GDataXMLElement* formulaTree = [formulaTrees objectAtIndex:0];
        FormulaElement* formulaElement = [self parseFormulaElement:formulaTree];
        
        Formula* formula = [[Formula alloc] init];
        formula.formulaTree = formulaElement;
        
        return formula;

    }
    else {
        [NSException raise:@"FormulaElementNotFoundException" format:@"Tried to parse Formula, but formula tag not found!"];
        return nil;
    }
}

-(id) parseVariablesContainer:(GDataXMLElement*)element withParent:(XMLObjectReference*)parent
{
    
    VariablesContainer* variables = nil;
    
    if (self.program) {
        
        variables = [[VariablesContainer alloc] init];
        
        NSArray* objectVariableListArray= [element elementsForName:@"objectVariableList"];
        
        XMLObjectReference* ref = [[XMLObjectReference alloc] initWithParent:parent andObject:variables];
        
        if(objectVariableListArray) {
            GDataXMLElement* objectVariableList = [objectVariableListArray objectAtIndex:0];
            variables.objectVariableList = [self parseObjectVariableMap:objectVariableList andParent:ref];
        }
        
        NSArray* programVariableListArray = [element elementsForName:@"programVariableList"];

        if(programVariableListArray) {
            GDataXMLElement* programVariableList  = [programVariableListArray objectAtIndex:0];
            variables.programVariableList = [self parseProgramVariableList:programVariableList andParent:ref];
        }
    }

    
    return variables;

}

-(id) parseReferenceElement:(GDataXMLElement*)element withParent:(XMLObjectReference*)parent
{
    NSString *refString = [element attributeForName:@"reference"].stringValue;
    if (!refString || [refString isEqualToString:@""]) {
        [NSException raise:@"ReferenceException" format:@"Tried to parse Reference Element, but no refString was found!"];
    }
    
    NSArray *components = [refString componentsSeparatedByString:@"/"];
    
    id lastComponent = [self parentObjectForReferenceElement:element andParent:parent];
    
    for(int i=0; i<[components count]; i++) {
        
        NSString* pathComponent = [components objectAtIndex:i];
        if([pathComponent isEqualToString:@".."]) {
            continue;
        }
        
        
        objc_property_t property = class_getProperty([lastComponent class], [pathComponent UTF8String]);
        if (property) {
            lastComponent = [lastComponent valueForKey:pathComponent];            
        }
        

        else if([pathComponent hasPrefix:@"object"]) {
            
            int index = [self indexForArrayObject:pathComponent];
            
            if (index+1 > [lastComponent count] || index < 0) {
                [NSException raise:@"IndexOutOfBoundsException" format:@"IndexOutOfBounds for lastComponent!"];
            }
            
            lastComponent = [lastComponent objectAtIndex:index];
        }
        else if([pathComponent hasPrefix:@"entry"]) {
            int index = [self indexForArrayObject:pathComponent];
            
            if (index+1 > [lastComponent count] || index < 0) {
                [NSException raise:@"IndexOutOfBoundsException" format:@"IndexOutOfBounds for lastComponent!"];
            }
            
            i++;
            pathComponent = [components objectAtIndex:i];
            
            if([pathComponent isEqualToString:@"object"]) {
                lastComponent = [lastComponent keyAtIndex:index];
            }
            else {
                lastComponent = [lastComponent objectAtIndex:index];
            }
        }
        else if([self component:pathComponent containsString:@"Brick"] || [self component:pathComponent containsString:@"Script"]) {
            
            NSMutableArray* lastComponentList = lastComponent;
            
            NSString* className = [[self stripArrayBrackets:pathComponent] capitalizedString];
            NSMutableArray* list = [[NSMutableArray alloc] init];
            for (id obj in lastComponentList)
            {
                if ([obj isMemberOfClass:NSClassFromString(className)])
                    [list addObject:obj];
            }
            
            int index = [self indexForArrayObject:pathComponent];
            
            if (index+1 > [list count] || index < 0) {
[NSException raise:@"IndexOutOfBoundsException" format:@"IndexOutOfBounds for lastComponent!"];
            }
            
            lastComponent = [list objectAtIndex:index];
                        
        }
        else {
            [NSException raise:@"UnknownPathComponentException" format:@"UNKNOWN Path Component: %@", pathComponent];
        }

        
    }
    
    if(lastComponent == nil) {
        NSWarn(@"LastComponent is nil: %@", refString);
    }
    
    return lastComponent;
}



-(OrderedMapTable*)parseObjectVariableMap:(GDataXMLElement*)objectVariableList andParent:(XMLObjectReference*)parent
{
    
    OrderedMapTable* objectVariableMap = [OrderedMapTable strongToStrongObjectsMapTable];
    XMLObjectReference* ref = [[XMLObjectReference alloc] initWithParent:parent andObject:objectVariableMap];
    
    for (GDataXMLElement *entry in objectVariableList.children) {
        
        
        GDataXMLElement* objectElement = [[entry elementsForName:@"object"] objectAtIndex:0];
        SpriteObject* object = nil;
        
        XMLObjectReference* entryRef = [[XMLObjectReference alloc] initWithParent:ref andObject:nil];
        
        if([self isReferenceElement:objectElement]) {
            object = [self parseReferenceElement:objectElement withParent:entryRef];
        }
        else {
            object = [self parseNode:objectElement withParent:entryRef];
        }
        
        NSArray* listArray = [entry elementsForName:@"list"];
        GDataXMLElement* listElement = [listArray objectAtIndex:0];
        
        NSMutableArray* list = [[NSMutableArray alloc] initWithCapacity:listElement.childCount];
        
        XMLObjectReference* listReference = [[XMLObjectReference alloc] initWithParent:entryRef andObject:list];
        
        for(GDataXMLElement* var in listElement.children) {
            
            Uservariable* userVariable = nil;
            if([self isReferenceElement:var]) {
                userVariable = [self parseReferenceElement:var withParent:listReference];
            }
            else {
                userVariable = [self parseNode:var withParent:listReference];
            }
            [list addObject:userVariable];
        }
        
        [objectVariableMap setObject:list forKey:object];
    }
    
    return objectVariableMap;
    
}

-(NSMutableArray*)parseProgramVariableList:(GDataXMLElement*)progList andParent:(XMLObjectReference*)parent
{
    NSMutableArray* programVariableList = [[NSMutableArray alloc] initWithCapacity:progList.childCount];
    XMLObjectReference* programVariableRef = [[XMLObjectReference alloc] initWithParent:parent andObject:programVariableList];
    for (GDataXMLElement *entry in progList.children) {
        Uservariable* var = nil;
        if([self isReferenceElement:entry]) {
            var = [self parseReferenceElement:entry withParent:programVariableRef];
        }
        else {
            var = [self parseNode:entry withParent:programVariableRef];
        }
        [programVariableList addObject:var];
    
    }

    return programVariableList;
    
}


-(FormulaElement*)parseFormulaElement:(GDataXMLElement*)element
{
    NSArray* valueArray = [element elementsForName:@"value"];
    NSArray* typeArray = [element elementsForName:@"type"];
    NSArray* rightChildArray = [element elementsForName:@"rightChild"];
    NSArray* leftChildArray = [element elementsForName:@"leftChild"];
    
    NSString* type = ((GDataXMLElement*)[typeArray objectAtIndex:0]).stringValue;
    NSString* value = ((GDataXMLElement*)[valueArray objectAtIndex:0]).stringValue;
    FormulaElement* leftChild = nil;
    FormulaElement* rightChild = nil;
    
    if(leftChildArray) {
        leftChild = [self parseFormulaElement:[leftChildArray objectAtIndex:0]];
    }
    if(rightChildArray) {
        rightChild = [self parseFormulaElement:[rightChildArray objectAtIndex:0]];
    }
    
    FormulaElement* parent = nil;
#warning to we really need a parent?!
    
    FormulaElement* formulaElement = [[FormulaElement alloc] initWithType:type
                                                                    value:value
                                                                leftChild:leftChild
                                                               rightChild:rightChild
                                                                   parent:parent];
    
    return formulaElement;
    
    
}





#pragma mark - Helper

const char* property_getTypeString(objc_property_t property) {
	const char *attrs = property_getAttributes(property);
	if (attrs == NULL) { return NULL; }
	
	static char buffer[256];
	const char *e = strchr(attrs, ',');
	if (e == NULL) { return NULL; }
	
	int len = (int)(e - attrs);
	memcpy(buffer, attrs, len);
	buffer[len] = '\0';
	
	return buffer;
}



-(BOOL) isReferenceElement:(GDataXMLElement*)element
{
    NSString *refString = [element attributeForName:@"reference"].stringValue;
    if (!refString || [refString isEqualToString:@""]) {
        return NO;
    }
    return YES;
}


-(id)parentObjectForReferenceElement:(GDataXMLElement*)element andParent:(XMLObjectReference*)parent
{
    NSString *refString = [element attributeForName:@"reference"].stringValue;    
    int count = [self numberOfOccurencesOfSubstring:@".." inString:refString];
    
    XMLObjectReference* tmp = parent;
    
    for(int i=0; i<count-1; i++) {
        tmp = tmp.parent;
    }
        
    return tmp.object;
    
}



-(int)numberOfOccurencesOfSubstring:(NSString*)substring inString:(NSString*)str
{
    int cnt = 0;
    int length = [str length];
    NSRange range = NSMakeRange(0, length);
    while(range.location != NSNotFound)
    {
        range = [str rangeOfString:substring options:0 range:range];
        if(range.location != NSNotFound)
        {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            cnt++; 
        }
    }
    return cnt;
    
}


-(BOOL) component:(NSString*)component containsString:(NSString*)stringToCheck
{
    NSString* pattern = [NSString stringWithFormat:@"[a-zA-Z]*%@(\\[[0-9]+\\])*", stringToCheck];
    NSError* error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    int matches = [regex numberOfMatchesInString:component options:0 range:NSMakeRange(0, [component length])];
    if(matches == 1) {
        return YES;
    }
    return NO;
}


-(NSString*) stripArrayBrackets:(NSString*)stringToStrip
{
    NSError* error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[a-zA-Z]*" options:0 error:&error];
    NSArray* matches = [regex matchesInString:stringToStrip options:0 range:NSMakeRange(0, [stringToStrip length])];
    if(matches) {
        return [stringToStrip substringWithRange:[[matches objectAtIndex:0] range]];
    }
    return stringToStrip;
}

-(int) indexForArrayObject:(NSString*)arrayObject
{
    int index = -1;
    if([arrayObject hasSuffix:@"]"]) {
        NSRange begin = [arrayObject rangeOfString:@"["];
        NSRange end = [arrayObject rangeOfString:@"]"];
        int length= end.location - begin.location - begin.length;
        int location = begin.location + begin.length;
        NSRange indexRange = NSMakeRange(location, length);
        NSString *indexString = [arrayObject substringWithRange:indexRange];
        index = indexString.integerValue;
        index--;
    }
    else {
        index = 0;
    }
    
    return index;
}




@end
