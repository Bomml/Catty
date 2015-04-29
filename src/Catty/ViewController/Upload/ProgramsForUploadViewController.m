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

#import "ProgramsForUploadViewController.h"
#import "LanguageTranslationDefines.h"
#import "Program.h"
#import "CellTagDefines.h"
#import "UIColor+CatrobatUIColorExtensions.h"
#import "CatrobatImageCell.h"
#import "CatrobatBaseCell.h"
#import "TableUtil.h"
#import "ProgramLoadingInfo.h"
#import "UIDefines.h"
#import "UIImageView+CatrobatUIImageViewExtensions.h"
#import "FileManager.h"
#import "RuntimeImageCache.h"
#import "AppDelegate.h"
#import "Util.h"
#import "UploadInfoPopupViewController.h"


@interface ProgramsForUploadViewController ()

@property (nonatomic, strong) Program *lastUsedProgram;
@property (nonatomic, strong) NSMutableArray *programLoadingInfos;
@property (nonatomic, strong) UIBarButtonItem *uploadButton;
@property (nonatomic, strong) NSIndexPath *lastSelectedIndexPath;

@end


@implementation ProgramsForUploadViewController

#pragma mark - View Events
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.title = self.title = kLocalizedUploadProgram;
    self.programLoadingInfos = [[Program allProgramLoadingInfos] mutableCopy];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setupToolBar];
    self.navigationController.toolbarHidden = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController setToolbarHidden:NO];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - system events
- (void)dealloc
{
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    self.programLoadingInfos = nil;
}

#pragma mark - getters and setters
- (Program*)lastUsedProgram
{
    if (! _lastUsedProgram) {
        _lastUsedProgram = [Program lastUsedProgram];
    }
    return _lastUsedProgram;
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.programLoadingInfos count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = kImageCell;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (! [cell isKindOfClass:[CatrobatBaseCell class]] || ! [cell conformsToProtocol:@protocol(CatrobatImageCell)]) {
        return cell;
    }
    
    CatrobatBaseCell<CatrobatImageCell> *imageCell = (CatrobatBaseCell<CatrobatImageCell>*)cell;
    [self configureImageCell:imageCell atIndexPath:indexPath];
    
    return imageCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [TableUtil heightForImageCell];
}

#pragma mark - table view helpers
- (void)configureImageCell:(CatrobatBaseCell<CatrobatImageCell>*)cell atIndexPath:(NSIndexPath*)indexPath
{
    ProgramLoadingInfo *info = [self.programLoadingInfos objectAtIndex:indexPath.row];
    cell.titleLabel.text = info.visibleName;
    cell.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.rightUtilityButtons = nil;
    //cell.delegate = self;
    cell.iconImageView.image = nil;
    cell.indexPath = indexPath;
    [cell.iconImageView setBorder:[UIColor skyBlueColor] Width:kDefaultImageCellBorderWidth];
    
    // check if one of these screenshot files is available in memory
    FileManager *fileManager = ((AppDelegate*)[UIApplication sharedApplication].delegate).fileManager;
    NSArray *fallbackPaths = @[[[NSString alloc] initWithFormat:@"%@small_screenshot.png", info.basePath],
                               [[NSString alloc] initWithFormat:@"%@screenshot.png", info.basePath],
                               [[NSString alloc] initWithFormat:@"%@manual_screenshot.png", info.basePath],
                               [[NSString alloc] initWithFormat:@"%@automatic_screenshot.png", info.basePath]];
    RuntimeImageCache *imageCache = [RuntimeImageCache sharedImageCache];
    for (NSString *fallbackPath in fallbackPaths) {
        NSString *fileName = [fallbackPath lastPathComponent];
        NSString *thumbnailPath = [NSString stringWithFormat:@"%@%@%@",
                                   info.basePath, kScreenshotThumbnailPrefix, fileName];
        UIImage *image = [imageCache cachedImageForPath:thumbnailPath];
        if (image) {
            cell.iconImageView.image = image;
            return;
        }
    }
    
    // no screenshot files in memory, check if one of these screenshot files exists on disk
    // if a screenshot file is found, then load it from disk and cache it in memory for future access
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        for (NSString *fallbackPath in fallbackPaths) {
            if ([fileManager fileExists:fallbackPath]) {
                NSString *fileName = [fallbackPath lastPathComponent];
                NSString *thumbnailPath = [NSString stringWithFormat:@"%@%@%@",
                                           info.basePath, kScreenshotThumbnailPrefix, fileName];
                [imageCache loadThumbnailImageFromDiskWithThumbnailPath:thumbnailPath
                                                              imagePath:fallbackPath
                                                     thumbnailFrameSize:CGSizeMake(kPreviewImageWidth, kPreviewImageHeight)
                                                           onCompletion:^(UIImage *image){
                                                               // check if cell still needed
                                                               if ([cell.indexPath isEqual:indexPath]) {
                                                                   cell.iconImageView.image = image;
                                                                   [cell setNeedsLayout];
                                                                   [self.tableView endUpdates];
                                                               }
                                                           }];
                return;
            }
        }
        
        // no screenshot file available -> last fallback, show standard program icon instead
        [imageCache loadImageWithName:@"programs" onCompletion:^(UIImage *image){
            // check if cell still needed
            if ([cell.indexPath isEqual:indexPath]) {
                cell.iconImageView.image = image;
                [cell setNeedsLayout];
                [self.tableView endUpdates];
            }
        }];
    });
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
    if (self.lastSelectedIndexPath) {
        UITableViewCell *lastCell = [tableView cellForRowAtIndexPath:self.lastSelectedIndexPath];
        lastCell.accessoryType = UITableViewCellAccessoryNone;

        // if user taps twice on same cell than cell should be deselected
        if (self.lastSelectedIndexPath.row == indexPath.row) {
            UITableViewCell *lastCell = [tableView cellForRowAtIndexPath:self.lastSelectedIndexPath];
            lastCell.accessoryType = UITableViewCellAccessoryNone;
            self.lastSelectedIndexPath = nil;
            return;
        }
    }

    currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
    self.lastSelectedIndexPath = indexPath;
    self.lastUsedProgram = [Program programWithLoadingInfo:[self.programLoadingInfos objectAtIndex:self.lastSelectedIndexPath.row]];
}

#pragma mark - Actions
- (void)uploadProgramAction:(id)sender
{
    NSDebug(@"Upload program: %@", self.lastUsedProgram.header.programName);
    
    /*
     ProgramLoadingInfo *info = self.programLoadingInfos.firstObject;
     NSDebug(@"%@", info.basePath);
     */
    
    [self showUploadInfoView];
}

#pragma mark - Helpers
- (void)setupToolBar
{
    [super setupToolBar];
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil
                                                                              action:nil];
    
    self.uploadButton = [[UIBarButtonItem alloc] initWithTitle:kLocalizedUpload
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(uploadProgramAction:)];
    
    [self.uploadButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0f], NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    self.toolbarItems = @[flexItem, self.uploadButton, flexItem];
}

- (void)showUploadInfoView
{
    if (self.popupViewController == nil) {
        UploadInfoPopupViewController *popupViewController = [[UploadInfoPopupViewController alloc] init];
        popupViewController.delegate = self;
        
        if (self.lastSelectedIndexPath) {
            popupViewController.program = self.lastUsedProgram;
            
            self.tableView.scrollEnabled = NO;
            [self presentPopupViewController:popupViewController WithFrame:self.tableView.frame upwardsCenterByFactor:4.5];
            self.navigationItem.leftBarButtonItem.enabled = NO;
            self.uploadButton.enabled = NO;
        } else {
            NSDebug(@"Please select a program to upload");
            [Util alertWithText:kLocalizedUploadSelectProgram];
        }
    } else {
        [self dismissPopupWithCode:NO];
    }
}

#pragma mark - popup delegate
- (BOOL)dismissPopupWithCode:(BOOL)uploadSuccessfull
{
    if (self.popupViewController != nil) {
        self.tableView.scrollEnabled = YES;
        self.uploadButton.enabled = YES;
        [self dismissPopupViewController];
        self.navigationItem.leftBarButtonItem.enabled = YES;
        if (uploadSuccessfull) {
            [Util alertWithText:kLocalizedUploadSuccessfull];
        }
        return YES;
    }
    return NO;
}


@end
