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

#import "TableUtil.h"
#import "Util.h"
#import "UIColor+CatrobatUIColorExtensions.h"
#import "CatrobatBaseCell.h"


#define kIphone5ScreenHeight 568.0f
#define kIphone4ScreenHeight 480.0f
#define kContinueCellHeight  124.0f
#define kImageCellHeight     79.0f



@implementation TableUtil

+(CGFloat)getHeightForContinueCell {
    CGFloat screenHeight = [Util getScreenHeight];
    if (screenHeight == kIphone5ScreenHeight) {
        return (kContinueCellHeight*screenHeight)/kIphone5ScreenHeight;
    }
    else{
        return (kContinueCellHeight*screenHeight)/kIphone4ScreenHeight;
    }

}

+(CGFloat)getHeightForImageCell {
    CGFloat screenHeight = [Util getScreenHeight];
    if (screenHeight == kIphone5ScreenHeight) {
        return (kImageCellHeight*screenHeight)/kIphone5ScreenHeight;
    }
    else{
        return (kImageCellHeight*screenHeight)/kIphone4ScreenHeight;
    }
}

+(void)initNavigationItem:(UINavigationItem*)navigationItem withTitle:(NSString*)title{
    
    navigationItem.title = title;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_icon"]];
    [navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:imageView]];
    
}

+(void)addSeperatorForCell:(CatrobatBaseCell*)cell{
    if(cell.seperatorView == nil) {
        UIImageView *seperator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cellseperator"]];
        seperator.frame = CGRectMake(0.0f, 0.0f, cell.bounds.size.width, 4.0f);
        [cell.contentView addSubview:seperator];
        cell.seperatorView = seperator;
    }
}



#pragma mark Helper
+(UIBarButtonItem*)createBackButtonWithTarget:(id)target{
    UIButton *backbutton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *img = [UIImage imageNamed:@"backbutton"];
    
    backbutton.frame = CGRectMake(20, 100, img.size.width+10, img.size.height);
    
    
    [backbutton setImage:img forState:UIControlStateNormal];
    [backbutton setImage:img forState:UIControlStateHighlighted];
    [backbutton setImage:img forState:UIControlStateSelected];
    [backbutton addTarget:target action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    
    return [[UIBarButtonItem alloc] initWithCustomView:backbutton];
    

}



@end
