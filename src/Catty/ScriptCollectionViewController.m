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

#import "ScriptCollectionViewController.h"
#import "UIDefines.h"
#import "SpriteObject.h"
#import "SegueDefines.h"
#import "ScenePresenterViewController.h"
#import "BrickCell.h"
#import "Script.h"
#import "StartScript.h"
#import "Brick.h"
#import "LXReorderableCollectionViewFlowLayout.h"
#import "BrickManager.h"
#import "StartScriptCell.h"
#import "BrickScaleTransition.h"
#import "BrickDetailViewController.h"
#import "WhenScriptCell.h"
#import "FXBlurView.h"
#import "LanguageTranslationDefines.h"
#import "PlaceHolderView.h"
#import "BroadcastScriptCell.h"
#import "UIColor+CatrobatUIColorExtensions.h"
#import "AHKActionSheet.h"
#import "BricksCollectionViewController.h"
#import "BrickSelectModalTransition.h"
#import "BrickSelectionSwipe.h"

@interface ScriptCollectionViewController () <UICollectionViewDelegate,
                                              LXReorderableCollectionViewDelegateFlowLayout,
                                              LXReorderableCollectionViewDataSource,
                                              UIViewControllerTransitioningDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) BrickScaleTransition *brickScaleTransition;
@property (nonatomic, strong) BrickSelectModalTransition *brickSelectModelTransition;
@property (nonatomic, strong) PlaceHolderView *placeHolderView;
@property (nonatomic, strong) NSIndexPath *addedIndexPath;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) AHKActionSheet *brickSelectionMenu;
@property (nonatomic, strong) BrickSelectionSwipe *interactiveSwipeDismiss;

@property (nonatomic, strong) UIView *testView;

@end

@implementation ScriptCollectionViewController {
    BOOL _brickSelectionActive;
}

#pragma mark - events
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupCollectionView];
    [self setupToolBar];

    // register brick cells for current brick category
    NSDictionary *allBrickTypes = [[BrickManager sharedBrickManager] classNameBrickTypeMap];
    for (NSString *className in allBrickTypes) {
        [self.collectionView registerClass:NSClassFromString([className stringByAppendingString:@"Cell"])
                forCellWithReuseIdentifier:className];
    }
}

#pragma mark - initialization
- (void)setupCollectionView
{
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = UIColor.darkBlueColor;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.scrollEnabled = YES;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    self.navigationItem.rightBarButtonItems = @[self.editButtonItem];
    self.placeHolderView = [[PlaceHolderView alloc]initWithTitle:kUIViewControllerPlaceholderTitleScripts];
    self.placeHolderView.frame = self.collectionView.bounds;
    [self.view addSubview:self.placeHolderView];
    self.placeHolderView.hidden = self.object.scriptList.count ? YES : NO;
    self.brickScaleTransition = [BrickScaleTransition new];
    self.brickSelectModelTransition = [BrickSelectModalTransition new];
}

#pragma mark - view events
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(brickAdded:) name:kBrickCellAddedNotification object:nil];
    [dnc addObserver:self selector:@selector(brickDetailViewDismissed:) name:kBrickDetailViewDismissed object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc removeObserver:self name:kBrickCellAddedNotification object:nil];
    [dnc removeObserver:self name:kBrickDetailViewDismissed object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [BrickCell clearImageCache];
}

#pragma mark - Getters and Setters
- (AHKActionSheet *)brickSelectionMenu
{
    if (!_brickSelectionMenu) {
        _brickSelectionMenu = [[AHKActionSheet alloc]initWithTitle:NSLocalizedString(kSelectionMenuTitle, nil)];
        _brickSelectionMenu.blurTintColor = [UIColor colorWithWhite:0.0f alpha:0.7f];
        _brickSelectionMenu.separatorColor = UIColor.skyBlueColor;
        _brickSelectionMenu.titleTextAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0f] ,
                                                    NSForegroundColorAttributeName : UIColor.skyBlueColor};
        _brickSelectionMenu.cancelButtonTextAttributes = @{NSForegroundColorAttributeName : UIColor.lightOrangeColor};
        _brickSelectionMenu.buttonTextAttributes = @{NSForegroundColorAttributeName : UIColor.whiteColor};
        _brickSelectionMenu.selectedBackgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
        _brickSelectionMenu.automaticallyTintButtonImages = NO;

        __weak typeof(self) weakSelf = self;
        [_brickSelectionMenu addButtonWithTitle:NSLocalizedString(@"Control", nil)
                                          image:[UIImage imageNamed:@"orange_indicator"]
                                   type:AHKActionSheetButtonTypeDefault
                                  handler:^(AHKActionSheet *actionSheet) {
                                      [weakSelf showBrickCategoryCVC:kControlBrick];
                                  }];
        
        [_brickSelectionMenu addButtonWithTitle:NSLocalizedString(@"Motion", nil)
                                          image:[UIImage imageNamed:@"lightblue_indicator"]
                                           type:AHKActionSheetButtonTypeDefault
                                        handler:^(AHKActionSheet *actionSheet) {
                                            [weakSelf showBrickCategoryCVC:kMotionBrick];
                                        }];
        
        [_brickSelectionMenu addButtonWithTitle:NSLocalizedString(@"Sound", nil)
                                          image:[UIImage imageNamed:@"pink_indicator"]
                                           type:AHKActionSheetButtonTypeDefault
                                        handler:^(AHKActionSheet *actionSheet) {
                                            [weakSelf showBrickCategoryCVC:kSoundBrick];
                                        }];
        
        [_brickSelectionMenu addButtonWithTitle:NSLocalizedString(@"Looks", nil)
                                          image:[UIImage imageNamed:@"green_indicator"]
                                           type:AHKActionSheetButtonTypeDefault
                                        handler:^(AHKActionSheet *actionSheet) {
                                            [weakSelf showBrickCategoryCVC:kLookBrick];
                                        }];
        
        [_brickSelectionMenu addButtonWithTitle:NSLocalizedString(@"Variables", nil)
                                          image:[UIImage imageNamed:@"red_indicator"]
                                           type:AHKActionSheetButtonTypeDefault
                                        handler:^(AHKActionSheet *actionSheet) {
                                            [weakSelf showBrickCategoryCVC:kVariableBrick];
                                        }];
        
        [_brickSelectionMenu addButtonWithTitle:NSLocalizedString(@"Test Show View", nil)
                                          image:nil
                                           type:AHKActionSheetButtonTypeDefault
                                        handler:^(AHKActionSheet *actionSheet) {
                                            [weakSelf showBrickSelectionView:kControlBrick];
                                        }];
    }
    return _brickSelectionMenu;
}

#pragma mark - Brick Selection Menu Action

- (void)showBrickCategoryCVC:(kBrickCategoryType)type
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    BricksCollectionViewController *bricksCollectionViewController = (BricksCollectionViewController*)[storyboard      instantiateViewControllerWithIdentifier:@"BricksDetailViewCollectionViewController"];
    bricksCollectionViewController.scriptCollectionViewController = self;
    bricksCollectionViewController.transitioningDelegate = self;
    bricksCollectionViewController.modalPresentationStyle = UIModalPresentationCustom;
    bricksCollectionViewController.brickCategoryType = type;
    bricksCollectionViewController.object = self.object;
    _brickSelectionActive = YES;
    
    [self presentViewController:bricksCollectionViewController animated:YES completion:^{
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }];
}


- (void)showBrickSelectionView:(kBrickCategoryType)type
{
    
}

//- (void)showTestView
//{
//    if (!_testViewOnScreen) {
//        _originalCollectionViewHeight = CGRectGetHeight(self.collectionView.bounds);
//        _testView = [[UIView alloc]initWithFrame:CGRectMake(0.0f, UIScreen.mainScreen.bounds.size.height + 250.0f, self.view.bounds.size.width, UIScreen.mainScreen.bounds.size.height / 2.0f)];
//        _testView.backgroundColor = UIColor.clearColor;
//        _testView.alpha = 0.98f;
//        
//        FXBlurView *subBlurView = [[FXBlurView alloc] initWithFrame:_testView.bounds];
//        subBlurView.tintColor = UIColor.clearColor;
//        subBlurView.underlyingView = self.view;
//        subBlurView.updateInterval = 0.1f;
//        subBlurView.blurRadius = 20.f;
//        
//        CALayer *overlayLayer = CALayer.layer;
//        overlayLayer.frame = subBlurView.bounds;
//        overlayLayer.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f].CGColor;
//        [_testView.layer insertSublayer:overlayLayer atIndex:1];
//        
//        [_testView insertSubview:subBlurView atIndex:0];
//        
//        UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(5.0f, 10.0f, 80.0f, 15.0f)];
//        titleLabel.text = @"Brick Name";
//        titleLabel.font = [UIFont systemFontOfSize:13.0f];
//        titleLabel.textAlignment = NSTextAlignmentLeft;
//        titleLabel.textColor = UIColor.skyBlueColor;
//        [_testView addSubview:titleLabel];
//        
//        [self.view insertSubview:_testView aboveSubview:self.collectionView];
//        
//        [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.7f initialSpringVelocity:2.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
//            _testView.frame = CGRectMake(0.0f, UIScreen.mainScreen.bounds.size.height - 250.0f, CGRectGetWidth(self.view.bounds), UIScreen.mainScreen.bounds.size.height / 2.0f);
//            self.collectionView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.collectionView.bounds), UIScreen.mainScreen.bounds.size.height / 2.0f + NAVIGATION_BAR_HEIGHT);
//            [self.navigationController setNavigationBarHidden:YES animated:YES];
//        } completion:^(BOOL finished) {
//            _testViewOnScreen = YES;
//            [self setupToolBar];
//            
//        }];
//    } else {
//        [UIView animateWithDuration:0.4f delay:0.0f usingSpringWithDamping:0.8f initialSpringVelocity:1.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
//            _testView.frame = CGRectMake(0.0f, UIScreen.mainScreen.bounds.size.height + 250.0f, CGRectGetWidth(self.view.bounds), UIScreen.mainScreen.bounds.size.height / 2.0f);
//            self.collectionView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.collectionView.bounds), _originalCollectionViewHeight);
//            [self.navigationController setNavigationBarHidden:NO animated:YES];
//
//        } completion:^(BOOL finished) {
//            _testViewOnScreen = NO;
//            [self setupToolBar];
//        }];
//    }
//}

- (FXBlurView *)dimView
{
    if (! _dimView) {
        _dimView = [[FXBlurView alloc] initWithFrame:self.view.bounds];
        _dimView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _dimView.userInteractionEnabled = NO;
        _dimView.tintColor = UIColor.clearColor;
        _dimView.underlyingView = self.collectionView;
        _dimView.blurEnabled = YES;
        _dimView.blurRadius = 20.f;
        _dimView.dynamic = YES;
        _dimView.updateInterval = 0.1f;
        _dimView.alpha = 0.f;
        _dimView.hidden = YES;
        [self.view addSubview:self.dimView];
    }
    return _dimView;
}

#pragma mark - UIViewControllerAnimatedTransitioning delegate
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    if ([presented isKindOfClass:[BrickDetailViewController class]]) {
         self.brickScaleTransition.transitionMode = TransitionModePresent;
        return self.brickScaleTransition;
    } else {
        if ([presented isKindOfClass:[BricksCollectionViewController class]]) {
            self.brickSelectModelTransition.transitionMode = TransitionModePresent;
            return self.brickSelectModelTransition;
        }
    }
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    if ([dismissed isKindOfClass:[BrickDetailViewController class]]) {
        self.brickScaleTransition.transitionMode = TransitionModeDismiss;
        return self.brickScaleTransition;
    } else {
        if ([dismissed isKindOfClass:[BricksCollectionViewController class]]) {
            _brickSelectionActive = NO;
            self.brickSelectModelTransition.transitionMode = TransitionModeDismiss;
            return self.brickSelectModelTransition;
        }
    }
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    if ([animator isKindOfClass:[BrickSelectModalTransition class]]) {
        if (!self.interactiveSwipeDismiss) {
            self.interactiveSwipeDismiss = [BrickSelectionSwipe new];
        }
        return self.interactiveSwipeDismiss;
    }
    return nil;
}

#pragma mark - actions
- (void)addBrickAction:(id)sender
{
    [self.brickSelectionMenu show];
}

- (void)playSceneAction:(id)sender
{
    [self.navigationController setToolbarHidden:YES];
    [self performSegueWithIdentifier:kSegueToScene sender:sender];
}

- (void)scriptDeleteButtonAction:(id)sender
{
    if ([sender isKindOfClass:ScriptDeleteButton.class]) {
        ScriptDeleteButton *button = (ScriptDeleteButton *)sender;
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[self.collectionView convertPoint:button.center fromView:button.superview]];
        if (indexPath) {
            [self removeScriptSectionWithIndexPath:indexPath];
        }

    }
}

#pragma mark - Notification
- (void)brickAdded:(NSNotification*)notification
{
    if (notification.userInfo) {
        __weak typeof(UICollectionView) *weakCollectionView = self.collectionView;
        __weak typeof(ScriptCollectionViewController) *weakself = self;
        if (self.object.scriptList) {
            [self addBrickCellAction:notification.userInfo[kUserInfoKeyBrickCell] copyBrick:NO completionBlock:^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakself scrollToLastbrickinCollectionView:weakCollectionView completion:NULL];
                    if (weakself.navigationController.navigationBar.hidden) {
                         [weakself.navigationController setNavigationBarHidden:NO animated:YES];
                    }
                });
            }];
        }
    }
}

- (void)brickDetailViewDismissed:(NSNotification *)notification
{
    self.collectionView.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [self.collectionView reloadData];

    if  ([notification.userInfo[@"brickDeleted"] boolValue]) {
        [notification.userInfo[@"isScript"] boolValue] ? [self removeScriptSectionWithIndexPath:self.selectedIndexPath]
                                                       : [self removeBrickFromScriptCollectionViewFromIndex:self.selectedIndexPath];
    } else {
        BOOL copy = [notification.userInfo[@"copy"] boolValue];
        if (copy && [notification.userInfo[@"copiedCell"] isKindOfClass:BrickCell.class]) {
            [self addBrickCellAction:notification.userInfo[@"copiedCell"] copyBrick:copy completionBlock:NULL];
        }
    }
}

#pragma mark - collection view datasource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self.object.scriptList count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    Script *script = [self.object.scriptList objectAtIndex:section];
    if (! script) {
        NSError(@"This should never happen");
        abort();
    }
    return ([script.brickList count] + 1); // because script itself is a brick in IDE too
}

#pragma mark - collection view delegate
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Script *script = [self.object.scriptList objectAtIndex:indexPath.section];
    if (! script) {
        NSError(@"This should never happen");
        abort();
    }

    BrickCell *brickCell = nil;
    if (indexPath.row == 0) {
        // case it's a script brick
        NSString *scriptSubClassName = NSStringFromClass([script class]);
        brickCell = [collectionView dequeueReusableCellWithReuseIdentifier:scriptSubClassName forIndexPath:indexPath];
        brickCell.brick = script;
        [brickCell.deleteButton addTarget:self action:@selector(scriptDeleteButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [brickCell setBrickEditing:self.isEditing];

        // overridden values, needs refactoring later
        brickCell.alpha = 1.0f;
        brickCell.userInteractionEnabled = YES;
    } else {
        // case it's a normal brick
        Brick *brick = [script.brickList objectAtIndex:(indexPath.row - 1)];
        NSString *brickSubClassName = NSStringFromClass([brick class]);
        brickCell = [collectionView dequeueReusableCellWithReuseIdentifier:brickSubClassName forIndexPath:indexPath];
        brickCell.brick = brick;
        [brickCell setBrickEditing:self.isEditing];
        brickCell.hideDeleteButton = YES;
    }
    brickCell.enabled = YES;
    [brickCell renderSubViews];
    return brickCell;
}

#pragma mark - CollectionView layout
- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
    CGFloat width = self.view.frame.size.width;
    Script *script = [self.object.scriptList objectAtIndex:indexPath.section];
    if (! script) {
        NSError(@"This should never happen");
        abort();
    }

    Class brickCellClass = NULL;
    if (indexPath.row == 0) {
        // case it's a script brick
        NSString *scriptSubClassName = [NSStringFromClass([script class]) stringByAppendingString:@"Cell"];
        brickCellClass = NSClassFromString(scriptSubClassName);
    } else {
        // case it's a normal brick
        Brick *brick = [script.brickList objectAtIndex:(indexPath.row - 1)];
        NSString *brickSubClassName = [NSStringFromClass([brick class]) stringByAppendingString:@"Cell"];
        brickCellClass = NSClassFromString(brickSubClassName);
    }

    CGFloat height = [brickCellClass cellHeight];
    height -= kBrickOverlapHeight; // reduce height for overlapping

    // last brick in last section has no overlapping at the bottom
    if (indexPath.section == ([self.object.scriptList count] - 1)) {
        if (indexPath.row == [script.brickList count]) { // there are ([brickList count]+1) cells
            height += kBrickOverlapHeight;
        }
    }
    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10, 0, 5, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    BrickCell *cell = (BrickCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    self.selectedIndexPath =  indexPath;

    // TODO: handle bricks which can be edited
    if (! self.isEditing  && ! [self.presentedViewController isKindOfClass:BricksCollectionViewController.class]) {
        BrickDetailViewController *brickDetailViewcontroller = [[BrickDetailViewController alloc]initWithNibName:@"BrickDetailViewController" bundle:nil];
        brickDetailViewcontroller.brickCell = cell;
        self.brickScaleTransition.cell = cell;
        self.brickScaleTransition.touchRect = cell.frame;
        brickDetailViewcontroller.transitioningDelegate = self;
        brickDetailViewcontroller.modalPresentationStyle = UIModalPresentationCustom;
        self.collectionView.userInteractionEnabled = NO;
        [self presentViewController:brickDetailViewcontroller animated:YES completion:^{
            self.navigationController.navigationBar.userInteractionEnabled = NO;
        }];
    } 
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    BrickCell *cell = (BrickCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    cell.alpha = .7f;
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    BrickCell *cell = (BrickCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    cell.alpha = 1.f;
}

#pragma mark - LXReorderableCollectionViewDatasource
- (void)collectionView:(UICollectionView *)collectionView
       itemAtIndexPath:(NSIndexPath *)fromIndexPath
   willMoveToIndexPath:(NSIndexPath *)toIndexPath
{
    if (fromIndexPath.section == toIndexPath.section) {
        Script *script = [self.object.scriptList objectAtIndex:fromIndexPath.section];
        Brick *toBrick = [script.brickList objectAtIndex:toIndexPath.item - 1];
        [script.brickList removeObjectAtIndex:toIndexPath.item - 1];
        [script.brickList insertObject:toBrick atIndex:fromIndexPath.item - 1];
    } else {
        Script *toScript = [self.object.scriptList objectAtIndex:toIndexPath.section];
        Brick *toBrick = [toScript.brickList objectAtIndex:toIndexPath.item - 1];
        
        Script *fromScript = [self.object.scriptList objectAtIndex:fromIndexPath.section];
        Brick *fromBrick = [fromScript.brickList objectAtIndex:fromIndexPath.item - 1];
        
        [toScript.brickList removeObjectAtIndex:toIndexPath.item -1];
        [fromScript.brickList removeObjectAtIndex:fromIndexPath.item - 1];
        [toScript.brickList insertObject:fromBrick atIndex:toIndexPath.item - 1];
        [toScript.brickList insertObject:toBrick atIndex:toIndexPath.item];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath
{
    return (toIndexPath.item != 0);
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return ((self.isEditing || indexPath.item == 0) ? NO : YES);
}

#pragma mark - segue handling
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    static NSString* toSceneSegueID = kSegueToScene;
    UIViewController* destController = segue.destinationViewController;
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        if ([segue.identifier isEqualToString:toSceneSegueID]) {
            if ([destController isKindOfClass:[ScenePresenterViewController class]]) {
                ScenePresenterViewController* scvc = (ScenePresenterViewController*) destController;
                if ([scvc respondsToSelector:@selector(setProgram:)]) {
                    [scvc setController:(UITableViewController *)self];
                    [scvc performSelector:@selector(setProgram:) withObject:self.object.program];
                }
            }
        }
    }
}

#pragma mark - helpers
- (void)setupToolBar
{
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.tintColor = [UIColor orangeColor];
    
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil
                                                                              action:nil];
    if (!_testViewOnScreen) {
        self.navigationController.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

        UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                             target:self
                                                                             action:@selector(addBrickAction:)];
        UIBarButtonItem *play = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                              target:self
                                                                              action:@selector(playSceneAction:)];
        // XXX: workaround for tap area problem:
        // http://stackoverflow.com/questions/5113258/uitoolbar-unexpectedly-registers-taps-on-uibarbuttonitem-instances-even-when-tap
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"transparent1x1"]];
        UIBarButtonItem *invisibleButton = [[UIBarButtonItem alloc] initWithCustomView:imageView];
        self.toolbarItems = [NSArray arrayWithObjects:flexItem, invisibleButton, add, invisibleButton, flexItem,
                             flexItem, flexItem, invisibleButton, play, invisibleButton, flexItem, nil];
    } else {
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(showTestView)];
        self.toolbarItems = @[flexItem, done, flexItem];
    }
}

- (void)removeBrickFromScriptCollectionViewFromIndex:(NSIndexPath *)indexPath
{
    if (indexPath) {
        Script *script = [self.object.scriptList objectAtIndex:indexPath.section];
        if (script.brickList.count) {
            [self.collectionView performBatchUpdates:^{
                [script.brickList removeObjectAtIndex:indexPath.item - 1];
                [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
            } completion:^(BOOL finished) {
                [self.collectionView reloadData];
            }];
        }
    }
}

- (void)removeScriptSectionWithIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section <= self.collectionView.numberOfSections) {
        Script *script = [self.object.scriptList objectAtIndex:indexPath.section];
        [self.collectionView performBatchUpdates:^{
            [self.object.scriptList removeObject:script];
            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
        } completion:^(BOOL finished) {
            [self.collectionView reloadData];
            self.placeHolderView.hidden = self.object.scriptList.count ? YES : NO;
        }];
    }
}

- (void)addBrickCellAction:(BrickCell*)brickCell copyBrick:(BOOL)copy completionBlock:(void(^)())completionBlock
{
    if (! brickCell) {
        return;
    }

    // convert brickCell to brick
    NSString *brickCellClassName = NSStringFromClass([brickCell class]);
    NSString *brickOrScriptClassName = [brickCellClassName stringByReplacingOccurrencesOfString:@"Cell" withString:@""];
    id brickOrScript = [[NSClassFromString(brickOrScriptClassName) alloc] init];
    if (! [brickOrScript conformsToProtocol:@protocol(BrickProtocol)]) {
        NSError(@"Given object does not implement BrickProtocol...");
        abort();
    }

    if ([brickOrScript isKindOfClass:[Brick class]]) {
        Script *script = nil;
        // automatically create new script if the object does not contain any of them
        if (! [self.object.scriptList count]) {
            script = [[StartScript alloc] init];
            script.allowRunNextAction = YES;
            script.object = self.object;
            [self.object.scriptList addObject:script];
        } else {
           script = [self firstVisibleScriptOnScreen:copy];
        }
        Brick *brick = (Brick*)brickOrScript;
        brick.object = self.object;
        
        [self insertBrick:brick intoScriptList:script copy:copy];
    } else if ([brickOrScript isKindOfClass:[Script class]]) {
        Script *script = (Script*)brickOrScript;
        script.object = self.object;
        [self.object.scriptList addObject:script];
    } else {
        NSError(@"Unknown class type given...");
        abort();
    }
    self.placeHolderView.hidden = self.object.scriptList.count ? YES : NO;
    [self.collectionView reloadData];
    if (completionBlock) {
        completionBlock();
    }
}

- (Script *)firstVisibleScriptOnScreen:(BOOL)copy
{
    Script *script = nil;
    if (copy) {
        script = [self.object.scriptList objectAtIndex:self.selectedIndexPath.section];
    } else {
        // insert new brick in last visible script (section)
        NSMutableArray *scriptCells = [NSMutableArray array];
        if (self.collectionView.visibleCells.count) {
            for (BrickCell *cell in self.collectionView.visibleCells) {
                if ([cell isScriptBrick]) {
                    [scriptCells addObject:cell];
                }
            }
        }
        if (scriptCells.count) {
            [scriptCells sortUsingComparator:^(BrickCell *cell1, BrickCell *cell2) {
                if (cell1.frame.origin.y > cell2.frame.origin.y) {
                    return (NSComparisonResult)NSOrderedDescending;
                }
                
                if (cell1.frame.origin.y < cell2.frame.origin.y) {
                    return (NSComparisonResult)NSOrderedAscending;
                }
                return (NSComparisonResult)NSOrderedSame;
            }];
        }
        
        BOOL emtpyScript = NO;
        for (BrickCell *scriptCell in scriptCells) {
            script = [self.object.scriptList objectAtIndex:[self.collectionView indexPathForCell:scriptCell].section];
            if (! script.brickList.count) {
                emtpyScript = YES;
                break;
            }
        }
        
        BrickCell *cell = scriptCells.count ? scriptCells.lastObject : [self.collectionView.visibleCells firstObject];
        script = emtpyScript ? script : [self.object.scriptList objectAtIndex:[self.collectionView indexPathForCell:cell].section];
        self.addedIndexPath = [self.collectionView indexPathForCell:cell];
    }
    return script;
}

- (void)insertBrick:(Brick *)brick intoScriptList:(Script *)script copy:(BOOL)copy
{
    if (copy) {
        [self.collectionView performBatchUpdates:^{
            [script.brickList insertObject:brick atIndex:self.selectedIndexPath.item];
            [self.collectionView insertItemsAtIndexPaths:@[self.selectedIndexPath]];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.collectionView reloadData];
            }
        }];
    } else {
         __block NSIndexPath *indexPath = nil;
        [self.collectionView performBatchUpdates:^{
            if (! script.brickList.count) {
                [script.brickList addObject:brick];
                indexPath = [NSIndexPath indexPathForItem:script.brickList.count inSection:self.collectionView.numberOfSections - 1];
                [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
            } else {
                [script.brickList insertObject:brick atIndex:script.brickList.count];
                 indexPath = [NSIndexPath indexPathForItem:script.brickList.count inSection:self.addedIndexPath.section];
                [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
            }
            
        } completion:^(BOOL finished) {
            if (finished) {
                [self.collectionView reloadData];
            }
        }];
    }
}


- (void)scrollToLastbrickinCollectionView:(UICollectionView *)collectionView completion:(void(^)(NSIndexPath *indexPath))completion
{
    Script *script = [self.object.scriptList objectAtIndex:self.addedIndexPath.section];
    NSUInteger brickCountInSection = script.brickList.count;
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:brickCountInSection inSection:self.addedIndexPath.section];
    [collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];

    if (completion) {
        completion(lastIndexPath);
    }
}

#pragma mark - Editing
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    if (self.isEditing) {
        self.navigationItem.title = kUINavigationItemTitleEditMenu;
         __block NSInteger section = 0;;
        for (NSUInteger idx = 0; idx < self.collectionView.numberOfSections; idx++) {
            BrickCell *controlBrickCell = (BrickCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            [self animateStataCellDeleteButton:controlBrickCell];
            
            Script *script = [self.object.scriptList objectAtIndex:idx];
            [script.brickList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                *stop = section > self.collectionView.numberOfSections ? YES : NO;
                BrickCell *cell = (BrickCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:idx + 1 inSection:section]];
                cell.userInteractionEnabled = NO;
                [UIView animateWithDuration:0.35f delay:0.0f usingSpringWithDamping:1.0f/*0.45f*/ initialSpringVelocity:5.0f/*2.0f*/ options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    cell.alpha = 0.2f;
                    // cell.transform = CGAffineTransformMakeScale(0.8f, 0.8f);  // TODO dont work right at the moment with the bacghround image. fix later
                } completion:NULL];
            }];
            section++;
        }
    } else {
        self.navigationItem.title = kUITableViewControllerMenuTitleScripts;
        __block NSInteger section = 0;
        for (NSUInteger idx = 0; idx < self.collectionView.numberOfSections; idx++) {
            BrickCell *controlBrickCell = (BrickCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            [self animateStataCellDeleteButton:controlBrickCell];

            Script *script = [self.object.scriptList objectAtIndex:idx];
            [script.brickList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                *stop = section > self.collectionView.numberOfSections ? YES : NO;
                BrickCell *cell = (BrickCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:idx + 1 inSection:section]];
                cell.userInteractionEnabled = YES;
                [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:0.5f initialSpringVelocity:2.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    cell.alpha = 1.0;
                    //   cell.transform = CGAffineTransformIdentity; // TODO dont work right at the moment with the bacghround image. fix later
                } completion:NULL];
            }];
            section++;
        }
    }
}

- (void)animateStataCellDeleteButton:(BrickCell *)controlBrickCell
{
    CGFloat endAlpha;
    CGAffineTransform transform;
    BOOL start = NO;
    
    controlBrickCell.hideDeleteButton = NO;
    if (self.isEditing) {
        start = YES;
        controlBrickCell.deleteButton.alpha = 0.0f;
        endAlpha = 1.0f;
        controlBrickCell.deleteButton.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
        transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    } else {
        transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        endAlpha = 0.0f;
    }
    
    [UIView animateWithDuration:0.35f
                          delay:0
         usingSpringWithDamping:1.0f
          initialSpringVelocity:1.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         controlBrickCell.deleteButton.transform = transform;
                         controlBrickCell.deleteButton.alpha = endAlpha;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             controlBrickCell.hideDeleteButton = !start;
                         }
                     }];
    
}

@end
