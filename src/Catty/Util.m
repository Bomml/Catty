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

#import "Util.h"
#import "ScenePresenterViewController.h"
#import "ProgramDefines.h"
#import "ProgramLoadingInfo.h"
#import "UIDefines.h"
#import "LanguageTranslationDefines.h"
#import "CatrobatAlertView.h"
#import "CatrobatActionSheet.h"
#import "UIColor+CatrobatUIColorExtensions.h"
#import "ActionSheetAlertViewTags.h"
#import "DataTransferMessage.h"
#import "UIImage+CatrobatUIImageExtensions.h"
#import "EAIntroView.h"

@interface Util () <CatrobatAlertViewDelegate, UITextFieldDelegate>

@end

@implementation Util

+ (BOOL)activateTestMode:(BOOL)activate
{
    static BOOL alreadyActive = NO;
    if (activate) {
        alreadyActive = YES;
    }
    return alreadyActive;
}

+ (NSString *)applicationDocumentsDirectory
{    
    NSArray *paths = 
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;

}

+ (void)showComingSoonAlertView
{
    CatrobatAlertView *alert = [[CatrobatAlertView alloc] initWithTitle:kLocalizedPocketCode
                                                                message:kLocalizedThisFeatureIsComingSoon
                                                               delegate:nil
                                                      cancelButtonTitle:kLocalizedOK
                                                      otherButtonTitles:nil];
    if (! [self activateTestMode:NO]) {
        [alert show];
    }
}

+ (void)showIntroductionScreenInView:(UIView *)view delegate:(id<EAIntroDelegate>)delegate
{
    UIImage *bgImage = [UIImage imageWithColor:[UIColor darkBlueColor]];
    EAIntroPage *page1 = [EAIntroPage page];
    page1.title = kLocalizedWelcomeToPocketCode;
    page1.desc = kLocalizedWelcomeDescription;
    page1.bgImage = bgImage;
    page1.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"page1_logo"]];

    EAIntroPage *page2 = [EAIntroPage page];
    page2.title = kLocalizedExploreApps;
    page2.desc = kLocalizedExploreDescription;
    page2.bgImage = bgImage;
    page2.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"page2_explore"]];

    EAIntroPage *page3 = [EAIntroPage page];
    page3.title = kLocalizedUpcomingVersion;
    page3.desc = kLocalizedUpcomingVersionDescription;
    page3.bgImage = bgImage;
    page3.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"page3_info"]];

    CGRect frame = view.frame;
    frame.size.height -= 64.0f;
    EAIntroView *intro = [[EAIntroView alloc] initWithFrame:frame andPages:@[page1, page2, page3]];
    intro.delegate = delegate;
    [intro showInView:view animateDuration:0.3f];
}

+ (CatrobatAlertView*)alertWithText:(NSString*)text
{
    return [self alertWithText:text delegate:nil tag:0];
}

+ (CatrobatAlertView*)alertWithText:(NSString*)text
                           delegate:(id<CatrobatAlertViewDelegate>)delegate
                                tag:(NSInteger)tag
{
    CatrobatAlertView *alertView = [[CatrobatAlertView alloc] initWithTitle:kLocalizedPocketCode
                                                                    message:text
                                                                   delegate:delegate
                                                          cancelButtonTitle:kLocalizedOK
                                                          otherButtonTitles:nil];
    alertView.tag = tag;
    if (! [self activateTestMode:NO]) {
        [alertView show];
    }
    return alertView;
}

+ (CatrobatAlertView*)confirmAlertWithTitle:(NSString*)title
                                    message:(NSString*)message
                                   delegate:(id<CatrobatAlertViewDelegate>)delegate
                                        tag:(NSInteger)tag
{
    CatrobatAlertView *alertView = [[CatrobatAlertView alloc] initWithTitle:title
                                                                    message:message
                                                                   delegate:delegate
                                                          cancelButtonTitle:kLocalizedNo
                                                          otherButtonTitles:nil];
    [alertView addButtonWithTitle:kLocalizedYes];
    alertView.tag = tag;
    if (! [self activateTestMode:NO]) {
        [alertView show];
    }
    return alertView;
}

+ (CatrobatAlertView*)promptWithTitle:(NSString*)title
                              message:(NSString*)message
                             delegate:(id<CatrobatAlertViewDelegate>)delegate
                          placeholder:(NSString*)placeholder
                                  tag:(NSInteger)tag
                    textFieldDelegate:(id<UITextFieldDelegate>)textFieldDelegate
{
    return [Util promptWithTitle:title
                         message:message
                        delegate:delegate
                     placeholder:placeholder
                             tag:tag
                           value:nil
               textFieldDelegate:textFieldDelegate];
}

+ (CatrobatAlertView*)promptWithTitle:(NSString*)title
                              message:(NSString*)message
                             delegate:(id<CatrobatAlertViewDelegate>)delegate
                          placeholder:(NSString*)placeholder
                                  tag:(NSInteger)tag
                                value:(NSString*)value
                    textFieldDelegate:(id<UITextFieldDelegate>)textFieldDelegate
{
    CatrobatAlertView *alertView = [[CatrobatAlertView alloc] initWithTitle:title
                                                                    message:message
                                                                   delegate:delegate
                                                          cancelButtonTitle:kLocalizedCancel
                                                          otherButtonTitles:kLocalizedOK, nil];
    alertView.tag = tag;
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = placeholder;
    [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
    textField.text = value;
    textField.delegate = textFieldDelegate;
    textField.returnKeyType = UIReturnKeyDone;
    catrobatAlertView = alertView;
    if (! [self activateTestMode:NO]) {
        [alertView show];
    }
    return alertView;
}

+ (CatrobatActionSheet*)actionSheetWithTitle:(NSString*)title
                                    delegate:(id<CatrobatActionSheetDelegate>)delegate
                      destructiveButtonTitle:(NSString*)destructiveButtonTitle
                           otherButtonTitles:(NSArray*)otherButtonTitles
                                         tag:(NSInteger)tag
                                        view:(UIView*)view
{
    CatrobatActionSheet *actionSheet = [[CatrobatActionSheet alloc] initWithTitle:title
                                                                         delegate:delegate
                                                                cancelButtonTitle:kLocalizedCancel
                                                           destructiveButtonTitle:destructiveButtonTitle
                                                           otherButtonTitlesArray:otherButtonTitles];
//    [actionSheet setButtonBackgroundColor:[UIColor colorWithWhite:0.0f alpha:1.0f]];
//    [actionSheet setButtonTextColor:[UIColor lightOrangeColor]];
//    [actionSheet setButtonTextColor:[UIColor redColor] forButtonAtIndex:0];
    actionSheet.transparentView.alpha = 1.0f;

//    if (destructiveButtonTitle) {
//        [actionSheet addDestructiveButtonWithTitle:destructiveButtonTitle];
//    }
//    for (id otherButtonTitle in otherButtonTitles) {
//        if ([otherButtonTitle isKindOfClass:[NSString class]]) {
//            [actionSheet addButtonWithTitle:otherButtonTitle];
//        }
//    }
//    [actionSheet addCancelButtonWithTitle:kLocalizedCancel];

    actionSheet.tag = tag;
    if (! [self activateTestMode:NO]) {
        [actionSheet showInView:view];
    }
    return actionSheet;
}

+ (UIButton*)slideViewButtonWithTitle:(NSString*)title backgroundColor:(UIColor*)backgroundColor
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = backgroundColor;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    return button;
}

+ (UIButton*)slideViewButtonMore
{
    return [Util slideViewButtonWithTitle:kLocalizedMore
                          backgroundColor:[UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]];
}

+ (UIButton*)slideViewButtonDelete
{
    return [Util slideViewButtonWithTitle:kLocalizedDelete
                          backgroundColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188f alpha:1.0f]];
}

+ (NSString*)getProjectName
{
  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  return [NSString stringWithFormat:@"%@", [info objectForKey:@"CFBundleDisplayName"]];
}

+ (NSString*)getProjectVersion
{
  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  return [NSString stringWithFormat:@"%@", [info objectForKey:@"CFBundleVersion"]];
}

+ (NSString*)getDeviceName
{
  return [[UIDevice currentDevice] model];
}

+ (NSString*)getPlatformName
{
  return [[UIDevice currentDevice] systemName];
}

+ (NSString*)getPlatformVersion
{
  return [[UIDevice currentDevice] systemVersion];
}

+ (CGFloat)getScreenHeight
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    return screenRect.size.height;
}

+ (CGFloat)getScreenWidth
{
  CGRect screenRect = [[UIScreen mainScreen] bounds];
  return screenRect.size.width;
}

+ (CATransition*)getPushCATransition
{
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    return transition;
}

+ (ProgramLoadingInfo*)programLoadingInfoForProgramWithName:(NSString*)program
{
    NSString *documentsDirectory = [Util applicationDocumentsDirectory];
    NSString *programsPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, kProgramsFolder];
    ProgramLoadingInfo *info = [[ProgramLoadingInfo alloc] init];
    info.basePath = [NSString stringWithFormat:@"%@/%@/", programsPath, program];
    info.visibleName = program;
    return info;
}

+ (NSString*)lastProgram
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* lastProgram = [userDefaults objectForKey:kLastProgram];
    if (! lastProgram) {
        [userDefaults setObject:kLocalizedMyFirstProgram forKey:kLastProgram];
        [userDefaults synchronize];
        lastProgram = kLocalizedMyFirstProgram;
    }
    return lastProgram;
}

+ (void)setLastProgram:(NSString*)visibleName
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:visibleName forKey:kLastProgram];
    [userDefaults synchronize];
}

+ (void)askUserForUniqueNameAndPerformAction:(SEL)action
                                      target:(id)target
                                 promptTitle:(NSString*)title
                               promptMessage:(NSString*)message
                                 promptValue:(NSString*)value
                           promptPlaceholder:(NSString*)placeholder
                              minInputLength:(NSUInteger)minInputLength
                              maxInputLength:(NSUInteger)maxInputLength
                         blockedCharacterSet:(NSCharacterSet*)blockedCharacterSet
                    invalidInputAlertMessage:(NSString*)invalidInputAlertMessage
                               existingNames:(NSArray*)existingNames
{
    [self askUserForUniqueNameAndPerformAction:action
                                        target:target
                                    withObject:nil
                                   promptTitle:title
                                 promptMessage:message
                                   promptValue:value
                             promptPlaceholder:placeholder
                                minInputLength:minInputLength
                                maxInputLength:maxInputLength
                           blockedCharacterSet:blockedCharacterSet
                      invalidInputAlertMessage:invalidInputAlertMessage
                                 existingNames:existingNames];
}

+ (void)askUserForUniqueNameAndPerformAction:(SEL)action
                                      target:(id)target
                                  withObject:(id)passingObject
                                 promptTitle:(NSString*)title
                               promptMessage:(NSString*)message
                                 promptValue:(NSString*)value
                           promptPlaceholder:(NSString*)placeholder
                              minInputLength:(NSUInteger)minInputLength
                              maxInputLength:(NSUInteger)maxInputLength
                         blockedCharacterSet:(NSCharacterSet*)blockedCharacterSet
                    invalidInputAlertMessage:(NSString*)invalidInputAlertMessage
                               existingNames:(NSArray*)existingNames;
{
    textFieldMaxInputLength = maxInputLength;
    textFieldBlockedCharacterSet = blockedCharacterSet;

    NSDictionary *payload = @{
        kDTPayloadAskUserAction : [NSValue valueWithPointer:action],
        kDTPayloadAskUserTarget : target,
        kDTPayloadAskUserObject : (passingObject ? passingObject : [NSNull null]),
        kDTPayloadAskUserPromptTitle : title,
        kDTPayloadAskUserPromptMessage : message,
        kDTPayloadAskUserPromptValue : (value ? value : [NSNull null]),
        kDTPayloadAskUserPromptPlaceholder : placeholder,
        kDTPayloadAskUserMinInputLength : @(minInputLength),
        kDTPayloadAskUserInvalidInputAlertMessage : invalidInputAlertMessage,
        kDTPayloadAskUserExistingNames : (existingNames ? existingNames : [NSNull null])
    };
    CatrobatAlertView *alertView = [[self class] promptWithTitle:title
                                                         message:message
                                                        delegate:(id<CatrobatAlertViewDelegate>)self
                                                     placeholder:kLocalizedEnterYourProgramNameHere
                                                             tag:kAskUserForUniqueNameAlertViewTag
                                                           value:value
                                               textFieldDelegate:(id<UITextFieldDelegate>)self];
    alertView.dataTransferMessage = [DataTransferMessage messageForActionType:kDTMActionAskUserForUniqueName
                                                                  withPayload:[payload mutableCopy]];
}

+ (void)askUserForTextAndPerformAction:(SEL)action
                                target:(id)target
                           promptTitle:(NSString*)title
                         promptMessage:(NSString*)message
                           promptValue:(NSString*)value
                     promptPlaceholder:(NSString*)placeholder
                        minInputLength:(NSUInteger)minInputLength
                        maxInputLength:(NSUInteger)maxInputLength
                   blockedCharacterSet:(NSCharacterSet*)blockedCharacterSet
              invalidInputAlertMessage:(NSString*)invalidInputAlertMessage
{
    [self askUserForTextAndPerformAction:action
                                  target:target
                              withObject:nil
                             promptTitle:title
                           promptMessage:message
                             promptValue:value
                       promptPlaceholder:placeholder
                          minInputLength:minInputLength
                          maxInputLength:maxInputLength
                     blockedCharacterSet:blockedCharacterSet
                invalidInputAlertMessage:invalidInputAlertMessage];
}

+ (void)askUserForTextAndPerformAction:(SEL)action
                                target:(id)target
                            withObject:(id)passingObject
                           promptTitle:(NSString*)title
                         promptMessage:(NSString*)message
                           promptValue:(NSString*)value
                     promptPlaceholder:(NSString*)placeholder
                        minInputLength:(NSUInteger)minInputLength
                        maxInputLength:(NSUInteger)maxInputLength
                   blockedCharacterSet:(NSCharacterSet*)blockedCharacterSet
              invalidInputAlertMessage:(NSString*)invalidInputAlertMessage
{
    [self askUserForUniqueNameAndPerformAction:action
                                        target:target
                                    withObject:passingObject
                                   promptTitle:title
                                 promptMessage:message
                                   promptValue:value
                             promptPlaceholder:placeholder
                                minInputLength:minInputLength
                                maxInputLength:maxInputLength
                           blockedCharacterSet:blockedCharacterSet
                      invalidInputAlertMessage:invalidInputAlertMessage
                                 existingNames:nil];
}

+ (NSString*)uniqueName:(NSString*)nameToCheck existingNames:(NSArray*)existingNames
{
    NSMutableString *uniqueName = [nameToCheck mutableCopy];
    unichar lastChar = [uniqueName characterAtIndex:([uniqueName length] - 1)];
    if (lastChar == 0x20) {
        [uniqueName deleteCharactersInRange:NSMakeRange(([uniqueName length] - 1), 1)];
    }

    NSUInteger counter = 0;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\(\\d\\)"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];
    NSArray *results = [regex matchesInString:uniqueName
                                      options:0
                                        range:NSMakeRange(0, [uniqueName length])];
    if ([results count]) {
        BOOL duplicate = NO;
        for (NSString *existingName in existingNames) {
            if ([existingName isEqualToString:uniqueName]) {
                duplicate = YES;
                break;
            }
        }
        if (! duplicate) {
            return [uniqueName copy];
        }
        NSTextCheckingResult *lastOccurenceResult = [results lastObject];
        NSMutableString *lastOccurence = [(NSString*)[uniqueName substringWithRange:lastOccurenceResult.range] mutableCopy];
        [uniqueName replaceOccurrencesOfString:lastOccurence
                                    withString:@""
                                       options:NSCaseInsensitiveSearch
                                         range:NSMakeRange(0, [uniqueName length])];
        unichar lastChar = [uniqueName characterAtIndex:([uniqueName length] - 1)];
        if (lastChar == 0x20) {
            [uniqueName deleteCharactersInRange:NSMakeRange(([uniqueName length] - 1), 1)];
        }
        [lastOccurence replaceOccurrencesOfString:@"("
                                       withString:@""
                                          options:NSCaseInsensitiveSearch
                                            range:NSMakeRange(0, [lastOccurence length])];
        [lastOccurence replaceOccurrencesOfString:@")"
                                       withString:@""
                                          options:NSCaseInsensitiveSearch
                                            range:NSMakeRange(0, [lastOccurence length])];
        counter = [lastOccurence integerValue];
    }
    NSString *uniqueFinalName = [uniqueName copy];
    BOOL duplicate;
    do {
        duplicate = NO;
        for (NSString *existingName in existingNames) {
            if ([existingName isEqualToString:uniqueFinalName]) {
                uniqueFinalName = [NSString stringWithFormat:@"%@ (%lu)", uniqueName, (unsigned long)++counter];
                duplicate = YES;
                break;
            }
        }
    } while (duplicate);
    return uniqueFinalName;
}

+ (double)radiansToDegree:(double)rad
{
    return rad * 180.0f / M_PI;
}

+ (double)degreeToRadians:(double)deg
{
    return deg * M_PI / 180.0f;
}

#pragma mark - text field delegates
static NSCharacterSet *textFieldBlockedCharacterSet = nil;

static NSUInteger textFieldMaxInputLength = 0;

static CatrobatAlertView *catrobatAlertView = nil;

+ (BOOL)textField:(UITextField*)field shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString*)characters
{
    if ([characters length] > textFieldMaxInputLength) {
        return false;
    }
    return ([characters rangeOfCharacterFromSet:textFieldBlockedCharacterSet].location == NSNotFound);
}

+ (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [catrobatAlertView dismissWithClickedButtonIndex:0 animated:YES];
    [textField resignFirstResponder]; // dismiss the keyboard
    [[self class] alertView:catrobatAlertView clickedButtonAtIndex:kAlertViewButtonOK];
    return YES;
}

#pragma mark - alert view delegates
+ (void)alertView:(CatrobatAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSMutableDictionary *payload = (NSMutableDictionary*)alertView.dataTransferMessage.payload;
    if (alertView.tag == kAskUserForUniqueNameAlertViewTag) {
        if ((buttonIndex == alertView.cancelButtonIndex) || (buttonIndex != kAlertViewButtonOK)) {
            return;
        }

        NSString *input = [alertView textFieldAtIndex:0].text;
        id existingNamesObject = payload[kDTPayloadAskUserExistingNames];
        BOOL nameAlreadyExists = NO;
        if ([existingNamesObject isKindOfClass:[NSArray class]]) {
            NSArray *existingNames = (NSArray*)existingNamesObject;
            for (NSString *existingName in existingNames) {
                if ([existingName isEqualToString:input]) {
                    nameAlreadyExists = YES;
                }
            }
        }

        NSUInteger textFieldMinInputLength = [payload[kDTPayloadAskUserMinInputLength] unsignedIntegerValue];
        if (nameAlreadyExists) {
            CatrobatAlertView *newAlertView = [Util alertWithText:payload[kDTPayloadAskUserInvalidInputAlertMessage]
                                                         delegate:(id<CatrobatAlertViewDelegate>)self
                                                              tag:kInvalidNameWarningAlertViewTag];
            payload[kDTPayloadAskUserPromptValue] = input;
            newAlertView.dataTransferMessage = alertView.dataTransferMessage;
        } else if ([input length] < textFieldMinInputLength) {
            NSString *alertText = [NSString stringWithFormat:kLocalizedNoOrTooShortInputDescription,
                                   textFieldMinInputLength];
            alertText = ((textFieldMinInputLength != 1) ? [[self class] pluralString:alertText]
                                                        : [[self class] singularString:alertText]);
            CatrobatAlertView *newAlertView = [Util alertWithText:alertText
                                                         delegate:(id<CatrobatAlertViewDelegate>)self
                                                              tag:kInvalidNameWarningAlertViewTag];
            payload[kDTPayloadAskUserPromptValue] = input;
            newAlertView.dataTransferMessage = alertView.dataTransferMessage;
        } else {
            // no name duplicate => call action on target
            SEL action = [((NSValue*)payload[kDTPayloadAskUserAction]) pointerValue];
            id target = payload[kDTPayloadAskUserTarget];
            id passingObject = payload[kDTPayloadAskUserObject];
            if ((! passingObject) || [passingObject isKindOfClass:[NSNull class]]) {
                if (action) {
                    IMP imp = [target methodForSelector:action];
                    void (*func)(id, SEL, id) = (void *)imp;
                    func(target, action, input);
                }
            } else {
                if (action) {
                    IMP imp = [target methodForSelector:action];
                    void (*func)(id, SEL, id, id) = (void *)imp;
                    func(target, action, input, passingObject);
                }
            }
        }
    } else if (alertView.tag == kInvalidNameWarningAlertViewTag) {
        // title of cancel button is "OK"
        if (buttonIndex == alertView.cancelButtonIndex) {
            id value = payload[kDTPayloadAskUserPromptValue];
            CatrobatAlertView *newAlertView = [Util promptWithTitle:payload[kDTPayloadAskUserPromptTitle]
                                                            message:payload[kDTPayloadAskUserPromptMessage]
                                                           delegate:(id<CatrobatAlertViewDelegate>)self
                                                        placeholder:payload[kDTPayloadAskUserPromptPlaceholder]
                                                                tag:kAskUserForUniqueNameAlertViewTag
                                                              value:([value isKindOfClass:[NSString class]] ? value : nil)
                                                  textFieldDelegate:(id<UITextFieldDelegate>)self];
            newAlertView.dataTransferMessage = alertView.dataTransferMessage;
        }
    }
}

+ (NSString*)singularString:(NSString*)string
{
    NSMutableString *mutableString = [string mutableCopy];
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"\\(.+?\\)"
                                  options:NSRegularExpressionCaseInsensitive
                                  error:NULL];
    [regex replaceMatchesInString:mutableString
                          options:0
                            range:NSMakeRange(0, [mutableString length])
                     withTemplate:@""];
    return [[self class] pluralString:mutableString];
}

+ (NSString*)pluralString:(NSString*)string
{
    NSMutableString *mutableString = [string mutableCopy];
    [mutableString stringByReplacingOccurrencesOfString:@"(" withString:@""];
    [mutableString stringByReplacingOccurrencesOfString:@")" withString:@""];
    return [mutableString copy];
}

@end
