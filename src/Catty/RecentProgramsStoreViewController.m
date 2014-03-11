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

#import "RecentProgramsStoreViewController.h"
#import "CatrobatInformation.h"
#import "CatrobatProject.h"
#import "AppDelegate.h"
#import "Util.h"
#import "TableUtil.h"
#import "CellTagDefines.h"
#import "CatrobatImageCell.h"
#import "LoadingView.h"
#import "NetworkDefines.h"
#import "SegueDefines.h"
#import "ProgramDetailStoreViewController.h"

#import "UIImage+CatrobatUIImageExtensions.h"
#import "UIColor+CatrobatUIColorExtensions.h"


@interface RecentProgramsStoreViewController ()

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableArray *projects;
@property (nonatomic, strong) LoadingView* loadingView;
@property (assign)            int programListOffset;
@property (assign)            int programListLimit;

@end

@implementation RecentProgramsStoreViewController

@synthesize data              = _data;
@synthesize connection        = _connection;
@synthesize projects          = _projects;
@synthesize programListOffset = _programListOffset;
@synthesize programListLimit  = _programListLimit;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    self.programListLimit = 20;
    self.programListOffset = 0;
    
    [super viewDidLoad];
    [self loadProjects];
    [self initTableView];
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    self.tableView.contentInset = UIEdgeInsetsMake(navigationBarHeight, 0, 0, 0);
    
    [self.downloadSegmentedControl addTarget:self action:@selector(changeView) forControlEvents:UIControlEventValueChanged];
    [self.downloadSegmentedControl setTitle:NSLocalizedString(@"Most Downloaded",nil) forSegmentAtIndex:0];
    [self.downloadSegmentedControl setTitle:NSLocalizedString(@"Most Viewed",nil) forSegmentAtIndex:1];
    [self.downloadSegmentedControl setTitle:NSLocalizedString(@"Newest",nil) forSegmentAtIndex:2];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
}

- (void)dealloc
{
    [self.loadingView removeFromSuperview];
    self.loadingView = nil;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.projects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell* cell = nil;
    cell = [self cellForProjectsTableView:tableView atIndexPath:indexPath];
    return cell;
}


#pragma mark - Init
-(void)initTableView
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"darkblue"]];
}

#pragma mark - Helper
-(UITableViewCell*)cellForProjectsTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    
    
    static NSString *CellIdentifier = kImageCell;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        NSLog(@"Should Never happen - since iOS5 Storyboard *always* instantiates our cell!");
        abort();
    }
    
    if([cell conformsToProtocol:@protocol(CatrobatImageCell)]) {
        if(indexPath.row == [self.projects count]-1){
            UITableViewCell <CatrobatImageCell>* imageCell = (UITableViewCell <CatrobatImageCell>*)cell;
            //cell.textLabel.text = @"Loading...";
            imageCell.titleLabel.text = NSLocalizedString(@"Loading...",nil);
            imageCell.imageView.image = nil;
            UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            
            imageCell.accessoryView = activityIndicator;
            [activityIndicator startAnimating];
            NSDebug(@"LoadingCell");
            imageCell.iconImageView.image = nil;

        }
        else{
            CatrobatProject *project = [self.projects objectAtIndex:indexPath.row];
        
            UITableViewCell <CatrobatImageCell>* imageCell = (UITableViewCell <CatrobatImageCell>*)cell;
            imageCell.titleLabel.text = project.projectName;
        
            [self loadImage:project.screenshotSmall forCell:imageCell atIndexPath:indexPath];
            NSDebug(@"Normal Cell");
            imageCell.accessoryView = nil;
            imageCell.accessoryType= UITableViewCellAccessoryDisclosureIndicator;
            
        }
    }
  
    return cell;
}




-(void)loadImage:(NSString*)imageURLString forCell:(UITableViewCell <CatrobatImageCell>*) imageCell atIndexPath:(NSIndexPath*)indexPath
{
    
    imageCell.iconImageView.image =
        [UIImage imageWithContentsOfURL:[NSURL URLWithString:imageURLString]
                       placeholderImage:[UIImage imageNamed:@"programs"]
                           onCompletion:^(UIImage *image) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [self.tableView beginUpdates];
                                   UITableViewCell <CatrobatImageCell>* cell = (UITableViewCell <CatrobatImageCell>*)[self.tableView cellForRowAtIndexPath:indexPath];
                                   if(cell) {
                                       cell.iconImageView.image = image;
                                   }
                                   [self.tableView endUpdates];
                               });
                            }];
}

- (void)loadProjects
{
    self.data = [[NSMutableData alloc] init];
    NSURL *url = [NSURL alloc];
    switch (self.downloadSegmentedControl.selectedSegmentIndex) {
        case 0:
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?%@%i&%@%i", kConnectionHost, kConnectionMostDownloaded, kProgramsOffset, self.programListOffset, kProgramsLimit, self.programListLimit]];

            break;
        case 1:
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?%@%i&%@%i", kConnectionHost, kConnectionMostViewed, kProgramsOffset, self.programListOffset, kProgramsLimit, self.programListLimit]];

            break;
        case 2:
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?%@%i&%@%i", kConnectionHost, kConnectionRecent, kProgramsOffset, self.programListOffset, kProgramsLimit, self.programListLimit]];

            break;
            
        default:
            break;
    }
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kConnectionTimeout];

    NSDebug(@"url is: %@", url);
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    self.connection = connection;
    [self showLoadingView];
    self.programListOffset += self.programListLimit;
}

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



#pragma mark - Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [TableUtil getHeightForImageCell];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark - NSURLConnection Delegates
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.connection == connection) {
        NSLog(@"Received data from server");
        [self.data appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    if (self.connection == connection) {
        
        [self.loadingView hide];
        
        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:self.data
                                                        options:NSJSONReadingMutableContainers
                                                          error:&error];
        NSDebug(@"array: %@", jsonObject);
        
        
        if ([jsonObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *catrobatInformation = [jsonObject valueForKey:@"CatrobatInformation"];
            
            CatrobatInformation *information = [[CatrobatInformation alloc] initWithDict:catrobatInformation];
            
            NSArray *catrobatProjects = [jsonObject valueForKey:@"CatrobatProjects"];
            
            if (!self.projects) {
                self.projects = [[NSMutableArray alloc] initWithCapacity:[catrobatProjects count]];
            }
            else {
                //preallocate due to performance reasons
                NSMutableArray *tmpResizedArray = [[NSMutableArray alloc] initWithCapacity:([self.projects count] + [catrobatProjects count])];
                for (CatrobatProject *catrobatProject in self.projects) {
                    [tmpResizedArray addObject:catrobatProject];
                }
                self.projects = nil;
                self.projects = tmpResizedArray;
            }
            
            
            for (NSDictionary *projectDict in catrobatProjects) {
                CatrobatProject *project = [[CatrobatProject alloc] initWithDict:projectDict andBaseUrl:information.baseURL];
                [self.projects addObject:project];
            }
        }
        
        self.data = nil;
        self.connection = nil;
        

        [self update];
    }
}


# pragma mark - Segue delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{    
    
    if([[segue identifier] isEqualToString:kSegueToLevelDetail]) {
        NSIndexPath *selectedRowIndexPath = self.tableView.indexPathForSelectedRow;
        CatrobatProject *level = [self.projects objectAtIndex:selectedRowIndexPath.row];
        ProgramDetailStoreViewController* levelDetailViewController = (ProgramDetailStoreViewController*)[segue destinationViewController];
        levelDetailViewController.project = level;
    }
}


#pragma mark - update

- (void)update {
    [self.tableView reloadData];
    [self.searchDisplayController setActive:NO animated:YES];
}


#pragma mark - BackButtonDelegate
-(void)back {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - scrollViewDidEndDecelerating
#warning not the best solution -> scrolling must stop that this event is fired. But scrollViewDidScroll gets fired too often for this procedure!
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    float checkPoint = scrollView.contentSize.height * 0.7;
    float currentViewBottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
        
    if (currentViewBottomEdge >= checkPoint) {
        NSDebug(@"Reached scroll-checkpoint for loading further projects");
        [self loadProjects];
    }
}

-(void)changeView
{
    NSDebug(@"test %li", (long)self.downloadSegmentedControl.selectedSegmentIndex);
    // TODO: Add support that downloaded data is cached! Now everytime all projects are downloaded after a segmentation click.
    [self.projects removeAllObjects];
    self.programListOffset = 0;
    [self loadProjects];
}



@end
