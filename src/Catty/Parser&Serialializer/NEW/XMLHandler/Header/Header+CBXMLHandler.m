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

#import "Header+CBXMLHandler.h"
#import "GDataXMLElement+CustomExtensions.h"
#import "CBXMLValidator.h"
#import "CBXMLParserHelper.h"
#import "CatrobatLanguageDefines.h"
#import "CBXMLSerializer.h"

@implementation Header (CBXMLHandler)

+ (instancetype)parseFromElement:(GDataXMLElement*)xmlElement withContext:(CBXMLContext*)context
{
    [XMLError exceptionIfNil:xmlElement message:@"No xml element given!"];
    Header *header = [self defaultHeader];
    NSArray *headerPropertyNodes = [xmlElement children];
    [XMLError exceptionIf:[headerPropertyNodes count] equals:0 message:@"No parsed properties found in header!"];
    
    for (GDataXMLNode *headerPropertyNode in headerPropertyNodes) {
        [XMLError exceptionIfNil:headerPropertyNode message:@"Parsed an empty header entry!"];
        id value = [CBXMLParserHelper valueForHeaderPropertyNode:headerPropertyNode];
        NSString *headerPropertyName = headerPropertyNode.name;
        
        // consider special case: name of property programDescription
        if ([headerPropertyNode.name isEqualToString:@"description"]) {
            headerPropertyName = @"programDescription";
        }
        [header setValue:value forKey:headerPropertyName]; // Note: weak properties are not yet supported!!
    }
    return header;
}

- (GDataXMLElement*)xmlElementWithContext:(CBXMLContext*)context
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateFormat:kCatrobatHeaderDateTimeFormat];
    
    GDataXMLElement *headerXMLElement = [GDataXMLElement elementWithName:@"header" context:context];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"applicationBuildName"
                                                    stringValue:self.applicationBuildName context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"applicationBuildNumber"
                                                    stringValue:self.applicationBuildNumber context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"applicationName"
                                                    stringValue:self.applicationName context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"applicationVersion"
                                                    stringValue:self.applicationVersion context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"catrobatLanguageVersion"
                                                    stringValue:kCBXMLSerializerLanguageVersion context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"dateTimeUpload"
                                                    stringValue:(self.dateTimeUpload ? [dateFormatter stringFromDate:self.dateTimeUpload] : nil) context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"description"
                                                    stringValue:self.programDescription context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"deviceName"
                                                    stringValue:self.deviceName context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"mediaLicense"
                                                    stringValue:self.mediaLicense context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"platform"
                                                    stringValue:self.platform context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"platformVersion"
                                                    stringValue:self.platformVersion context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"programLicense"
                                                    stringValue:self.programLicense context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"programName"
                                                    stringValue:self.programName context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"remixOf"
                                                    stringValue:self.remixOf context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"screenHeight"
                                                    stringValue:[self.screenHeight stringValue] context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"screenWidth"
                                                    stringValue:[self.screenWidth stringValue] context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"screenMode"
                                                    stringValue:self.screenMode context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"tags"
                                                    stringValue:self.tags context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"url"
                                                    stringValue:self.url context:context]];
    [headerXMLElement addChild:[GDataXMLElement elementWithName:@"userHandle"
                                                    stringValue:self.userHandle context:context]];
    return headerXMLElement;
}

@end
