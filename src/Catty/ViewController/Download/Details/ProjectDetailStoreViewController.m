/**
 *  Copyright (C) 2010-2021 The Catrobat Team
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

#import "ProjectDetailStoreViewController.h"
#import "CBFileManager.h"
#import "ButtonTags.h"
#import "SegueDefines.h"
#import "SceneTableViewController.h"
#import "Util.h"
#import "EVCircularProgressView.h"
#import "KeychainUserDefaultsDefines.h"
#import "Pocket_Code-Swift.h"
#import "EVCircularProgressView.h"
#import "RoundBorderedButton.h"

@interface ProjectDetailStoreViewController ()

@property (nonatomic, strong) UIView *projectView;
@property (nonatomic, strong) LoadingView *loadingView;
@property (nonatomic, strong) Project *loadedProject;
@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURLSessionDataTask *dataTask;

@end

@implementation ProjectDetailStoreViewController

- (NSMutableDictionary*)projects
{
    if (!_projects) {
        _projects = [[NSMutableDictionary alloc] init];
    }
    return _projects;
}

- (NSURLSession *)session {
    if (!_session) {
        // Initialize Session Configuration
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        // Configure Session Configuration
        [sessionConfiguration setHTTPAdditionalHeaders:@{ @"Accept" : @"application/json" }];
        
        // Initialize Session
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    }
    
    return _session;
}

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
    [self initNavigationBar];
    self.hidesBottomBarWhenPushed = YES;
    self.view.backgroundColor = UIColor.background;
    NSDebug(@"%@",self.project.author);
    [self loadProject:self.project];
    CBFileManager *fileManager = [CBFileManager sharedManager];
    fileManager.delegate = self;
    fileManager.projectURL = [NSURL URLWithString:self.project.downloadUrl];
}

-(void)loadProject:(CatrobatProject*)project {
    [self.projectView removeFromSuperview];
    self.projectView = [self createViewForProject:project];
    if(!self.project.author){
        [self showLoadingView];
        UIButton * button =(UIButton*)[self.projectView viewWithTag:kDownloadButtonTag];
        button.enabled = NO;
    }
    CGFloat minHeight = self.view.frame.size.height;
    [self.scrollViewOutlet addSubview:self.projectView];
    self.scrollViewOutlet.delegate = self;
    CGSize contentSize = self.projectView.bounds.size;
    
    if (contentSize.height < minHeight) {
        contentSize.height = minHeight;
    }
    contentSize.height += 30.0f;
    [self.scrollViewOutlet setContentSize:contentSize];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.scrollViewOutlet.userInteractionEnabled = YES;
}
- (void)initNavigationBar
{
    self.title = self.navigationItem.title = kLocalizedDetails;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.hidesBottomBarWhenPushed = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIView*)createViewForProject:(CatrobatProject*)project
{
    UIView *view = [self createProjectDetailView:project target:self];
    return view;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
    self.loadedProject = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc
{
    [self setScrollViewOutlet:nil];
}

#pragma mark - ProjectStore Delegate

- (void)openButtonPressed:(id)sender
{
    
    NSString *localProjectName = [Project projectNameForProjectID:self.project.projectID];
    
    [self showLoadingView];
    [CATransaction flush];
    
    self.loadedProject = [Project projectWithLoadingInfo:[ProjectLoadingInfo projectLoadingInfoForProjectWithName:localProjectName projectID:self.project.projectID]];
    
    [self hideLoadingView];
    
    if (!self.loadedProject) {
        [Util alertWithText:kLocalizedUnableToLoadProject];
        return;
    }
    
    [self openProject:self.loadedProject];
}

- (void)downloadButtonPressed
{
    NSDebug(@"Download Button!");
    EVCircularProgressView* button = (EVCircularProgressView*)[self.projectView viewWithTag:kStopLoadingTag];
    [self.projectView viewWithTag:kDownloadButtonTag].hidden = YES;
    button.hidden = NO;
    button.progress = 0;
    NSString* duplicateName = [Util uniqueName:self.project.name existingNames:[Project allProjectNames]];
    [self downloadWithName:duplicateName];
}

- (void)downloadButtonPressed:(id)sender
{
    [self downloadButtonPressed];
}

- (void) reportProject:(id)sender;
{
    [self reportProject];
}

-(void)downloadAgain:(id)sender
{
    EVCircularProgressView* button = (EVCircularProgressView*)[self.projectView viewWithTag:kStopLoadingTag];
    [self.projectView viewWithTag:kOpenButtonTag].hidden = YES;
    UIButton* downloadAgainButton = (UIButton*)[self.projectView viewWithTag:kDownloadAgainButtonTag];
    downloadAgainButton.enabled = NO;
    button.hidden = NO;
    button.progress = 0;
    NSString* duplicateName = [Util uniqueName:self.project.name existingNames:[Project allProjectNames]];
    NSDebug(@"%@",[Project allProjectNames]);
    [self downloadWithName:duplicateName];
}

-(void)downloadWithName:(NSString*)name
{
    NSURL *url = [NSURL URLWithString:self.project.downloadUrl];
    CBFileManager *fileManager = [CBFileManager sharedManager];
    fileManager.delegate = self;
    [fileManager downloadProjectFromURL:url withProjectID:self.project.projectID andName:name];
    self.project.isdownloading = YES;
    [self.projects setObject:self.project forKey:url];
    [self reloadInputViews];
}

#pragma mark - File Manager Delegate
- (void) downloadFinishedWithURL:(NSURL*)url andProjectLoadingInfo:(ProjectLoadingInfo *)info
{
    NSDebug(@"Download Finished!!!!!!");
    self.project.isdownloading = NO;
    [self.projects removeObjectForKey:url];
    EVCircularProgressView* button = (EVCircularProgressView*)[self.view viewWithTag:kStopLoadingTag];
    button.hidden = YES;
    button.progress = 0;
    [self.view viewWithTag:kOpenButtonTag].hidden = NO;
    UIButton* downloadAgainButton = (UIButton*)[self.projectView viewWithTag:kDownloadAgainButtonTag];
    downloadAgainButton.enabled = YES;
    downloadAgainButton.hidden = NO;
    [self loadingIndicator:NO];
}

#pragma mark - TTTAttributedLabelDelegate
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber
{
    UIDevice *device = [UIDevice currentDevice];
    if ([[device model] isEqualToString:@"iPhone"] ) {
        NSString *escapedPhoneNumber = [phoneNumber stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]];
        NSString *phoneURLString = [NSString stringWithFormat:@"telprompt:%@", escapedPhoneNumber];
        NSURL *url = [NSURL URLWithString:phoneURLString];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)reloadWithProject:(CatrobatProject *)loadedProject
{
    [self loadProject:loadedProject];
    UIButton * button =(UIButton*)[self.projectView viewWithTag:kDownloadButtonTag];
    button.enabled = YES;
    [self hideLoadingView];
    [self.view setNeedsDisplay];
}

#pragma mark - loading view
- (void)showLoadingView
{
    if(!self.loadingView) {
        self.loadingView = [[LoadingView alloc] init];
        [self.view addSubview:self.loadingView];
    }
    [self.loadingView show];
}

- (void) hideLoadingView
{
    [self.loadingView hide];
}

#pragma mark - actions
- (void)stopLoading
{
    NSURL *url = [NSURL URLWithString:self.project.downloadUrl];
    CBFileManager *fileManager = [CBFileManager sharedManager];
    [fileManager stopLoading:url];
    fileManager.delegate = self;
    EVCircularProgressView* button = (EVCircularProgressView*)[self.view viewWithTag:kStopLoadingTag];
    button.hidden = YES;
    button.progress = 0;
    UIButton* downloadAgainButton = (UIButton*)[self.projectView viewWithTag:kDownloadAgainButtonTag];
    if(downloadAgainButton.enabled){
        [self.view viewWithTag:kDownloadButtonTag].hidden = NO;
    } else {
        [self.view viewWithTag:kOpenButtonTag].hidden = NO;
        downloadAgainButton.enabled = YES;
    }
    [self loadingIndicator:NO];
    
}
- (void)updateProgress:(double)progress
{
    NSDebug(@"updateProgress:%f",((float)progress));
    EVCircularProgressView* button = (EVCircularProgressView*)[self.view viewWithTag:kStopLoadingTag];
    [button setProgress:progress animated:YES];
}

- (void)timeoutReached
{
    [self setBackDownloadStatus];
    [Util defaultAlertForNetworkError];
}

- (void)maximumFilesizeReached
{
    [self setBackDownloadStatus];
    [Util alertWithText:kLocalizedNotEnoughFreeMemoryDescription];
}

- (void)fileNotFound
{
    [self setBackDownloadStatus];
    [Util alertWithText:kLocalizedProjectNotFound];
}

- (void)invalidZip
{
    [self setBackDownloadStatus];
    [Util alertWithText:kLocalizedInvalidZip];
}

- (void)setBackDownloadStatus
{
    [self.view viewWithTag:kDownloadButtonTag].hidden = NO;
    [self.view viewWithTag:kOpenButtonTag].hidden = YES;
    [self.view viewWithTag:kStopLoadingTag].hidden = YES;
    [self.view viewWithTag:kDownloadAgainButtonTag].hidden = YES;
    [self loadingIndicator:NO];
}

- (void)loadingIndicator:(BOOL)value
{
    UIApplication* app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = value;
}

#pragma mark Rotation

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadProject:self.project];
        [self.view setNeedsDisplay];
    });
}

@end
