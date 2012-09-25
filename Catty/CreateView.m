//
//  CreateView.m
//  Catty
//
//  Created by Christof Stromberger on 20.09.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CreateView.h"
#import "CatrobatProject.h"

@implementation CreateView

+ (UIView*)createLevelStoreView:(CatrobatProject*)project target:(id)target {
    //creating new view for page
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"container"]];
    
    
    //adding project name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 15, 155, 25)];
    nameLabel.text = project.projectName;
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.font = [UIFont boldSystemFontOfSize:16];
    nameLabel.textColor = [UIColor colorWithRed:61.0/255.0 green:61.0/255.0 blue:61.0/255.0 alpha:1.0];
    nameLabel.layer.shadowColor = [[UIColor whiteColor] CGColor];
    nameLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    
    //just for debug
//    nameLabel.layer.borderColor = [UIColor greenColor].CGColor;
//    nameLabel.layer.borderWidth = 1.0;
    
    [view addSubview:nameLabel];
    
    
    //adding thumbnail image to view
    NSURL *imageURL = [NSURL URLWithString:project.screenshotSmall];
    NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
    UIImage *image = [UIImage imageWithData:imageData];
    
    //cutting image
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGFloat frame = 60.0;
    
    if (height > width) {
        frame = width;
    }
    else {
        frame = height;
    }
    
    CGImageRef imageToSplit = image.CGImage;
    CGImageRef partOfImageAsCG = CGImageCreateWithImageInRect(imageToSplit, CGRectMake((width/2)-(frame/2), (height/2)-(frame/2), frame, frame));
    //CGImageRelease(imageToSplit);
    UIImage *cuttedImage = [UIImage imageWithCGImage:partOfImageAsCG];
    CGImageRelease(partOfImageAsCG);
    
    //uiimage view
    UIImageView *imageView = [[UIImageView alloc] initWithImage:cuttedImage];
    imageView.frame = CGRectMake(25, 15, 55, 55);
    
    imageView.layer.cornerRadius = 5.0;
    imageView.layer.masksToBounds = YES;
    imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    imageView.layer.borderWidth = 1.0;
    
    [view addSubview:imageView];

    
    
    //adding big image
    NSURL *imageURL2 = [NSURL URLWithString:project.screenshotBig];
    NSData *imageData2 = [NSData dataWithContentsOfURL:imageURL2];
    UIImage *image2 = [UIImage imageWithData:imageData2];
    
    //uiimage view
    UIImageView *imageView2 = [[UIImageView alloc] initWithImage:image2];
    imageView2.frame = CGRectMake(45, 80, 155, 235);
    
    //    imageView.layer.cornerRadius = 5.0;
    //    imageView.layer.masksToBounds = YES;
    imageView2.layer.borderColor = [UIColor lightGrayColor].CGColor;
    imageView2.layer.borderWidth = 1.0;
    
    [view addSubview:imageView2];
    
    
    //adding download button (below level name)
    NSString *title = @"Download";
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = 501;
    button.frame = CGRectMake(85, 45, 115, 25);
    button.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [button setTitle:title forState:UIControlStateNormal];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:target action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = button.layer.bounds;
    
    gradientLayer.colors = [NSArray arrayWithObjects:
                            //                            (id)[UIColor colorWithRed:58.0f/255.0f green:199.0f/255.0f blue:84.0f/255.0f alpha:1.0f].CGColor,
                            //                            (id)[UIColor colorWithRed:0.0f/255.0f green:138/255.0f blue:24/255.0f alpha:1.0f].CGColor,
                            (id)[UIColor colorWithRed:54/255.0f green:157/255.0f blue:244/255.0f alpha:1.0f].CGColor,
                            (id)[UIColor colorWithRed:58/255.0f green:136/255.0f blue:191/255.0f alpha:1.0f].CGColor,
                            nil];
    
    gradientLayer.locations = [NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:0.0f],
                               [NSNumber numberWithFloat:1.0f],
                               nil];
    
    button.layer.cornerRadius = 3.0f;
    gradientLayer.cornerRadius = button.layer.cornerRadius;
    //    [self.buttonOutlet.layer addSublayer:gradientLayer];
    [button.layer insertSublayer:gradientLayer atIndex:0];
    
    button.layer.masksToBounds = YES;
    
    //text shadow
    button.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    button.titleLabel.layer.shadowOpacity = 0.3f;
    button.titleLabel.layer.shadowRadius = 1;
    button.titleLabel.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    
    //border
    //    self.buttonOutlet.layer.borderColor = [UIColor colorWithRed:2/255.0f green:73/255.0f blue:14/255.0f alpha:0.5f].CGColor;
    button.layer.borderColor = [UIColor colorWithRed:41/255.0f green:103/255.0f blue:147/255.0f alpha:0.5f].CGColor;
    button.layer.borderWidth = 1.0f;
    
    
    [view addSubview:button];
    
    
    //adding play button (below level name)
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    playButton.tag = 502;
    playButton.hidden = YES;
    playButton.frame = CGRectMake(85, 45, 115, 25);
    playButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [playButton setTitle:@"Play" forState:UIControlStateNormal];
    playButton.backgroundColor = [UIColor clearColor];
    [playButton addTarget:target action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    CAGradientLayer *newGradientLayer = [CAGradientLayer layer];
    newGradientLayer.frame = playButton.layer.bounds;
    
    newGradientLayer.colors = [NSArray arrayWithObjects:
                            (id)[UIColor colorWithRed:103/255.0f green:174/255.0f blue:59/255.0f alpha:1.0f].CGColor,
                            (id)[UIColor colorWithRed:61/255.0f green:118/255.0f blue:26/255.0f alpha:1.0f].CGColor,
                            nil];
    
    newGradientLayer.locations = [NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:0.0f],
                               [NSNumber numberWithFloat:1.0f],
                               nil];
    
    playButton.layer.cornerRadius = 3.0f;
    newGradientLayer.cornerRadius = playButton.layer.cornerRadius;
    [playButton.layer insertSublayer:newGradientLayer atIndex:0];
    
    playButton.layer.masksToBounds = YES;
    
    //text shadow
    playButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    playButton.titleLabel.layer.shadowOpacity = 0.3f;
    playButton.titleLabel.layer.shadowRadius = 1;
    playButton.titleLabel.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    
    //border
    playButton.layer.borderColor = [UIColor colorWithRed:61/255.0f green:118/255.0f blue:26/255.0f alpha:0.5f].CGColor;
    playButton.layer.borderWidth = 1.0f;

    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activity.tag = 601;
    activity.frame = CGRectMake(5, 0, 25, 25);
    [playButton addSubview:activity];
    
    
    [view addSubview:playButton];
    

    
    
    return view;
}


@end
