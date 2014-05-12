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

#import "ProgramTableViewController.h"
#import "TableUtil.h"
#import "ObjectTableViewController.h"
#import "SegueDefines.h"
#import "Program.h"
#import "Look.h"
#import "Sound.h"
#import "Brick.h"
#import "ObjectTableViewController.h"
#import "CatrobatImageCell.h"
#import "DarkBlueGradientImageDetailCell.h"
#import "Util.h"
#import "UIDefines.h"
#import "ProgramDefines.h"
#import "ProgramLoadingInfo.h"
#import "Script.h"
#import "Brick.h"
#import "ActionSheetAlertViewTags.h"
#import "ScenePresenterViewController.h"
#import "FileManager.h"
#import "UIColor+CatrobatUIColorExtensions.h"
#import "UIImageView+CatrobatUIImageViewExtensions.h"
#import "ProgramUpdateDelegate.h"
#import "SensorHandler.h"
#import "CellTagDefines.h"
#import "AppDelegate.h"
#import "LanguageTranslationDefines.h"

// TODO: outsource...
#define kUserDetailsShowDetailsKey @"showDetails"
#define kUserDetailsShowDetailsObjectsKey @"detailsForObjects"

@interface ProgramTableViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UITextFieldDelegate,
UINavigationBarDelegate>
@property (nonatomic) BOOL useDetailCells;
@property (strong, nonatomic) NSCharacterSet *blockedCharacterSet;
@property (strong, nonatomic) NSMutableDictionary *imageCache;
@end

@implementation ProgramTableViewController

#pragma mark - getter and setters
- (NSCharacterSet*)blockedCharacterSet
{
    if (! _blockedCharacterSet) {
        _blockedCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:kTextFieldAllowedCharacters] invertedSet];
    }
    return _blockedCharacterSet;
}

- (NSMutableDictionary*)imageCache
{
    // lazy instantiation
    if (! _imageCache) {
        _imageCache = [NSMutableDictionary dictionaryWithCapacity:[self.program numberOfTotalObjects]];
    }
    return _imageCache;
}

- (void)setProgram:(Program *)program
{
    [program setAsLastProgram];
    _program = program;
}

#pragma mark - initialization
- (void)initNavigationBar
{
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:kUIBarButtonItemTitleEdit
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(editAction:)];
    self.navigationItem.rightBarButtonItem = editButton;
}

#pragma mark - view events
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self.tableView reloadData];
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController setToolbarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.isNewProgram) {
        [self.program saveToDisk];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSDictionary *showDetails = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDetailsShowDetailsKey];
    NSNumber *showDetailsObjectsValue = (NSNumber*)[showDetails objectForKey:kUserDetailsShowDetailsObjectsKey];
    self.useDetailCells = [showDetailsObjectsValue boolValue];
    [self initNavigationBar];
    [super initTableView];

    self.editableSections = @[@(kObjectSectionIndex)];
    if (self.program.header.programName) {
        self.navigationItem.title = self.program.header.programName;
        self.title = self.program.header.programName;
    }
    [self setupToolBar];
}

#pragma mark - application events
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.imageCache = nil;
}

#pragma mark - actions
- (void)addObjectAction:(id)sender
{
    [Util promptWithTitle:kUIAlertViewTitleAddObject
                  message:[NSString stringWithFormat:@"%@:", kUIAlertViewMessageObjectName]
                 delegate:self
              placeholder:kUIAlertViewPlaceholderEnterObjectName
                      tag:kNewObjectAlertViewTag
        textFieldDelegate:self];
}

- (void)playSceneAction:(id)sender
{
    [self.navigationController setToolbarHidden:YES];
    [self performSegueWithIdentifier:kSegueToScene sender:sender];
}

- (void)editAction:(id)sender
{
    NSMutableArray *options = [NSMutableArray array];
    [options addObject:kUIActionSheetButtonTitleRename];
    if ([self.program numberOfNormalObjects]) {
        [options addObject:kUIActionSheetButtonTitleDeleteObjects];
    }
    if (self.useDetailCells) {
        [options addObject:kUIActionSheetButtonTitleHideDetails];
    } else {
        [options addObject:kUIActionSheetButtonTitleShowDetails];
    }
    [Util actionSheetWithTitle:kUIActionSheetTitleEditProgramSingular
                      delegate:self
        destructiveButtonTitle:kUIActionSheetButtonTitleDelete
             otherButtonTitles:options
                           tag:kEditProgramActionSheetTag
                          view:self.view];
}

- (void)confirmDeleteSelectedObjectsAction:(id)sender
{
    NSArray *selectedRowsIndexPaths = [self.tableView indexPathsForSelectedRows];
    if (! [selectedRowsIndexPaths count]) {
        // nothing selected, nothing to delete...
        [super exitEditingMode];
        return;
    }
    [self performActionOnConfirmation:@selector(deleteSelectedObjectsAction)
                       canceledAction:@selector(exitEditingMode)
                               target:self
                         confirmTitle:(([selectedRowsIndexPaths count] != 1)
                                       ? kUIAlertViewTitleDeleteMultipleObjects
                                       : kUIAlertViewTitleDeleteSingleObject)
                       confirmMessage:kUIAlertViewMessageIrreversibleAction];
}

- (void)deleteSelectedObjectsAction
{
    NSArray *selectedRowsIndexPaths = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *objectsToRemove = [NSMutableArray arrayWithCapacity:[selectedRowsIndexPaths count]];
    for (NSIndexPath *selectedRowIndexPath in selectedRowsIndexPaths) {
        // sanity check
        if (selectedRowIndexPath.section != kObjectSectionIndex) {
            continue;
        }
        SpriteObject *object = (SpriteObject*)[self.program.objectList objectAtIndex:(kObjectSectionIndex + selectedRowIndexPath.row)];
        [self.imageCache removeObjectForKey:object.name];
        [objectsToRemove addObject:object];
    }
    for (SpriteObject *objectToRemove in objectsToRemove) {
        [self.program removeObject:objectToRemove];
    }
    [super exitEditingMode];
    [self.tableView deleteRowsAtIndexPaths:selectedRowsIndexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (void)deleteObjectForIndexPath:(NSIndexPath*)indexPath
{
    NSUInteger index = (kBackgroundObjects + indexPath.row);
    SpriteObject *object = (SpriteObject*)[self.program.objectList objectAtIndex:index];
    [self.imageCache removeObjectForKey:object.name];
    [self.program removeObject:object];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSectionsInProgramTableViewController;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kBackgroundSectionIndex:
            return [self.program numberOfBackgroundObjects];
        case kObjectSectionIndex:
            return [self.program numberOfNormalObjects];
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = kImageCell;
    static NSString *DetailCellIdentifier = kDetailImageCell;
    UITableViewCell *cell = nil;
    if (! self.useDetailCells) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:DetailCellIdentifier forIndexPath:indexPath];
    }
    if (! [cell conformsToProtocol:@protocol(CatrobatImageCell)]) {
        return cell;
    }
    UITableViewCell<CatrobatImageCell> *imageCell = (UITableViewCell<CatrobatImageCell>*)cell;
    NSInteger index = (kBackgroundSectionIndex + indexPath.section + indexPath.row);
    SpriteObject *object = [self.program.objectList objectAtIndex:index];
    imageCell.iconImageView.image = nil;
    [imageCell.iconImageView setBorder:[UIColor skyBlueColor] Width:kDefaultImageCellBorderWidth];
    imageCell.backgroundColor = UIColor.darkBlueColor;
    if (! [object.lookList count]) {
        imageCell.titleLabel.text = object.name;
        return imageCell;
    }

    NSString *previewImagePath = [object previewImagePath];
    UIImage *image = [self.imageCache objectForKey:object.name];
    imageCell.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    if (! image) {
        imageCell.iconImageView.image = nil;
        imageCell.indexPath = indexPath;
        if (previewImagePath) {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            dispatch_async(queue, ^{
                UIImage *image = [[UIImage alloc] initWithContentsOfFile:previewImagePath];
                // perform UI stuff on main queue (UIKit is not thread safe!!)
                dispatch_sync(dispatch_get_main_queue(), ^{
                    // check if cell still needed
                    if ([imageCell.indexPath isEqual:indexPath]) {
                        imageCell.iconImageView.image = image;
                        [imageCell setNeedsLayout];
                        [self.imageCache setObject:image forKey:object.name];
                    }
                });
            });
        } else {
            // fallback
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            dispatch_async(queue, ^{
                // TODO: outsource this "thumbnail generation code" to helper class
                Look* look = [object.lookList objectAtIndex:kBackgroundObjectIndex];
                NSString *newPreviewImagePath = [NSString stringWithFormat:@"%@%@/%@",
                                                 [object projectPath], kProgramImagesDirName,
                                                 [look previewImageFileName]];

                NSString *imagePath = [NSString stringWithFormat:@"%@%@/%@",
                                       [object projectPath], kProgramImagesDirName,
                                       look.fileName];
                UIImage *image = [UIImage imageWithContentsOfFile:imagePath];

                // generate thumbnail image (retina)
                CGSize previewImageSize = CGSizeMake(kPreviewImageWidth, kPreviewImageHeight);
                // determine aspect ratio
                if (image.size.height > image.size.width)
                    previewImageSize.width = (image.size.width*previewImageSize.width)/image.size.height;
                else
                    previewImageSize.height = (image.size.height*previewImageSize.height)/image.size.width;
                
                UIGraphicsBeginImageContext(previewImageSize);
                UIImage *previewImage = [image copy];
                [previewImage drawInRect:CGRectMake(0, 0, previewImageSize.width, previewImageSize.height)];
                previewImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                [UIImagePNGRepresentation(previewImage) writeToFile:newPreviewImagePath atomically:YES];

                dispatch_sync(dispatch_get_main_queue(), ^{
                    // check if cell still needed
                    if ([imageCell.indexPath isEqual:indexPath]) {
                        imageCell.iconImageView.image = previewImage;
                        [imageCell setNeedsLayout];
                        [self.imageCache setObject:previewImage forKey:object.name];
                    }
                });
            });
        }
    } else {
        imageCell.iconImageView.image = image;
    }
    if (self.useDetailCells && [cell isKindOfClass:[DarkBlueGradientImageDetailCell class]]) {
        DarkBlueGradientImageDetailCell *detailCell = (DarkBlueGradientImageDetailCell*)imageCell;
        detailCell.topLeftDetailLabel.textColor = [UIColor whiteColor];
        detailCell.topLeftDetailLabel.text = [NSString stringWithFormat:@"%@: %lu", kUILabelTextScripts,
                                              (unsigned long)[object numberOfScripts]];
        detailCell.topRightDetailLabel.textColor = [UIColor whiteColor];
        detailCell.topRightDetailLabel.text = [NSString stringWithFormat:@"%@: %lu", kUILabelTextBricks,
                                               (unsigned long)[object numberOfTotalBricks]];
        detailCell.bottomLeftDetailLabel.textColor = [UIColor whiteColor];
        detailCell.bottomLeftDetailLabel.text = [NSString stringWithFormat:@"%@: %lu", kUILabelTextLooks,
                                                 (unsigned long)[object numberOfLooks]];
        detailCell.bottomRightDetailLabel.textColor = [UIColor whiteColor];
        detailCell.bottomRightDetailLabel.text = [NSString stringWithFormat:@"%@: %lu", kUILabelTextSounds,
                                                  (unsigned long)[object numberOfSounds]];
    }
    imageCell.titleLabel.text = object.name;
    return imageCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [TableUtil getHeightForImageCell];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // TODO: outsource to TableUtil
    switch (section) {
        case 0:
            return 45.0;
        case 1:
            return 50.0;
        default:
            return 45.0;
    }
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    // TODO: outsource to TableUtil
    //UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kTableHeaderIdentifier];
    // FIXME: HACK do not alloc init there. Use ReuseIdentifier instead!! But does lead to several issues...
    UITableViewHeaderFooterView *headerView = [[UITableViewHeaderFooterView alloc] init];
//    headerView.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"darkblue"]];

    CGFloat height = [self tableView:self.tableView heightForHeaderInSection:section]-10.0;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(13.0f, 0.0f, 265.0f, height)];

//    CALayer *layer = titleLabel.layer;
//    CALayer *bottomBorder = [CALayer layer];
//    bottomBorder.borderColor = [UIColor airForceBlueColor].CGColor;
//    bottomBorder.borderWidth = 1;
//    bottomBorder.frame = CGRectMake(0, layer.frame.size.height-1, layer.frame.size.width, 1);
//    [bottomBorder setBorderColor:[UIColor airForceBlueColor].CGColor];
//    [layer addSublayer:bottomBorder];

    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.tag = 1;
    titleLabel.font = [UIFont systemFontOfSize:14.0f];
    if (section == 0) {
        titleLabel.text = [kUILabelTextBackground uppercaseString];
    } else {
        titleLabel.text = (([self.program numberOfNormalObjects] != 1)
                        ? [kUILabelTextObjectPlural uppercaseString]
                        : [kUILabelTextObjectSingular uppercaseString]);
    }
    titleLabel.text = [NSString stringWithFormat:@"  %@", titleLabel.text];
    [headerView.contentView addSubview:titleLabel];
    return headerView;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ((indexPath.section == kObjectSectionIndex)
            && ([self.program numberOfNormalObjects] > kMinNumOfObjects));
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == kObjectSectionIndex) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
            [self performActionOnConfirmation:@selector(deleteObjectForIndexPath:)
                               canceledAction:nil
                                   withObject:indexPath
                                       target:self
                                 confirmTitle:kUIAlertViewTitleDeleteSingleObject
                               confirmMessage:kUIAlertViewMessageIrreversibleAction];
        }
    }
}

#pragma mark - segue handler
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Pass the selected object to the new view controller.
    static NSString *toObjectSegue1ID = kSegueToObject1;
    static NSString *toObjectSegue2ID = kSegueToObject2;
    static NSString *toSceneSegueID = kSegueToScene;

    UIViewController *destController = segue.destinationViewController;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell*) sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        if ([segue.identifier isEqualToString:toObjectSegue1ID] || [segue.identifier isEqualToString:toObjectSegue2ID]) {
            if ([destController isKindOfClass:[ObjectTableViewController class]]) {
                ObjectTableViewController *tvc = (ObjectTableViewController*) destController;
                if ([tvc respondsToSelector:@selector(setObject:)]) {
                    SpriteObject* object = [self.program.objectList objectAtIndex:(kBackgroundObjectIndex + indexPath.section + indexPath.row)];
                    [destController performSelector:@selector(setObject:) withObject:object];
                }
            }
        }
    } else if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        if ([segue.identifier isEqualToString:toSceneSegueID]) {
            if ([destController isKindOfClass:[ScenePresenterViewController class]]) {
                ScenePresenterViewController* scvc = (ScenePresenterViewController*) destController;
                if ([scvc respondsToSelector:@selector(setProgram:)]) {
                    [scvc setController:(UITableViewController *)self];
                    [scvc performSelector:@selector(setProgram:) withObject:self.program];
                }
            }
        }
    }
}

#pragma mark - text field delegates
- (BOOL)textField:(UITextField *)field shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)characters
{
    return ([characters rangeOfCharacterFromSet:self.blockedCharacterSet].location == NSNotFound);
}

#pragma mark - action sheet delegates
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag != kEditProgramActionSheetTag) {
        return;
    }

    if (buttonIndex == 1) {
        // Rename button
        [Util promptWithTitle:kUIAlertViewTitleRenameProgram
                      message:[NSString stringWithFormat:@"%@:", kUIAlertViewMessageProgramName]
                     delegate:self
                  placeholder:kUIAlertViewPlaceholderEnterProgramName
                          tag:kRenameAlertViewTag
                        value:((! [self.program.header.programName isEqualToString:kGeneralNewDefaultProgramName])
                               ? self.program.header.programName : nil)
            textFieldDelegate:self];
    } else if (buttonIndex == 2 && [self.program numberOfNormalObjects]) {
        // Delete Objects button
        [self setupEditingToolBar];
        [super changeToEditingMode:actionSheet];
    } else if (buttonIndex == 3 || ((buttonIndex == 2) && (! [self.program numberOfNormalObjects]))) {
        // Show/Hide Details button
        self.useDetailCells = (! self.useDetailCells);
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *showDetails = [defaults objectForKey:kUserDetailsShowDetailsKey];
        NSMutableDictionary *showDetailsMutable = nil;
        if (! showDetails) {
            showDetailsMutable = [NSMutableDictionary dictionary];
        } else {
            showDetailsMutable = [showDetails mutableCopy];
        }
        [showDetailsMutable setObject:[NSNumber numberWithBool:self.useDetailCells]
                               forKey:kUserDetailsShowDetailsObjectsKey];
        [defaults setObject:showDetailsMutable forKey:kUserDetailsShowDetailsKey];
        [defaults synchronize];
        [self.tableView reloadData];
    } else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        // Delete Program button
        [self.delegate removeProgram:self.program.header.programName];
        [self.program removeFromDisk];
        self.program = nil;
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - alert view delegate handlers
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [super alertView:alertView clickedButtonAtIndex:buttonIndex];
    if (alertView.tag == kRenameAlertViewTag) {
        NSString* input = [alertView textFieldAtIndex:0].text;
        if (buttonIndex == kAlertViewButtonOK) {
            if ([input isEqualToString:self.program.header.programName])
                return;

            kProgramNameValidationResult validationResult = [Program validateProgramName:input];
            if (validationResult == kProgramNameValidationResultInvalid) {
                [Util alertWithText:kUIAlertViewMessageInvalidProgramName
                           delegate:self
                                tag:kInvalidProgramNameWarningAlertViewTag];
            } else if (validationResult == kProgramNameValidationResultAlreadyExists) {
                [Util alertWithText:kUIAlertViewMessageProgramNameAlreadyExists
                           delegate:self
                                tag:kInvalidProgramNameWarningAlertViewTag];
            } else if (validationResult == kProgramNameValidationResultOK) {
                NSString *oldProgramName = self.program.header.programName;
                [self.program renameToProgramName:input];
                [self.delegate renameOldProgramName:oldProgramName ToNewProgramName:input];
                [self.program setAsLastProgram];
                self.navigationItem.title = self.title = input;
            }
        }
    }
    if (alertView.tag == kNewObjectAlertViewTag) {
        NSString* input = [alertView textFieldAtIndex:0].text;
        if (buttonIndex != kAlertViewButtonOK) {
            return;
        }
        if (! [input length]) {
            [Util alertWithText:kUIAlertViewMessageInvalidObjectName
                       delegate:self
                            tag:kInvalidObjectNameWarningAlertViewTag];
            return;
        }
        [self.program addNewObjectWithName:input];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)]
                      withRowAnimation:UITableViewRowAnimationNone];
    }
    if (alertView.tag == kInvalidProgramNameWarningAlertViewTag) {
        // title of cancel button is "OK"
        if (buttonIndex == 0) {
            [Util promptWithTitle:kUIAlertViewTitleRenameProgram
                          message:[NSString stringWithFormat:@"%@:", kUIAlertViewMessageProgramName]
                         delegate:self
                      placeholder:kUIAlertViewPlaceholderEnterProgramName
                              tag:kRenameAlertViewTag
                            value:((! [self.program.header.programName isEqualToString:kGeneralNewDefaultProgramName])
                                   ? self.program.header.programName : nil)
                textFieldDelegate:self];
        }
    }
}

#pragma mark - helpers
- (void)setupToolBar
{
    [super setupToolBar];
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil
                                                                              action:nil];
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                         target:self
                                                                         action:@selector(addObjectAction:)];
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

- (void)setupEditingToolBar
{
    [super setupEditingToolBar];
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil
                                                                              action:nil];
    UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithTitle:kUIBarButtonItemTitleDelete
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(confirmDeleteSelectedObjectsAction:)];
    // XXX: workaround for tap area problem:
    // http://stackoverflow.com/questions/5113258/uitoolbar-unexpectedly-registers-taps-on-uibarbuttonitem-instances-even-when-tap
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"transparent1x1"]];
    UIBarButtonItem *invisibleButton = [[UIBarButtonItem alloc] initWithCustomView:imageView];
    self.toolbarItems = [NSArray arrayWithObjects:self.selectAllRowsButtonItem, invisibleButton, flexItem,
                         invisibleButton, deleteButton, nil];
}

@end
