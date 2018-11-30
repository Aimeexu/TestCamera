//
//  TTDBaseViewController.h
//  TTDPettyLoanStandard
//
//  Created by xuj on 2017/7/17.
//  Copyright © 2017年 ttd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTDBaseViewController : UIViewController

@property (strong, nonatomic) UIView *ttdNavigationView;

/**
 返回按钮
 */
@property (nonatomic, strong) UIButton *backButton;

/**
 title
 */
@property (nonatomic, strong) UILabel *textLabel;

/**
 右侧按钮
 */
@property (nonatomic, strong) UIButton *rightButton;

/**
 分割线
 */
@property (nonatomic, strong) UIView *sepView;


//

/**
 返回按钮事件重写

 @param sender 返回
 */
- (void)backButtonPressed:(UIButton *)sender;

/**
 右侧按钮点击事件

 @param sender 右侧按钮
 */
- (void)rightButtonPressed:(UIButton *)sender;

@end
