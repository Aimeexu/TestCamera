//
//  VideoController.m
//  VideoRecord
//
//  Created by Jessica on 11/15/16.
//  Copyright © 2016 .inc. All rights reserved.
//

#import "VideoController.h"
#import "CaptureEncoder.h"
#import "CaptureEngine.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVKit/AVKit.h>
#import "VolumeManager.h"
#import "VideoManager.h"
#import <CoreTelephony/CTCall.h>
#import "UIColor+TTDAdd.h"

#import "PPVideoBottomView.h"

#import "PPVideoReviewViewController.h"


@interface VideoController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate,PPVideoRightViewDelegate>

@property (nonatomic, strong) CaptureEngine *capengine;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, assign) NSInteger time;

@property (nonatomic, strong) PPVideoBottomView *rightView;
@property (nonatomic, assign) NSInteger totalVideoTime;

@property (assign, nonatomic) BOOL isRecord;

@end

@implementation VideoController

- (PPVideoBottomView *)rightView {
    if (_rightView == nil) {
        _rightView = [PPVideoBottomView videoRightView];
        self.rightView.delegate = self;
    }
    return _rightView;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    if (_capengine == nil) {
            self.capengine.prewView.frame = self.view.bounds;
            [self.view.layer insertSublayer:self.capengine.prewView atIndex:0];
        }

    if (self.capengine) {
        [self.capengine start];
        _capengine.picPath = @"test";
        _capengine.videoPath = @"test";
    }
}

- (UILabel *)timeLabel{
    if (_timeLabel == nil) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake((SCREEN_WIDTH-100)/2, 20, 100, 44)];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _timeLabel;
}

- (CaptureEngine *)capengine {
    if (_capengine == nil) {
        _capengine = [[CaptureEngine alloc] init];
    }
    return _capengine;
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.rightView.frame = CGRectMake(0, SCREEN_HEIGHT-100, SCREEN_WIDTH, 100);
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;

    /* 不让手机锁屏 */
    [UIApplication sharedApplication].idleTimerDisabled=YES;

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    /* 让手机恢复锁屏 */
    [UIApplication sharedApplication].idleTimerDisabled = NO;

    self.timeLabel.text = @"00:00:00";
    self.timeLabel.hidden = YES;

    /* 关闭 */
    [self close];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    /* 监听推到后台 */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];

    [self.view addSubview:self.rightView];
    [self.view addSubview:self.timeLabel];
   
    [self topView];
    [self bottomView];
    self.isRecord = NO;
}

/* 程序推到后台 */
- (void)applicationEnterBackground:(NSNotification *)notification {
    [self close];
}

- (void)handleVideoRightButtonClick:(UIButton *)button {
    button.selected = !button.selected;
    if (button.tag == 1001) {//切换摄像头方向
        //切换方向-------默认后置------如果改为默认前置---下面改成!button.isSelected
        [self.capengine changeCameraPositionWithCurrentIsFront:!button.isSelected];
    } else if (button.tag == 1002) {//录像
        self.isRecord = button.isSelected;
        //开始录制
        if (button.isSelected) {
            //开始录制---关闭一些功能
            if (self.capengine) {
                [self.capengine addObserver:self forKeyPath:@"currentTime" options:NSKeyValueObservingOptionNew context:nil];
            }
            
            self.rightView.changeButton.hidden = YES;
            self.rightView.takeLabel.text = @"录像中";
            self.rightView.backgroundColor = [UIColor clearColor];
            self.timeLabel.hidden = NO;
            
            if (self.capengine.isCapturing) {
                [self.capengine captureEngineResumeCapture];
                
            }else{
                [self.capengine captureEngineStartCapture];
            }
            
        } else {
            
            //结束录制
            /* -------------------------------------------------*/
            if (self.capengine.videoPath.length > 0) {
                __weak typeof(self) weakSelf = self;
                //防止多次点击
                button.enabled = NO;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    button.enabled = YES;
                });
                self.rightView.takeLabel.text = @"开始双录";
                [self.capengine removeObserver:self forKeyPath:@"currentTime"];
                [self.capengine captureEngineEndCaptureWithCallBack:^(UIImage *image,NSString *name) {
                    PPVideoReviewViewController *VC = [[PPVideoReviewViewController alloc]
                                                       initWithLocalMediaURL:[NSURL fileURLWithPath:weakSelf.capengine.videoPath]];
                    VC.videoTime = self.totalVideoTime;
                    VC.firstFrame = image;
                    //正常流程不需要回调
                    self.rightView.changeButton.hidden = NO;
                    
                    [self presentViewController:VC animated:YES completion:nil];
                    
                }];
            } else {
                NSLog(@"请先录制视频");
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"无法找到视频文件" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:cancel];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
    } else {//取消
        [self handleCancelButtonClick:button];
        [self close];
    }
}

- (void)handleCancelButtonClick:(UIButton *)cancel{
    
}

- (void)close {
    [self.capengine captureEngineEndCaptureWithCallBack:^(UIImage *image, NSString *name) {
        self.rightView.takeVideoButton.selected = NO;
        if (self.capengine) {
            [self.capengine removeObserver:self forKeyPath:@"currentTime"];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (change) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"change------%@", change);

            NSInteger currentTime = [change[@"new"] integerValue];
            NSInteger currenHour = currentTime/600;
            NSInteger currentMin = (currentTime - currenHour * 60)/60;
            NSInteger currentSec = currentTime - (currentTime - currenHour * 60)/60 * 60;

            self.timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",(long)currenHour,(long)currentMin,(long)currentSec];
        });

        NSLog(@"属性变化了😀--当前时间是--------%@", change[@"new"]);
        self.totalVideoTime = [change[@"new"] integerValue] == 0 ? self.totalVideoTime : [change[@"new"] integerValue];
        NSLog(@"视频长度-------%ld", (long)self.totalVideoTime);
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

/**
 顶部渐变
 */
- (void)topView {
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[(__bridge id)[UIColor colorWithHexString:@"#000000" alpha:0.5f].CGColor,
                             (__bridge id)[UIColor colorWithHexString:@"#000000" alpha:0.0f].CGColor];
    //上深 下浅
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1);
    gradientLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, 100);
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
}


/**
 底部渐变
 */
- (void)bottomView {
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)[UIColor colorWithHexString:@"#000000" alpha:0.5f].CGColor,
                                 (__bridge id)[UIColor colorWithHexString:@"#000000" alpha:0.0f].CGColor];
    //上浅 下深
    gradientLayer.startPoint = CGPointMake(0, 1);
    gradientLayer.endPoint = CGPointMake(0, 0);
    gradientLayer.frame = CGRectMake(0, SCREEN_HEIGHT - 80, SCREEN_WIDTH, 100);
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
}

@end
