//
//  TTDBaseViewController.m
//  TTDPettyLoanStandard
//
//  Created by xuj on 2017/7/17.
//  Copyright © 2017年 ttd. All rights reserved.
//

#import "TTDBaseViewController.h"

@interface TTDBaseViewController ()
@end

@implementation TTDBaseViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initView];
    
}


- (void)initView {
    self.ttdNavigationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, NAVIGATIONBAR_MAX_Y)];
    self.ttdNavigationView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.ttdNavigationView];
    [self.ttdNavigationView addSubview:self.textLabel];
    [self.ttdNavigationView addSubview:self.backButton];
    [self.ttdNavigationView addSubview:self.rightButton];
    [self.ttdNavigationView addSubview:self.sepView];
    self.rightButton.hidden = YES;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        // 导航栏（navigationbar）
        CGRect rectNav = self.navigationController.navigationBar.frame;
        if (rectNav.size.height == 0) {
            rectNav.size.height = 44;
        }
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, NAVIGATIONBAR_MAX_Y - rectNav.size.height, SCREEN_WIDTH, rectNav.size.height)];
        _textLabel.text = @"首页";
        _textLabel.textColor = [UIColor blackColor];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    }
    return _textLabel;
}

/**
 返回按钮

 @return 按钮
 */
- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        UIImage *image = [UIImage imageNamed:@"back" inBundle:[NSBundle mainBundle] compatibleWithTraitCollection:nil];
        [_backButton setImage:image forState:UIControlStateNormal];
        
        // 导航栏（navigationbar）
        CGRect rectNav = self.navigationController.navigationBar.frame;
        if (rectNav.size.height == 0) {
            rectNav.size.height = 44;
        }
        _backButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        [_backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _backButton.frame = CGRectMake(0, NAVIGATIONBAR_MAX_Y - rectNav.size.height, image.size.width*3, rectNav.size.height);
    }
    return _backButton;
}

/**
 右侧按钮

 @return 按钮
 */
- (UIButton *)rightButton {
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [UIImage imageNamed:@"add-1" inBundle:[NSBundle mainBundle] compatibleWithTraitCollection:nil];
        [_rightButton setImage:image forState:UIControlStateNormal];
        
        [_rightButton addTarget:self action:@selector(rightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        // 导航栏（navigationbar）
        CGRect rectNav = self.navigationController.navigationBar.frame;
        if (rectNav.size.height == 0) {
            rectNav.size.height = 44;
        }
        _rightButton.frame = CGRectMake(SCREEN_WIDTH - 54, NAVIGATIONBAR_MAX_Y - rectNav.size.height, 54, rectNav.size.height);
        [_rightButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _rightButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_rightButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    }
    return _rightButton;
}

- (UIView *)sepView {
    if (!_sepView) {
        _sepView = [[UIView alloc] initWithFrame:CGRectMake(0, NAVIGATIONBAR_MAX_Y - 1, SCREEN_WIDTH, 1)];
        _sepView.backgroundColor = [UIColor lightGrayColor];
    }
    return _sepView;
}

- (void)backButtonPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)rightButtonPressed:(UIButton *)sender {
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}


@end
