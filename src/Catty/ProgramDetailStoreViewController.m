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

#import "ProgramDetailStoreViewController.h"
#import "CatrobatProject.h"
#import "CreateView.h"
#import "AppDelegate.h"
#import "TableUtil.h"
#import "ButtonTags.h"
#import "UIColor+CatrobatUIColorExtensions.h"
#import "SegueDefines.h"
#import "SceneViewController.h"
#import "ProgramLoadingInfo.h"
#import "Util.h"

#define kUIBarHeight 49
#define kNavBarHeight 44

#define kScrollViewOffset 20.0f

@interface ProgramDetailStoreViewController ()

@property (nonatomic, strong) UIView* projectView;

@end


@implementation ProgramDetailStoreViewController

@synthesize project = _project;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor darkBlueColor];
    [TableUtil initNavigationItem:self.navigationItem withTitle:@"Info" enableBackButton:YES target:self];
    
    self.projectView = [self createViewForProject:self.project];
    [self.scrollViewOutlet addSubview:self.projectView];
    self.scrollViewOutlet.delegate = self;
    
    CGSize contentSize = self.projectView.bounds.size;
    CGFloat minHeight = self.view.frame.size.height-kUIBarHeight-kNavBarHeight;
    if(contentSize.height < minHeight) {
        contentSize.height = minHeight;
    }
    contentSize.height += kScrollViewOffset;
    [self.scrollViewOutlet setContentSize:contentSize];
    self.scrollViewOutlet.userInteractionEnabled = YES;
    self.scrollViewOutlet.exclusiveTouch = YES;

}

- (void) viewWillDisappear:(BOOL)animated
{
    self.hidesBottomBarWhenPushed = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UIView*)createViewForProject:(CatrobatProject*)project {
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    UIView *view = [CreateView createProgramDetailView:self.project target:self];
    if ([appDelegate.fileManager getPathForLevel:self.project.projectName]) {
        [view viewWithTag:kDownloadButtonTag].hidden = YES;
        [view viewWithTag:kPlayButtonTag].hidden = NO;
    }
    
    return view;
}

-(void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidUnload {
    [self setScrollViewOutlet:nil];
    [super viewDidUnload];
}

#pragma mark - Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueToScene]) {
        if ([segue.destinationViewController isKindOfClass:[SceneViewController class]]){
            self.hidesBottomBarWhenPushed = YES;
            SceneViewController *destination = (SceneViewController*)segue.destinationViewController;
            destination.programLoadingInfo = [Util programLoadingInfoForProgramWithName:self.project.name];            
        }
    }
}


# pragma mark - LevelStore Delegate
- (void) playButtonPressed
{
    NSDebug(@"Play Button");
    [self performSegueWithIdentifier:kSegueToScene sender:self];
}


- (void) downloadButtonPressed
{
    NSDebug(@"Download Button!");
    UIButton* downloadButton = (UIButton*)[self.projectView viewWithTag:kDownloadButtonTag];
    NSString* title = [[NSString alloc] initWithFormat:@"%@...", NSLocalizedString(@"Loading", nil)];
    [downloadButton setTitle:title forState:UIControlStateNormal];
    [downloadButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 25.0f, 0.0f, 0.0f)];
    downloadButton.enabled = NO;
    downloadButton.backgroundColor = [UIColor grayColor];

    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSURL *url = [NSURL URLWithString:self.project.downloadUrl];
    
    UIActivityIndicatorView *activity = (UIActivityIndicatorView*)[downloadButton viewWithTag:kActivityIndicator];
    [activity startAnimating];
    
    [appDelegate.fileManager downloadFileFromURL:url withName:self.project.projectName];
    appDelegate.fileManager.delegate = self;
}

#pragma mark - File Manager Delegate
- (void) downloadFinished
{
    NSLog(@"Download Finished!!!!!!");
    [self.projectView viewWithTag:kDownloadButtonTag].hidden = YES;
    [self.projectView viewWithTag:kPlayButtonTag].hidden = NO;
    
}


#pragma mark - TTTAttributedLabelDelegate

-(void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

-(void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber
{
    UIDevice *device = [UIDevice currentDevice];
    if ([[device model] isEqualToString:@"iPhone"] ) {
        //NSString* telpromt = [phoneNumber stringByReplacingOccurrencesOfString:@"tel:" withString:@""];
        NSString *cleanedString = [[phoneNumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
        NSString *escapedPhoneNumber = [cleanedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *phoneURLString = [NSString stringWithFormat:@"telprompt:%@", escapedPhoneNumber];
        NSURL *url = [NSURL URLWithString:phoneURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}


@end
