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
#import "BrickCategoriesTableViewController.h"
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

@interface ScriptCollectionViewController () <UICollectionViewDelegate, LXReorderableCollectionViewDelegateFlowLayout, LXReorderableCollectionViewDataSource, UIViewControllerTransitioningDelegate>
@property (nonatomic, strong) NSDictionary *classNameBrickNameMap;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) BrickScaleTransition *brickScaleTransition;
@property (nonatomic, strong) FXBlurView *dimView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) PlaceHolderView *placeHolderView;

@end

@implementation ScriptCollectionViewController

#pragma mark - events
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupCollectionView];
    [self setupToolBar];
    
    // register brick cells for current brick category
    NSDictionary *allCategoriesAndBrickTypes = self.classNameBrickNameMap;
    for (NSString *brickTypeName in allCategoriesAndBrickTypes) {
        [self.collectionView registerClass:NSClassFromString([brickTypeName stringByAppendingString:@"Cell"]) forCellWithReuseIdentifier:brickTypeName];
    }
}

#pragma mark - Getters and Setters
- (NSDictionary*)classNameBrickNameMap
{
    static NSDictionary *classNameBrickNameMap = nil;
    if (classNameBrickNameMap == nil) {
        classNameBrickNameMap = kClassNameBrickNameMap;
    }
    return classNameBrickNameMap;
}

#pragma mark - initialization
- (void)setupCollectionView
{
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"darkblue"]];
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.scrollEnabled = YES;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.navigationItem.rightBarButtonItems = @[self.editButtonItem];
    
    self.placeHolderView = [[PlaceHolderView alloc]initWithFrame:self.collectionView.bounds];
    [self.view addSubview:self.placeHolderView];
    self.placeHolderView.hidden = NO;
    
    self.brickScaleTransition = [BrickScaleTransition new];
    self.dimView = [[FXBlurView alloc] initWithFrame:self.view.bounds];
    self.dimView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.dimView.userInteractionEnabled = NO;
    self.dimView.tintColor = UIColor.clearColor;
    self.dimView.underlyingView = self.collectionView;
    self.dimView.blurEnabled = YES;
    self.dimView.blurRadius = 10.f;
    self.dimView.dynamic = YES;
    self.dimView.alpha = 0.f;
    self.dimView.hidden = YES;
    [self.view addSubview:self.dimView];
}

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
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [BrickCell clearImageCache];
}


#pragma mark - UIViewControllerAnimatedTransitioning delegate
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    self.brickScaleTransition.transitionMode = TransitionModePresent;
    return self.brickScaleTransition;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    self.brickScaleTransition.transitionMode = TransitionModeDismiss;
    return self.brickScaleTransition;
}

#pragma mark - actions
- (void)addBrickAction:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    BrickCategoriesTableViewController *brickCategoryTVC;
    brickCategoryTVC = [storyboard instantiateViewControllerWithIdentifier:@"BrickCategoriesTableViewController"];
    brickCategoryTVC.object = self.object;
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:brickCategoryTVC];
    [self presentViewController:navigationController animated:YES completion:NULL];
}

- (void)playSceneAction:(id)sender
{
    [self.navigationController setToolbarHidden:YES];
    [self performSegueWithIdentifier:kSegueToScene sender:sender];
}

- (void)addBrickCellAction:(BrickCell*)brickCell completionBlock:(void(^)())completionBlock {
    if (! brickCell) {
        return;
    }

    // convert brickCell to brick
    NSString *brickCellClassName = NSStringFromClass([brickCell class]);
    NSString *brickOrScriptClassName = [brickCellClassName stringByReplacingOccurrencesOfString:@"Cell" withString:@""];
    id brickOrScript = [[NSClassFromString(brickOrScriptClassName) alloc] init];
    
    if ([brickOrScript isKindOfClass:[Brick class]]) {
        Script *script = nil;
        // automatically create new script if the object does not contain any of them
        if (! [self.object.scriptList count]) {
            script = [[StartScript alloc] init];
            script.allowRunNextAction = YES;
            script.object = self.object;
            [self.object.scriptList addObject:script];
        } else {
            // add brick to first script
            script = [self.object.scriptList objectAtIndex:self.collectionView.numberOfSections - 1];
        }
        Brick *brick = (Brick*)brickOrScript;
        brick.object = self.object;
        [script.brickList addObject:brick];
    } else if ([brickOrScript isKindOfClass:[Script class]]) {
        Script *script = (Script*)brickOrScript;
        script.object = self.object;
        [self.object.scriptList addObject:script];
    } else {
        NSError(@"Unknown class type given...");
        abort();
    }
    
    if (completionBlock) completionBlock();
}

#pragma mark - Notification
- (void)brickAdded:(NSNotification*)notification
{
    if (notification.userInfo) {
        __weak UICollectionView *weakself = self.collectionView;
        NSUInteger sectionCount = self.object.scriptList.count;
        
        if (self.object.scriptList.count) {
            Script *script = [self.object.scriptList objectAtIndex:sectionCount - 1];
            NSUInteger brickCountInSection = script.brickList.count;
            
            NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:brickCountInSection inSection:sectionCount - 1];
            [self addBrickCellAction:notification.userInfo[kUserInfoKeyBrickCell] completionBlock:^{
                [weakself reloadData];
                [weakself scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
            }];
        } else {
            [self addBrickCellAction:notification.userInfo[kUserInfoKeyBrickCell] completionBlock:^{
                [weakself reloadData];
            }];
        }

    }
}

- (void)brickDetailViewDismissed:(NSNotification *)notification {
    self.collectionView.userInteractionEnabled = YES;
    [self.navigationController setToolbarHidden:NO animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [self.collectionView reloadData];
    
    if  ([notification.userInfo[@"brickDeleted"] boolValue]) {
        if (![notification.userInfo[@"isScript"] boolValue]) {
             [self removeBrickFromScriptCollectionViewFromIndex:self.selectedIndexPath];
        } else {
            [self removeScriptSectionWithIndexPath:self.selectedIndexPath];
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
    } else {
        // case it's a normal brick
        Brick *brick = [script.brickList objectAtIndex:(indexPath.row - 1)];
        NSString *brickSubClassName = NSStringFromClass([brick class]);
        brickCell = [collectionView dequeueReusableCellWithReuseIdentifier:brickSubClassName forIndexPath:indexPath];
        [brickCell setBrickEditing:self.isEditing];
    }
    brickCell.backgroundBrickCell = self.object.isBackground;
    brickCell.enabled = YES;
    [brickCell renderSubViews];
    
    self.placeHolderView.hidden = self.object.scriptList.count ? YES : NO;
    
    return brickCell;
}

#pragma mark - CollectionView layout
- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
    CGFloat width = self.view.frame.size.width;
    kBrickCategoryType categoryType = kControlBrick;
    NSInteger brickType = kProgramStartedBrick;
    Script *script = [self.object.scriptList objectAtIndex:indexPath.section];
    if (! script) {
        NSError(@"This should never happen");
        abort();
    }

    NSDictionary *allCategoriesAndBrickTypes = self.classNameBrickNameMap;
    if (indexPath.row == 0) {
        // case it's a script brick
        categoryType = kControlBrick;
        NSString *scriptSubClassName = NSStringFromClass([script class]);
        for (NSString *brickTypeName in allCategoriesAndBrickTypes) {
            if ([brickTypeName isEqualToString:scriptSubClassName]) {
                brickType = [allCategoriesAndBrickTypes[brickTypeName][@"brickType"] integerValue];
                break;
            }
        }
    } else {
        // case it's a normal brick
        Brick *brick = [script.brickList objectAtIndex:(indexPath.row - 1)];
        NSString *brickSubClassName = NSStringFromClass([brick class]);
        for (NSString *brickTypeName in allCategoriesAndBrickTypes) {
            if ([brickTypeName isEqualToString:brickSubClassName]) {
                categoryType = (kBrickCategoryType)[allCategoriesAndBrickTypes[brickTypeName][@"categoryType"] integerValue];
                brickType = [allCategoriesAndBrickTypes[brickTypeName][@"brickType"] integerValue];
                break;
            }
        }
    }
    CGFloat height = [BrickCell brickCellHeightForCategoryType:categoryType AndBrickType:brickType];

    // TODO: outsource all consts
    height -= 4.0f; // reduce height for overlapping

    // if last brick in last section => no overlapping and no height deduction!
    if (indexPath.section == ([self.object.scriptList count] - 1)) {
        Script *script = [self.object.scriptList objectAtIndex:indexPath.section];
        if (! script) {
            NSError(@"This should never happen");
            abort();
        }
        if (indexPath.row == [script.brickList count]) { // NOTE: there are ([brickList count]+1) cells!!
            height += 4.0f;
        }
    }
    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    // !!! PLEASE DO NOT COMMENT THESE LINES OUT !!!
    // margin between CVC-sections as you can see in Catroid's PocketCode version
    // TODO: outsource all consts
    return UIEdgeInsetsMake(10, 0, 5, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndexPath =  indexPath;
    BrickCell *cell = (BrickCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    NSLog(@"selected cell = %@", cell);
    
    // TDOD handle bricks which can be edited
    if (!self.isEditing) {
        BrickDetailViewController *brickDetailViewcontroller = [[BrickDetailViewController alloc]initWithNibName:@"BrickDetailViewController" bundle:nil];
        brickDetailViewcontroller.scriptCollectionViewControllerToolbar = self.navigationController.toolbar;
        
        NSString *brickName =  NSStringFromClass(cell.class);
        if (brickName.length) {
            brickName = [brickName substringToIndex:brickName.length - 4];
        }
        
        brickDetailViewcontroller.brickName = brickName;
        brickDetailViewcontroller.brickCell = cell;
        self.brickScaleTransition.cell = cell;
        self.brickScaleTransition.navigationBar = self.navigationController.navigationBar;
        self.brickScaleTransition.collectionView = self.collectionView;
        self.brickScaleTransition.touchRect = cell.frame;
        self.brickScaleTransition.dimView = self.dimView;
        brickDetailViewcontroller.transitioningDelegate = self;
        brickDetailViewcontroller.modalPresentationStyle = UIModalPresentationCustom;
        self.collectionView.userInteractionEnabled = NO;
        [self presentViewController:brickDetailViewcontroller animated:YES completion:^{
            self.navigationController.navigationBar.userInteractionEnabled = NO;
        }];
    } else {
        [self removeScriptSectionWithIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    BrickCell *cell = (BrickCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    cell.alpha = .7f;
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
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

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    [self.collectionView reloadData];
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    return toIndexPath.item == 0 ? NO : YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isEditing || indexPath.item == 0) {
        return NO;
    }
    
    return YES;
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
    // @INFO: Please do not modify or remove this code again, unless you don't know exactly what you are doing.

    [self.navigationController setToolbarHidden:NO];
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.tintColor = [UIColor orangeColor];
    self.navigationController.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil
                                                                              action:nil];
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
}

- (void)removeBrickFromScriptCollectionViewFromIndex:(NSIndexPath *)indexPath {
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

- (void)removeScriptSectionWithIndexPath:(NSIndexPath *)indexPath {
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

#pragma mark - Editing
-(void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    if (self.isEditing) {
        self.navigationItem.title = NSLocalizedString(@"Edit Mode", nil);
         __block NSInteger section = 0;
        for (NSUInteger idx = 0; idx < self.collectionView.numberOfSections; idx++) {
            Script *script = [self.object.scriptList objectAtIndex:idx];
            [script.brickList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                *stop = section > self.collectionView.numberOfSections ? YES : NO;
                
                BrickCell *cell = (BrickCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:idx + 1 inSection:section]];
                cell.userInteractionEnabled = NO;
                [UIView animateWithDuration:0.55f delay:0.0f usingSpringWithDamping:5.0f/*0.45f*/ initialSpringVelocity:0.0f/*2.0f*/ options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    cell.alpha = 0.2f;
                    // cell.transform = CGAffineTransformMakeScale(0.8f, 0.8f);  // TODO dont work right at the moment with the bacghround image. fix later
                } completion:NULL];
            }];
            section++;
        }
    } else {
         __block NSInteger section = 0;
        self.navigationItem.title = NSLocalizedString(@"Scripts", nil);
        for (NSUInteger idx = 0; idx < self.collectionView.numberOfSections; idx++) {
            Script *script = [self.object.scriptList objectAtIndex:idx];
            [script.brickList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                *stop = section > self.collectionView.numberOfSections ? YES : NO;
                
                BrickCell *cell = (BrickCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:idx + 1 inSection:section]];
                cell.userInteractionEnabled = YES;
                [UIView animateWithDuration:0.35f delay:0.0f usingSpringWithDamping:0.5f initialSpringVelocity:2.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    cell.alpha = 1.0;
                    //   cell.transform = CGAffineTransformIdentity; // TODO dont work right at the moment with the bacghround image. fix later

                } completion:NULL];
            }];
            section++;
        }
    }
}

@end
