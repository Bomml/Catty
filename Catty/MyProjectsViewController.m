//
//  MyProjectsViewController.m
//  Catty
//
//  Created by Christof Stromberger on 19.09.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "MyProjectsViewController.h"
#import "Util.h"
#import "LevelLoadingInfo.h"
#import "StageViewController.h"
#import "CattyAppDelegate.h"
#import "TableUtil.h"
#import "CellTags.h"
#import "UIColor+CatrobatUIColorExtensions.h"
#import "CatrobatImageCell.h"

@interface MyProjectsViewController ()

@property (nonatomic, strong) NSMutableArray *levelLoadingInfos;

@end

@implementation MyProjectsViewController

@synthesize levelLoadingInfos = _levelLoadingInfos;

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

    //background image
    [self initTableView];
    [TableUtil initNavigationItem:self.navigationItem withTitle:@"Programs" enableBackButton:YES target:self];
    
        
    //loading levels
    NSString *documentsDirectoy = [Util applicationDocumentsDirectory];
    NSString *levelFolder = @"levels";
    NSString *levelsPath = [NSString stringWithFormat:@"%@/%@", documentsDirectoy, levelFolder];
    
    NSError *error;
    NSArray *levels = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:levelsPath error:&error];
    [Util log:error];
    
    NSLog(@"my levels: %@", levels);
    
    
    self.levelLoadingInfos = [[NSMutableArray alloc] initWithCapacity:[levels count]];
    for (NSString *level in levels) {
        LevelLoadingInfo *info = [[LevelLoadingInfo alloc] init];
        info.basePath = [NSString stringWithFormat:@"%@/%@/", levelsPath, level];
        info.visibleName = level;
        
        NSLog(@"Adding level: %@", info.basePath);
        
        [self.levelLoadingInfos addObject:info];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma marks init
-(void)initTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"darkblue"]];
    
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.levelLoadingInfos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = kImageCell;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(!cell) {
        NSLog(@"This should not happen - since ios5 - storyboards manages allocation of cells");
        abort();
    }
    

    if([cell conformsToProtocol:@protocol(CatrobatImageCell)]) {
        UITableViewCell <CatrobatImageCell>* imageCell = (UITableViewCell <CatrobatImageCell>*)cell;
        [self configureImageCell:imageCell atIndexPath:indexPath];
    }
    
        
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [TableUtil getHeightForImageCell];
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        CattyAppDelegate *appDelegate = (CattyAppDelegate*)[[UIApplication sharedApplication] delegate];
        LevelLoadingInfo *level = [self.levelLoadingInfos objectAtIndex:indexPath.row];
        [appDelegate.fileManager deleteFolder:level.basePath];
        [self.levelLoadingInfos removeObject:level];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{    
    if ([segue.identifier isEqualToString:@"SEGUE_TO_STAGE"])
    {
        //get selected row index
        NSIndexPath *selectedRowIndexPath = self.tableView.indexPathForSelectedRow;
                
        //check if it's the same class
        if ([segue.destinationViewController isKindOfClass:[StageViewController class]])
        {
#warning outsource this.. (This is used multiple times..)
            LevelLoadingInfo* info = [self.levelLoadingInfos objectAtIndex:selectedRowIndexPath.row];
            NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:info.visibleName forKey:@"lastProject"];
            [userDefaults synchronize];
            StageViewController *destination = segue.destinationViewController;
            destination.levelLoadingInfo = [self.levelLoadingInfos objectAtIndex:selectedRowIndexPath.row];
        }
        
    }
    
}

#pragma mark - BackButtonDelegate
-(void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Cell Helper


-(void)configureImageCell:(UITableViewCell <CatrobatImageCell>*)cell atIndexPath:(NSIndexPath*)indexPath
{
    LevelLoadingInfo *info = [self.levelLoadingInfos objectAtIndex:indexPath.row];
    cell.titleLabel.text = info.visibleName;
    
#warning we need an image here.. LevelLoading does not provide one..
    cell.imageView.image = [UIImage imageNamed:@"programs"];
}


@end
