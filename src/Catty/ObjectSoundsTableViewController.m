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

#import "ObjectSoundsTableViewController.h"
#import "UIDefines.h"
#import "TableUtil.h"
#import "CatrobatImageCell.h"
#import "Sound.h"
#import "SegueDefines.h"
#import "ActionSheetAlertViewTags.h"
#import "ScenePresenterViewController.h"
#import "SpriteObject.h"
#import "AudioManager.h"
#import "ProgramDefines.h"
#import "Util.h"
#import <AVFoundation/AVFoundation.h>

#define kTableHeaderIdentifier @"Header"
#define kPocketCodeRecorderActionSheetButton @"pocketCodeRecorder"
#define kSelectMusicTrackActionSheetButton @"selectMusicTrack"

@interface ObjectSoundsTableViewController () <UIActionSheetDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) NSMutableDictionary* addSoundActionSheetBtnIndexes;
@property (atomic, strong) Sound *currentPlayingSong;
@property (atomic, weak) UITableViewCell<CatrobatImageCell> *currentPlayingSongCell;

@end

@implementation ObjectSoundsTableViewController

#pragma getters and setters
- (NSMutableDictionary*)addSoundActionSheetBtnIndexes
{
    // lazy instantiation
    if (_addSoundActionSheetBtnIndexes == nil)
        _addSoundActionSheetBtnIndexes = [NSMutableDictionary dictionaryWithCapacity:3];
    return _addSoundActionSheetBtnIndexes;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.currentPlayingSong = nil;
    self.currentPlayingSongCell = nil;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    [self initTableView];
    [super initPlaceHolder];
    [super setPlaceHolderTitle:kSoundsTitle
                   Description:[NSString stringWithFormat:NSLocalizedString(kEmptyViewPlaceHolder, nil), kSoundsTitle]];
    [super showPlaceHolder:(! (BOOL)[self.object.soundList count])];
    //[TableUtil initNavigationItem:self.navigationItem withTitle:NSLocalizedString(@"New Programs", nil)];
    
    self.title = self.object.name;
    self.navigationItem.title = self.object.name;
    [self setupToolBar];
}

-(void)dealloc
{
    [[AudioManager sharedAudioManager] stopAllSounds];
    self.currentPlayingSong.playing = NO;
    self.currentPlayingSong = nil;
    self.currentPlayingSongCell = nil;
}

#pragma marks init
- (void)initTableView
{
    [super initTableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"darkblue"]];
    UITableViewHeaderFooterView *headerViewTemplate = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:kTableHeaderIdentifier];
    headerViewTemplate.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"darkblue"]];
    [self.tableView addSubview:headerViewTemplate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.object.soundList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SoundCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if ([cell conformsToProtocol:@protocol(CatrobatImageCell)]) {
        UITableViewCell <CatrobatImageCell>* imageCell = (UITableViewCell <CatrobatImageCell>*)cell;
        imageCell.iconImageView.image = [UIImage imageNamed:@"ic_media_play.png"];
        imageCell.titleLabel.text = ((Sound*) [self.object.soundList objectAtIndex:indexPath.row]).name;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [TableUtil getHeightForImageCell];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell conformsToProtocol:@protocol(CatrobatImageCell)]) {
        UITableViewCell <CatrobatImageCell>* imageCell = (UITableViewCell <CatrobatImageCell>*)cell;
        
        if (indexPath.row < [self.object.soundList count]) {
            // synchronized to guarantee that the player never plays two (different) songs at the same time
            // INFO: there are no operations that take much time, therefore synchronized will be no problem here
            @synchronized(self) {
                Sound* sound = (Sound*) [self.object.soundList objectAtIndex:indexPath.row];
                BOOL isPlaying = sound.playing;
                if (self.currentPlayingSong && self.currentPlayingSongCell) {
                    self.currentPlayingSong.playing = NO;
                    self.currentPlayingSongCell.iconImageView.image = [UIImage imageNamed:@"ic_media_play.png"];
                }
                self.currentPlayingSong = sound;
                self.currentPlayingSongCell = imageCell;
                self.currentPlayingSong.playing = (! isPlaying);
                self.currentPlayingSongCell.iconImageView.image = [UIImage imageNamed:@"ic_media_play.png"];
                if (! isPlaying)
                    imageCell.iconImageView.image = [UIImage imageNamed:@"ic_media_pause.png"];
                
                // INFO: the synchronized-lock will be released immediatelly by the main-thread itself,
                //       because the long-time operations are performed on another thread AFTER the lock is released
                dispatch_queue_t audioPlayerQueue = dispatch_queue_create("audio player", NULL);
                dispatch_async(audioPlayerQueue, ^{
                    [[AudioManager sharedAudioManager] stopAllSounds];
                    if (! isPlaying)
                        [[AudioManager sharedAudioManager] playSoundWithFileName:sound.fileName
                                                                          andKey:self.object.name
                                                                      atFilePath:[self.object projectPath]
                                                                        Delegate:self];
                });
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma audio delegate methods
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    // mark all sounds as stopped
    // switch back to main thread here, since UI-actions have to be performed on main thread!!
    dispatch_async(dispatch_get_main_queue(), ^{
        // FIXME: fix possible concurrency issue with didSelectRowAtIndexPath
        @synchronized(self) {
            if (self.currentPlayingSong && self.currentPlayingSongCell) {
                self.currentPlayingSong.playing = NO;
                self.currentPlayingSongCell.iconImageView.image = [UIImage imageNamed:@"ic_media_play.png"];
            }
            self.currentPlayingSong = nil;
            self.currentPlayingSongCell = nil;
        }
    });
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    static NSString *toSceneSegueID = kSegueToScene;
    UIViewController *destController = segue.destinationViewController;
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

#pragma mark - UIActionSheetDelegate Handlers
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == kAddSoundActionSheetTag) {
        NSString *action = self.addSoundActionSheetBtnIndexes[@(buttonIndex)];
        if ([action isEqualToString:kPocketCodeRecorderActionSheetButton]) {
            // Pocket Code Recorder
            NSLog(@"Pocket Code Recorder");
            [Util showComingSoonAlertView];
        } else if ([action isEqualToString:kSelectMusicTrackActionSheetButton]) {
            // Select music track
            NSLog(@"Select music track");
        }
    }
}

#pragma mark - UIActionSheet Views
- (void)showAddSoundActionSheet
{
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.title = NSLocalizedString(@"Add sound",@"Action sheet menu title");
    sheet.delegate = self;
    self.addSoundActionSheetBtnIndexes[@([sheet addButtonWithTitle:NSLocalizedString(@"Pocket Code Recorder",nil)])] = kPocketCodeRecorderActionSheetButton;
    
    //  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
    //    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    //    if ([availableMediaTypes containsObject:(NSString *)kUTTypeImage])
    //      self.addSoundActionSheetBtnIndexes[@([sheet addButtonWithTitle:NSLocalizedString(@"Choose image",nil)])] = kSelectMusicTrackActionSheetButton;
    //  }
    
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:kBtnCancelTitle];
    sheet.tag = kAddSoundActionSheetTag;
    sheet.actionSheetStyle = UIActionSheetStyleDefault;
    [sheet showInView:self.view];
}

#pragma mark - Helper Methods
- (void)addSoundAction:(id)sender
{
    [self showAddSoundActionSheet];
}

- (void)playSceneAction:(id)sender
{
    [self.navigationController setToolbarHidden:YES];
    [self performSegueWithIdentifier:kSegueToScene sender:sender];
}

- (void)setupToolBar
{
    [self.navigationController setToolbarHidden:NO];
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.tintColor = [UIColor orangeColor];
    self.navigationController.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil
                                                                              action:nil];
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                         target:self
                                                                         action:@selector(addSoundAction:)];
    UIBarButtonItem *play = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                          target:self
                                                                          action:@selector(playSceneAction:)];
    // XXX: workaround for tap area problem:
    // http://stackoverflow.com/questions/5113258/uitoolbar-unexpectedly-registers-taps-on-uibarbuttonitem-instances-even-when-tap
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"transparent1x1.png"]];
    UIBarButtonItem *invisibleButton = [[UIBarButtonItem alloc] initWithCustomView:imageView];
    self.toolbarItems = [NSArray arrayWithObjects:flexItem, invisibleButton, add, invisibleButton, flexItem,
                         flexItem, flexItem, invisibleButton, play, invisibleButton, flexItem, nil];
}

@end
