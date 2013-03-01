//
//  CatrobatTableViewController.m
//  Catty
//
//  Created by Dominik Ziegler on 2/27/13.
//  Copyright (c) 2013 Graz University of Technology. All rights reserved.
//

#import "CatrobatTableViewController.h"
#import "CellTags.h"
#import "BackgroundLayer.h"
#import "TableUtil.h"
#import "UIColor+CatrobatUIColorExtensions.h"
#import "CattyAppDelegate.h"


@interface CatrobatTableViewController ()

@property (nonatomic, strong) NSArray* cells;
@property (nonatomic, strong) NSArray* images;

@end

@implementation CatrobatTableViewController


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
    
    [self initTableView];
    [TableUtil initNavigationItem:self.navigationItem withTitle:@"Catrobat" enableBackButton:NO target:nil];
    
    CattyAppDelegate *appDelegate = (CattyAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.fileManager addDefaultProject];
    
//    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStyleBordered target:self action:@selector(back:)];
//    self.navigationItem.backBarButtonItem = button;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma marks init
-(void)initTableView
{
    self.cells = [[NSArray alloc] initWithObjects:@"continue", @"new", @"programs", @"forum", @"download", @"upload", nil];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"darkblue"]];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.cells count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = (indexPath.row == 0) ? kContinueCell : kImageCell;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        NSLog(@"Should Never happen - since iOS5 Storyboard *always* instantiates our cell!");
        abort();
    }
    
    [self configureTitleLabelForCell:cell atIndexPath:indexPath];
    [self configureImageViewForCell:cell atIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];

    if(indexPath.row == 0) {
        [self configureSubtitleLabelForCell:cell];
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
#warning do not use constants! just for debugging
    if(indexPath.row == 2) {
        [self performSegueWithIdentifier:@"segueToProjects" sender:self];
    }

}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return [self getHeightForCellAtIndexPath:indexPath];
}


#pragma mark Helper

-(void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*) indexPath
{
    if(indexPath.row != ([self.cells count]-1)) {
        [TableUtil addSeperatorForCell:cell atYPosition:[self getHeightForCellAtIndexPath:indexPath]];
    }
    
}

-(void)configureTitleLabelForCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    UILabel* titleLabel = (UILabel*)[cell viewWithTag:kTitleLabelTag];
    titleLabel.text = NSLocalizedString([[self.cells objectAtIndex:indexPath.row] capitalizedString], nil);
    titleLabel.textColor = [UIColor brightBlueColor];
}


-(void)configureImageViewForCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:kImageLabelTag];
    imageView.image = [UIImage imageNamed: [self.cells objectAtIndex:indexPath.row]];
}


-(void)configureSubtitleLabelForCell:(UITableViewCell*)cell
{
    UILabel* subtitleLabel = (UILabel*)[cell viewWithTag:kSubtitleLabelTag];
    subtitleLabel.textColor = [UIColor brightGrayColor];
#warning USE NSUSERDEFAULTS here..
    subtitleLabel.text = @"My Zoo";
}


-(CGFloat)getHeightForCellAtIndexPath:(NSIndexPath*) indexPath {
    return (indexPath.row == 0) ? [TableUtil getHeightForContinueCell] : [TableUtil getHeightForImageCell];
}



@end
