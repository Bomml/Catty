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

#import "FormulaEditorViewController.h"
#import "FormulaEditorTextView.h"
#import "UIDefines.h"
#import "Brick.h"
#import "LanguageTranslationDefines.h"
#import "UIColor+CatrobatUIColorExtensions.h"
#import "StartScriptCell.h"
#import "WhenScriptCell.h"
#import "IfLogicElseBrickCell.h"
#import "IfLogicEndBrickCell.h"
#import "ForeverBrickCell.h"
#import "IfLogicBeginBrickCell.h"
#import "RepeatBrickCell.h"
#import "BroadcastScriptCell.h"
#import "CellMotionEffect.h"
#import "BrickCell.h"
#import "FormulaElement.h"
#import "LanguageTranslationDefines.h"
#import "FormulaEditorHistory.h"
#import "AHKActionSheet.h"

NS_ENUM(NSInteger, ButtonIndex) {
    kButtonIndexDelete = 0,
    kButtonIndexCopyOrCancel = 1,
    kButtonIndexAnimate = 2,
    kButtonIndexEdit = 3,
    kButtonIndexCancel = 4
};

@interface FormulaEditorViewController ()

@property (nonatomic, strong) FormulaEditorHistory *history;

@property (strong, nonatomic) UITapGestureRecognizer *recognizer;
@property (strong, nonatomic) UIMotionEffectGroup *motionEffects;
@property (strong, nonatomic) FormulaEditorTextView *formulaEditorTextView;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;
@property (weak, nonatomic) IBOutlet UIButton *redoButton;
@property (weak, nonatomic) IBOutlet UIButton *computeButton;
@property (weak, nonatomic) IBOutlet UIButton *divisionButton;
@property (weak, nonatomic) IBOutlet UIButton *multiplicationButton;
@property (weak, nonatomic) IBOutlet UIButton *substractionButton;
@property (weak, nonatomic) IBOutlet UIButton *additionButton;

@property (strong, nonatomic) AHKActionSheet *mathFunctionsMenu;

@end

@implementation FormulaEditorViewController

@synthesize formulaEditorTextView;

- (id)initWithFormulaButton:(FormulaEditorButton *)formulaButton
{
    self = [super init];
    
    if(self) {
        [self setFormulaButton:formulaButton];
    }
    
    return self;
}

- (void)setFormulaButton:(FormulaEditorButton*)formulaButton
{
    self.brickCell = formulaButton.brickCell;
    self.formulaEditorButton = formulaButton;
    self.internFormula = [[InternFormula alloc] initWithInternTokenList:[[self.formulaEditorButton getFormula].formulaTree getInternTokenList]];
    self.history = [[FormulaEditorHistory alloc] initWithInternFormulaState:[self.internFormula getInternFormulaState]];
    
    [self update];
    [self setCursorPositionToEndOfFormula];
}

- (void)setCursorPositionToEndOfFormula
{
    [self.internFormula setCursorAndSelection:0 selected:NO];
    [self.internFormula generateExternFormulaStringAndInternExternMapping];
    [self.internFormula setExternCursorPositionRightTo:INT_MAX];
    [self.internFormula updateInternCursorPosition];
}

- (InternFormula *)internFormula
{
    if(!_internFormula) {
        _internFormula = [[InternFormula alloc]init];
    }
    return _internFormula;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    [CellMotionEffect addMotionEffectForView:self.brickCell withDepthX:0.0f withDepthY:25.0f withMotionEffectGroup:self.motionEffects];
    
    [self showFormulaEditor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.recognizer.numberOfTapsRequired = 1;
    self.recognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:self.recognizer];
    [self update];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [CellMotionEffect removeMotionEffect:self.motionEffects fromView:self.brickCell];
    self.motionEffects = nil;
    if ([self.view.window.gestureRecognizers containsObject:self.recognizer]) {
        [self.view.window removeGestureRecognizer:self.recognizer];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(formulaEditorViewController:withBrickCell:)]) {
        [self.delegate formulaEditorViewController:self withBrickCell:self.brickCell];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    if ([sender isKindOfClass:UITapGestureRecognizer.class]) {
        //[self dismissFormulaEditorViewController];
    }
}

- (UIMotionEffectGroup *)motionEffects {
    if (!_motionEffects) {
        _motionEffects = [UIMotionEffectGroup new];
    }
    return _motionEffects;
}

#pragma mark - helper methods
- (void)dismissFormulaEditorViewController
{
    if (! self.presentingViewController.isBeingDismissed) {
        [self.formulaEditorTextView removeFromSuperview];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    }
}

#pragma mark - TextField Actions
- (IBAction)buttonPressed:(id)sender
{
    if([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        NSString *title = button.titleLabel.text;

        if(PLUS == [sender tag])
        {
            NSLog(@"Plus: %@", title);
        }else{
            NSLog(@"Beschreibung: %ld", (long)[sender tag]);
        }
        
        [self handleInputWithTitle:title AndButtonType:(int)[sender tag]];
    }
}

- (void)handleInputWithTitle:(NSString*)title AndButtonType:(int)buttonType
{
    [self.internFormula handleKeyInputWithName:title butttonType:buttonType];
    NSLog(@"InternFormulaString: %@",[self.internFormula getExternFormulaString]);
    [self.history push:[self.internFormula getInternFormulaState]];
    [self update];
}

- (IBAction)undo:(id)sender
{
    if (![self.history undoIsPossible]) {
        return;
    }
    
    InternFormulaState *lastStep = [self.history backward];
    if (lastStep != nil) {
        self.internFormula = [lastStep createInternFormulaFromState];
        [self update];
        [self setCursorPositionToEndOfFormula];
    }
}

- (IBAction)redo:(id)sender
{
    if (![self.history redoIsPossible]) {
        return;
    }
    
    InternFormulaState *nextStep = [self.history forward];
    if (nextStep != nil) {
        self.internFormula = [nextStep createInternFormulaFromState];
        [self update];
        [self setCursorPositionToEndOfFormula];
    }
}

- (void)backspace:(id)sender
{
    [self handleInputWithTitle:@"Backspace" AndButtonType:CLEAR];
}

- (IBAction)done:(id)sender
{
    [self dismissFormulaEditorViewController];
}

- (IBAction)compute:(id)sender {
    float result = [[[self.internFormula getInternFormulaParser] parseFormula] interpretRecursiveForSprite:nil];
    NSString *computedString = [NSString stringWithFormat:@"Computed result is %f", result];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Result"
                                                   message: computedString
                                                  delegate: self
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil,nil];
    [alert show];
}

#pragma margk - Getter and setter

- (AHKActionSheet *)mathFunctionsMenu
{
    if (!_mathFunctionsMenu) {
        
        NSArray *mathFunctions = @[
                                  [NSNumber numberWithInt:SIN],
                                  [NSNumber numberWithInt:COS],
                                  [NSNumber numberWithInt:TAN],
                                  [NSNumber numberWithInt:LN],
                                  [NSNumber numberWithInt:LOG],
                                  [NSNumber numberWithInt:PI_F],
                                  [NSNumber numberWithInt:SQRT],
                                  [NSNumber numberWithInt:ABS],
                                  [NSNumber numberWithInt:MAX],
                                  [NSNumber numberWithInt:MIN],
                                  [NSNumber numberWithInt:ARCSIN],
                                  [NSNumber numberWithInt:ARCCOS],
                                  [NSNumber numberWithInt:ARCTAN],
                                  [NSNumber numberWithInt:ROUND],
                                  [NSNumber numberWithInt:MOD],
                                  [NSNumber numberWithInt:POW],
                                  [NSNumber numberWithInt:EXP]
                                  ];
        
        _mathFunctionsMenu = [[AHKActionSheet alloc]initWithTitle:kUIActionSheetTitleSelectMathematicalFunction];
        _mathFunctionsMenu.blurTintColor = [UIColor colorWithWhite:0.0f alpha:0.7f];
        _mathFunctionsMenu.separatorColor = UIColor.skyBlueColor;
        _mathFunctionsMenu.titleTextAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0f] ,
                                                    NSForegroundColorAttributeName : UIColor.skyBlueColor};
        _mathFunctionsMenu.cancelButtonTextAttributes = @{NSForegroundColorAttributeName : UIColor.lightOrangeColor};
        _mathFunctionsMenu.buttonTextAttributes = @{NSForegroundColorAttributeName : UIColor.whiteColor};
        _mathFunctionsMenu.selectedBackgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
        _mathFunctionsMenu.automaticallyTintButtonImages = NO;
        
        __weak FormulaEditorViewController *weakSelf = self;
        
        for(int i = 0; i < [mathFunctions count]; i++) {
            
            int functionType = [[mathFunctions objectAtIndex:i] intValue];
            NSString *functionName = [Functions getExternName:[Functions getName:functionType]];
            [_mathFunctionsMenu addButtonWithTitle:functionName
                                           type:AHKActionSheetButtonTypeDefault
                                        handler:^(AHKActionSheet *actionSheet) {
                                            [weakSelf handleInputWithTitle:functionName AndButtonType:functionType];
                                            [weakSelf closeMathFunctionsMenu:SIN];
                                        }];
        }
        
        _mathFunctionsMenu.cancelHandler = ^(AHKActionSheet *actionSheet) {
            [weakSelf.formulaEditorTextView becomeFirstResponder];
        };
    }
    return _mathFunctionsMenu;
}

#pragma mark - UI

- (void)showFormulaEditor
{
    self.formulaEditorTextView = [[FormulaEditorTextView alloc] initWithFrame: CGRectMake(1, self.brickCell.frame.size.height + 41, self.view.frame.size.width - 2, 0) AndFormulaEditorViewController:self];
    [self.view addSubview:self.formulaEditorTextView];
    
    for(int i = 0; i < [self.buttons count]; i++) {
        [[self.buttons objectAtIndex:i] setTitleColor:UIColor.lightOrangeColor forState:UIControlStateNormal];
    }
    
    [self update];
    [self.formulaEditorTextView becomeFirstResponder];
}

- (void)update
{
    [self.formulaEditorTextView update];
    [self.formulaEditorButton updateFormula:self.internFormula];
    [self.undoButton setEnabled:[self.history undoIsPossible]];
    [self.redoButton setEnabled:[self.history redoIsPossible]];
}

- (IBAction)showMathFunctionsMenu:(id)sender {
    [self.formulaEditorTextView resignFirstResponder];
    [self.mathFunctionsMenu show];
    [self.mathFunctionsMenu becomeFirstResponder];
}

- (void)closeMathFunctionsMenu:(Function)function {
    [self.formulaEditorTextView becomeFirstResponder];
}

@end
