//
//  BaseViewController.m
//  GeneralSettings
//
//  Created by dynamsoft on 2021/11/18.
//

#import "BaseViewController.h"

@interface BaseViewController ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *navBarHairlineImageView;

@end

@implementation BaseViewController

- (void)dealloc
{
    NSLog(@"%@ dealloc--", [self class]);
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


@end
