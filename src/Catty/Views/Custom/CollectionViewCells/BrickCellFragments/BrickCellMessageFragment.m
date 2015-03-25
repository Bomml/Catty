/**
 *  Copyright (C) 2010-2015 The Catrobat Team
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


#import "BrickCellMessageFragment.h"
#import "iOSCombobox.h"
#import "BrickCell.h"
#import "Script.h"
#import "Brick.h"
#import "BrickTextProtocol.h"
#import "LooksTableViewController.h"
#import "LanguageTranslationDefines.h"
#import "BroadcastScript.h"
#import "BroadcastBrick.h"
#import "BroadcastWaitBrick.h"

@interface BrickCellMessageFragment()
@property (nonatomic, weak) BrickCell *brickCell;
@property (nonatomic) NSInteger lineNumber;
@property (nonatomic) NSInteger parameterNumber;
@end

@implementation BrickCellMessageFragment

static NSMutableArray *messages = nil;

- (instancetype)initWithFrame:(CGRect)frame andBrickCell:(BrickCell*)brickCell andLineNumber:(NSInteger)line andParameterNumber:(NSInteger)parameter
{
    if(self = [super initWithFrame:frame]) {
        _brickCell = brickCell;
        _lineNumber = line;
        _parameterNumber = parameter;
        NSMutableArray *options = [[NSMutableArray alloc] init];
        [options addObject:kLocalizedNewElement];
        int currentOptionIndex = 0;
        int optionIndex = 1;
        if([brickCell.scriptOrBrick conformsToProtocol:@protocol(BrickMessageProtocol)]) {
            Brick<BrickMessageProtocol> *messageBrick = (Brick<BrickMessageProtocol>*)brickCell.scriptOrBrick;
            NSString *currentMessage = [messageBrick messageForLineNumber:line andParameterNumber:parameter];
            for(NSString *message in [self messages]) {
                if(![options containsObject:message]) {
                    [options addObject:message];
                    if([message isEqualToString:currentMessage])
                        currentOptionIndex = optionIndex;
                    optionIndex++;
                }
            }
        }
        [self setValues:options];
        [self setCurrentValue:options[currentOptionIndex]];
        [self setDelegate:(id<iOSComboboxDelegate>)self];
    }
    return self;
}

- (void)comboboxClosed:(iOSCombobox*)combobox withValue:(NSString*)value
{
    [self.brickCell.fragmentDelegate updateData:value forBrick:(Brick*)self.brickCell.scriptOrBrick andLineNumber:self.lineNumber andParameterNumber:self.parameterNumber];
}

- (NSMutableArray*)messages
{
    if (messages == nil)
    {
        messages = [[NSMutableArray alloc] init];
        Brick *currentBrick = (Brick*)self.brickCell.scriptOrBrick;
        for(SpriteObject *object in currentBrick.script.object.program.objectList) {
            for(Script *script in object.scriptList) {
                if([script isKindOfClass:[BroadcastScript class]]) {
                    BroadcastScript *broadcastScript = (BroadcastScript*)script;
                    [messages addObject:broadcastScript.receivedMessage];
                }
                for(Brick *brick in script.brickList) {
                    if([brick isKindOfClass:[BroadcastBrick class]]) {
                        BroadcastBrick *broadcastBrick = (BroadcastBrick*)brick;
                        [messages addObject:broadcastBrick.broadcastMessage];
                    } else if([brick isKindOfClass:[BroadcastWaitBrick class]]) {
                        BroadcastWaitBrick *broadcastBrick = (BroadcastWaitBrick*)brick;
                        [messages addObject:broadcastBrick.broadcastMessage];
                    }
                }
            }
        }
    }
    
    return messages;
}

- (void)addMessage:(NSString*)message
{
    [[self messages] addObject:message];
}

+ (void)resetMessages
{
    messages = nil;
}

+ (NSArray*)allMessages
{
    return messages;
}

@end
