//
//  ProgramTableHeaderView.m
//  Catty
//
//  Created by luca on 12/05/14.
//
//

#import "ProgramTableHeaderView.h"
#import "UIColor+CatrobatUIColorExtensions.h"

@implementation ProgramTableHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    self.contentView.backgroundColor = UIColor.backgroundBlueColor;
}

@end
