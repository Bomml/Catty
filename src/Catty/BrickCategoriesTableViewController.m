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

#import "BrickCategoriesTableViewController.h"
#import "UIDefines.h"
#import "TableUtil.h"
#import "ColoredCell.h"
#import "SpriteObject.h"
#import "SegueDefines.h"
#import "ActionSheetAlertViewTags.h"
#import "ProgramDefines.h"
#import "UIImageView+CatrobatUIImageViewExtensions.h"
#import "Util.h"
#import "UIColor+CatrobatUIColorExtensions.h"
#import "BricksCollectionViewController.h"

#define kTableHeaderIdentifier @"Header"
#define kCategoryCell @"CategoryCell"

@interface BrickCategoriesTableViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) NSArray *brickTypeNames;
@property (nonatomic, strong) NSArray *brickTypeColors;
@end

@implementation BrickCategoriesTableViewController

#pragma marks - getters and setters
- (NSArray*)brickTypeNames
{
    if (! _brickTypeNames)
        _brickTypeNames = kBrickTypeNames;
    return _brickTypeNames;
}

- (NSArray*)brickTypeColors
{
    if (! _brickTypeColors)
        _brickTypeColors = kBrickTypeColors;
    return _brickTypeColors;
}

#pragma marks init
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

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

#pragma view events
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initTableView];
    [super initPlaceHolder];

    NSString *title = NSLocalizedString(@"Categories", nil);
    self.title = title;
    self.navigationItem.title = title;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
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
    return [self.brickTypeNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = kCategoryCell;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if ([cell isKindOfClass:[ColoredCell class]]) {
        ColoredCell *coloredCell = (ColoredCell*)cell;
        coloredCell.textLabel.text = self.brickTypeNames[indexPath.row];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = self.brickTypeColors[indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    return (([Util getScreenHeight] - navBarHeight - kAddScriptCategoryTableViewBottomMargin) / [self.brickTypeNames count]);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Navigation
// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    static NSString *toNewScriptCategorySegueID = kSegueToNewScriptCategory;

    UIViewController* destController = segue.destinationViewController;
    if ([sender isKindOfClass:[ColoredCell class]]) {
        if ([segue.identifier isEqualToString:toNewScriptCategorySegueID] &&
            [destController respondsToSelector:@selector(setObject:)] &&
            [destController respondsToSelector:@selector(setCategoryType:)]) {
            [destController performSelector:@selector(setObject:) withObject:self.object];
            NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell*)sender];
            ((BrickCollectionViewController*)destController).categoryType = (kBrickType)indexPath.row;
        }
    }
}

@end
