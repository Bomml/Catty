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
#import <objc/runtime.h>
#import <Foundation/NSObjCRuntime.h>
#import "Sound.h"
#import "Formula.h"
#import "FormulaElement.h"


// test
#import "SpriteObject.h"


#define kCatroidXMLPrefix               @"org.catrobat.catroid.content."
#define kCatroidXMLSpriteList           @"spriteList"
#define kParserObjectTypeString         @"T@\"NSString\""
#define kParserObjectTypeNumber         @"T@\"NSNumber\""
#define kParserObjectTypeArray          @"T@\"NSArray\""
#define kParserObjectTypeMutableArray   @"T@\"NSMutableArray\""
#define kParserObjectTypeDate           @"T@\"NSDate\""

// TODO: fix the user defined warnings below and remove this in final version
#define kParserObjectTypeSprite         @"T@\"SpriteObject\""
#define kParserObjectTypeLookData       @"T@\"Look\""
#define kParserObjectTypeLoopEndBrick   @"T@\"Loopendbrick\""
#define kParserObjectTypeSound          @"T@\"Sound\""
#define kParserObjectTypeHeader         @"T@\"Header\""
#define kParserObjectTypeUserVariable   @"T@\"Uservariable\""
#define kParserObjectTypeFormula        @"T@\"Formula\""


@interface ProjectParser()

- (id)parseNode:(GDataXMLElement*)node;
- (id)getSingleValue:(GDataXMLElement*)element ofType:(NSString*)propertyType;

// just temp
//#error todo
/*@property (nonatomic, strong) NSMutableDictionary *lookDict;
@property (nonatomic, strong) NSString *path;*/
@property (nonatomic, strong) id currentActiveSprite;

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
    return [self parseNode:doc.rootElement];
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
- (id)parseNode:(GDataXMLElement*)node {
    // sanity check
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
    
    if ([className isEqualToString:@"Object"]) {
        // ... introspect from "Object"... glory idea...
        // I'm so proud of you XML Team...
        className = @"SpriteObject";
    }
    
    id object = [[NSClassFromString(className) alloc] init];
    if (!object) {
        NSLog(@"Implementation of <%@> NOT FOUND!", className);
        abort(); // TODO: just for debug
    }
        
    // just an educated gues...
    if ([object isKindOfClass:[SpriteObject class]]) {
        self.currentActiveSprite = object;
    }
    
    for (GDataXMLElement *child in node.children) {
        // maybe check node.childCount == 0?
        
        objc_property_t property = class_getProperty([object class], [child.name UTF8String]);
        if (property) { // check if property exists
            NSString *propertyType = [NSString stringWithUTF8String:property_getTypeString(property)];
            NSLog(@"Property type: %@", propertyType);
                        
            // check if property is of type array
            if ([propertyType isEqualToString:kParserObjectTypeArray]
                || [propertyType isEqualToString:kParserObjectTypeMutableArray]) {
                // = ARRAY
                // create new array
                NSMutableArray *arr = [[NSMutableArray alloc] init];
                for (GDataXMLElement *arrElement in child.children) {
                    [arr addObject:[self parseNode:arrElement]];
                }
                
                // now set the array property (from *arr)
                [object setValue:arr forKey:child.name];
            }
            else {
                // NOT ARRAY
                // now set the value
                id value = [self getSingleValue:child ofType:propertyType]; // get value for type
                
                
                if([child.name isEqualToString:@"timeToWaitInSeconds"])
                {
                    NSLog(@"Now");
                }
                
                // check for property type
                [object setValue:value forKey:child.name]; // assume new value
            }
        }
        else {
            NSLog(@"property <%@> does NOT exist in our implementation of <%@>", child.name, className);
            abort(); // PROPERTY IN IMPLEMENTATION NOT FOUND!!!
            // THIS SHOULD _NOT_ HAPPEN!
            // IF THIS HAPPENS, we have forgotten to implement a property in our classes
            // Check the XML file and search for differences to our implementation
            // You can see the property which we've to implement by typing 'po child.name' in gdb
        }
    }
    
    // return new object
    return object;
}



// -----------------------------------------------------------------------------
// getSingleValue:ofType:
// This method extracts a single value of a given GDataXMLElement for the
// corresponding (given) type, such as NSString, NSArray and so on.
- (id)getSingleValue:(GDataXMLElement*)element ofType:(NSString*)propertyType {
    // sanity checks
    if (!element || !propertyType) { return nil; }
    
    
    // check type
    if ([propertyType isEqualToString:kParserObjectTypeString]) {
        return element.stringValue;
    }
    else if ([propertyType isEqualToString:kParserObjectTypeNumber]) {
#warning Workaround until Formula editor is fully supported!
        NSString *temp = nil;
        NSArray* formulaTrees = [element elementsForName:@"formulaTree"];
        if(formulaTrees) {
            GDataXMLElement* formulaTree = [formulaTrees objectAtIndex:0];
            NSArray* rightChildArray = [formulaTree elementsForName:@"rightChild"];
            NSArray* values = nil;
            if(rightChildArray) {
                GDataXMLElement* rightChild = [rightChildArray objectAtIndex:0];
                values = [rightChild elementsForName:@"value"];
                temp = [[values objectAtIndex:0] stringValue];
                NSArray* opCodeArray = [formulaTree elementsForName:@"value"];
                if(opCodeArray) {
                    NSString* opCode = [[opCodeArray objectAtIndex:0] stringValue];
                    if([opCode isEqualToString:@"MINUS"]) {
                        temp = [NSString stringWithFormat:@"-%@", temp];
                    }
                }
                
            } else {
                NSArray* values = [formulaTree elementsForName:@"value"];
                temp = [[values objectAtIndex:0] stringValue];
            }
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
        NSString *ref = [element attributeForName:@"reference"].stringValue;
        NSLog(@"NSOBJECT TYPE FOUND");
        NSLog(@"   SET reference (%@) for %@", ref, element.name);
        NSLog(@"   RETURNING SPRITE %@", self.currentActiveSprite);
        return self.currentActiveSprite;
    }
    else if ([propertyType isEqualToString:kParserObjectTypeLookData]) {
        // sanity check
        if (self.currentActiveSprite && [self.currentActiveSprite isKindOfClass:[SpriteObject class]]) {
            SpriteObject *sprite = (SpriteObject*)self.currentActiveSprite;
            NSString *refString = [element attributeForName:@"reference"].stringValue;
            if (!refString || [refString isEqualToString:@""]) {
                // SHOULD NOT HAPPEN!
                // IF YOU ARE HERE, this means, that in the XML there has no reference been set
                // for this tag.
                // SHOULD BE: (i.e.) <look reference="../../../../../lookList/org.catrobat.catroid.common.LookData"/>
                // BUT WAS: <look reference=""/>
                abort(); // todo
            }
            
            
            NSLog(@"NSOBJECT TYPE FOUND");
            NSLog(@"   SET reference (%@) for %@", refString, element.name);
            
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
        NSLog(@"NSOBJECT TYPE FOUND");
        NSLog(@"   SET reference (%@) for %@", ref, element.name);
        
        Sound *sound = [self parseNode:element];
        
        
        return sound; // TODO!
    }
    else if ([propertyType isEqualToString:kParserObjectTypeHeader]) {
        return [self parseNode:element];
    }
    else if ([propertyType isEqualToString:kParserObjectTypeLoopEndBrick]) {
#warning todo
        return nil;
    }
    else if([propertyType isEqualToString:kParserObjectTypeUserVariable]) {
        return [self parseNode:element];
    }
    else if([propertyType isEqualToString:kParserObjectTypeFormula]) {
        NSDebug(@"Formula");
        [self parseFormula:element];
    }
    else {
        abort(); // TODO: just for debug purposes
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
        NSLog(@"Formula could not be found!");
        abort();
#warning debug! remove
        return nil;
    }
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
        rightChild = [self parseFormulaElement:[leftChildArray objectAtIndex:0]];
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



// -----------------------------------------------------------------------------
//                                   HELPER
// -----------------------------------------------------------------------------
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

@end
