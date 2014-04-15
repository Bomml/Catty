/**
 *  Copyright (C) 2010-2013 The Catrobat Team
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

@implementation Util

+ (NSString *)applicationDocumentsDirectory
{    
    NSArray *paths = 
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;

}

+ (void)showComingSoonAlertView
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kUIAlertViewTitleStandard
                                                    message:kUIAlertViewMessageFeatureComingSoon
                                                   delegate:nil
                                          cancelButtonTitle:kBtnOKTitle
                                          otherButtonTitles:nil];
    [alert show];
}

+ (UIAlertView*)alertWithText:(NSString*)text
{
    return [self alertWithText:text delegate:nil tag:0];
}

+ (UIAlertView*)alertWithText:(NSString*)text delegate:(id<UIAlertViewDelegate>)delegate tag:(NSInteger)tag
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:kUIAlertViewTitleStandard
                                                        message:text
                                                       delegate:delegate
                                              cancelButtonTitle:kBtnOKTitle
                                              otherButtonTitles:nil];
    alertView.tag = tag;
    [alertView show];
    return alertView;
}

+ (UIAlertView*)confirmAlertWithTitle:(NSString*)title
                              message:(NSString*)message
                             delegate:(id<UIAlertViewDelegate>)delegate
                                  tag:(NSInteger)tag
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:delegate
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil];
    [alertView addButtonWithTitle:kBtnAgreeTitle];
    alertView.cancelButtonIndex = [alertView addButtonWithTitle:kBtnDisagreeTitle];
    alertView.tag = tag;
    [alertView show];
    return alertView;
}

+ (UIAlertView*)promptWithTitle:(NSString*)title
                message:(NSString*)message
               delegate:(id<UIAlertViewDelegate>)delegate
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

+ (UIAlertView*)promptWithTitle:(NSString*)title
                        message:(NSString*)message
                       delegate:(id<UIAlertViewDelegate>)delegate
                    placeholder:(NSString*)placeholder
                            tag:(NSInteger)tag
                          value:(NSString*)value
              textFieldDelegate:(id<UITextFieldDelegate>)textFieldDelegate
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:delegate
                                              cancelButtonTitle:kBtnCancelTitle
                                              otherButtonTitles:kBtnOKTitle, nil];
    alertView.tag = tag;
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = placeholder;
    [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
    textField.text = value;
    textField.delegate = textFieldDelegate;
    [alertView show];
    return alertView;
}

+ (UIActionSheet*)actionSheetWithTitle:(NSString*)title
                              delegate:(id<UIActionSheetDelegate>)delegate
                destructiveButtonTitle:(NSString*)destructiveButtonTitle
                     otherButtonTitles:(NSArray*)otherButtonTitles
                                   tag:(NSInteger)tag
                                  view:(UIView*)view
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:delegate
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    actionSheet.title = title;
    actionSheet.delegate = delegate;
    if (destructiveButtonTitle) {
        actionSheet.destructiveButtonIndex = [actionSheet addButtonWithTitle:destructiveButtonTitle];
    }
    for (id otherButtonTitle in otherButtonTitles) {
        if ([otherButtonTitle isKindOfClass:[NSString class]]) {
            [actionSheet addButtonWithTitle:otherButtonTitle];
        }
    }
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:kBtnCancelTitle];
    actionSheet.tag = tag;
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:view];
    return actionSheet;
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
        [userDefaults setObject:kDefaultProgramName forKey:kLastProgram];
        [userDefaults synchronize];
        lastProgram = kDefaultProgramName;
    }
    return lastProgram;
}

+ (void)setLastProgram:(NSString*)visibleName
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:visibleName forKey:kLastProgram];
    [userDefaults synchronize];
}

+ (NSString*)uniqueName:(NSString*)nameToCheck existingNames:(NSArray*)existingNames
{
    NSString *uniqueName = nameToCheck;
    NSUInteger counter = 0;
    BOOL duplicate;
    do {
        duplicate = NO;
        for (NSString *existingName in existingNames) {
            if ([existingName isEqualToString:uniqueName]) {
                uniqueName = [NSString stringWithFormat:@"%@ (%lu)", nameToCheck, (unsigned long)++counter];
                duplicate = YES;
                break;
            }
        }
    } while (duplicate);
    return uniqueName;
}

+ (double)radiansToDegree:(float)rad
{
    return rad * 180.0 / M_PI;
}

+ (double)degreeToRadians:(float)deg
{
    return deg * M_PI / 180.0;
}

@end
