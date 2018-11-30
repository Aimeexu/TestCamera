//
//  PPVideoRightView.h
//  PPVideo
//
//  Created by xuj on 2017/4/25.
//  Copyright © 2017年 xuj. All rights reserved.
//

#import <UIKit/UIKit.h>

//右侧按钮点击代理方法
@protocol PPVideoRightViewDelegate <NSObject>

- (void)handleVideoRightButtonClick:(UIButton *)button;

@end

@interface PPVideoBottomView : UIView

/**
 切换摄像头方向
 */
@property (weak, nonatomic) IBOutlet UIButton *changeButton;

/**
 录像按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *takeVideoButton;
@property (weak, nonatomic) IBOutlet UILabel *takeLabel;

/**
 取消按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

/**
 时间label
 */
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

/**
 按钮点击代理
 */
@property (nonatomic, weak) id<PPVideoRightViewDelegate> delegate;

+ (instancetype)videoRightView;

@end
