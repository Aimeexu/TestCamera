//
//  JRPlayerViewController.m
//  JRVideoPlayer
//
//  Created by 湛家荣 on 15/5/8.
//  Copyright (c) 2015年 Zhan. All rights reserved.
//

#import "PPVideoReviewViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "JRPlayerView.h"
#import "CaptureEngine.h"

#import "PPReviewHitView.h"

#define OFFSET 5.0 // 快进和快退的时间跨度
#define ALPHA 0.5 // headerView和bottomView的透明度

static void * playerItemDurationContext = &playerItemDurationContext;
static void * playerItemStatusContext = &playerItemStatusContext;
static void * playerPlayingContext = &playerPlayingContext;


@interface PPVideoReviewViewController()<PPReviewHitViewDelegate>{

    CGFloat playerProgress; // 播放进度
    UISlider *volumeSlider; // 改变系统声音的 MPVolumeSlider (UISlider的子类)
    // 手势初始X和Y坐标
    CGFloat beginTouchX;
    CGFloat beginTouchY;
    // 手势相对于初始X和Y坐标的偏移量
    CGFloat offsetX;
    CGFloat offsetY;
}

@property (nonatomic, strong) AVPlayer *player; // 播放器
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) NSURL *mediaURL; // 视频资源的url
@property (nonatomic, assign) BOOL playing; // 是否正在播放
@property (nonatomic, assign) BOOL canPlay; // 是否可以播放
@property (nonatomic, assign) CMTime duration; // 视频总时间
@property (nonatomic, strong) id timeObserver;
@property (weak, nonatomic) IBOutlet JRPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel; // 当前播放的时间
@property (weak, nonatomic) IBOutlet UILabel *remainTimeLabel; // 剩余时间
@property (weak, nonatomic) IBOutlet UISlider *progressView; // 播放进度

/* 底部预览工具条 */
@property (nonatomic, strong) PPReviewHitView *reviewToolView;
@property (weak, nonatomic) IBOutlet UIButton *smallPlayButton;

//失败原因
@property (weak, nonatomic) IBOutlet UILabel *cantPlayReasonLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressConstraint;


@end

@implementation PPVideoReviewViewController

-(PPReviewHitView *)reviewToolView{
    if (_reviewToolView == nil) {
        _reviewToolView = [[[NSBundle mainBundle] loadNibNamed:@"PPReviewHitView" owner:nil options:nil] firstObject];
        _reviewToolView.delegate = self;
    }
    return _reviewToolView;
}

- (instancetype)initWithLocalMediaURL:(NSURL *)url {
    self = [super initWithNibName:@"PPVideoReviewViewController" bundle:nil];
    if (self) {
        self.mediaURL = url;
        [self createLocalMediaPlayerItem];
    }
    return self;
}

- (instancetype)initWithHTTPLiveStreamingMediaURL:(NSURL *)url {
    self = [super initWithNibName:@"PPVideoReviewViewController" bundle:nil];
    if (self) {
        self.mediaURL = url;
        [self createHLSPlayerItem];
        NSLog(@"😀😀------流播放的视频地址-------%@",url);
    }
    return self;
}

- (UIImage *)OriginImage:(UIImage *)image scaleToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0, size.width, size.height)];
    UIImage *scaleImage=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaleImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.textLabel.text = @"视频预览";
    [self.progressView setThumbImage:[UIImage imageNamed:@"dian" inBundle:nil compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.progressView setTintColor:[UIColor whiteColor]];
    [self.progressView setMaximumTrackImage:[self imageWithColor:[UIColor colorWithWhite:1 alpha:0.5f]] forState:UIControlStateNormal];


    self.smallPlayButton.hidden = YES;
    /* 添加底部工具条 */
    [self.view addSubview:self.reviewToolView];
  
    // KVO观察self.playing属性的变化以改变playButton的状态
    [self addObserver:self forKeyPath:@"playing" options:NSKeyValueObservingOptionNew context:playerPlayingContext];
    [self createPlayer];// 创建播放器
    
    // 监控 app 活动状态，打电话/锁屏 时暂停播放
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
//    self.fd_interactivePopDisabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView:)];
    [self.playerView addGestureRecognizer:tap];
}

//颜色转换 背景图片
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 2.0f, 2.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)tapView:(UITapGestureRecognizer *)tap {
    [UIView animateWithDuration:0.2f animations:^{
        self.ttdNavigationView.alpha = !self.ttdNavigationView.alpha;
        self.reviewToolView.alpha = !self.reviewToolView.alpha;
    }];
}

- (void)appWillResignActive:(NSNotification *)aNotification {
    [self.player pause];
    self.playing = NO;
}

#pragma mark - 创建播放器

- (void)createPlayer {
    // 1.控制器初始化时创建playerItem对象
    
    // 2.观察self.currentItem.status属性变化，变为AVPlayerItemStatusReadyToPlay时就可以播放了
    [self addObserver:self forKeyPath:@"playerItem.status" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:playerItemStatusContext];

    // 监听播放到最后的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    // 3.playerItem关联创建player
    AVPlayerLayer *layer = (AVPlayerLayer *)self.player;
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    // 4.player关联创建playerView
    [self.playerView setPlayer:self.player];
    
    [self.playerView.layer setBackgroundColor:[UIColor blackColor].CGColor];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.reviewToolView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height-50, [UIScreen mainScreen].bounds.size.width, 50);
    [self.view bringSubviewToFront:self.reviewToolView];
    self.progressConstraint.constant = 60;
}

- (void)createLocalMediaPlayerItem {
    // 如果是本地视频，创建AVURLAsset对象
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.mediaURL options:nil];
    self.playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
}

- (void)createHLSPlayerItem {
    self.playerItem = [AVPlayerItem playerItemWithURL:self.mediaURL];
}

- (void)handleConfirmButtonClick:(UIButton *)btn{
}

- (IBAction)smallPlayButtonPressed:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    
    if (sender.selected) {
        [self.player play];
        self.playing = YES;
        NSLog(@"playing yes");
    } else {
        [self.player pause];
        self.playing = NO;
    }
}

- (void)handleReviewButtonClick:(UIButton *)btn{
    btn.selected = !btn.selected;
    
    if (btn.selected) {
        [self.player play];
        self.playing = YES; // KVO观察playing属性的变化
        [UIView animateWithDuration:0.2f animations:^{
            self.ttdNavigationView.alpha = 0;
            self.reviewToolView.alpha = 0;
        }];
    }else{
        [self.player pause];
        self.playing = NO;
    }
}

-(void)handleReRecordingButtonClick:(UIButton *)btn{
    btn.enabled = NO;
    [self.player pause];
//    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    btn.enabled = YES;
}

#pragma mark 播放到最后时
- (void)playerItemDidPlayToEnd:(NSNotification *)aNotification {
    [self.playerItem seekToTime:kCMTimeZero];
    self.reviewToolView.reviewButton.selected = !self.reviewToolView.reviewButton.selected;
    self.playing = NO;
    self.smallPlayButton.selected = NO;
}

#pragma mark - 拖动进度条改变播放点(playhead)
// valueChanged
- (IBAction)slidingProgress:(UISlider *)slider {

    // 取消调用hideHeaderViewAndBottomView方法，不隐藏
    Float64 totalSeconds = CMTimeGetSeconds(self.duration);
    CMTime time = CMTimeMakeWithSeconds(totalSeconds * slider.value, self.duration.timescale);
    if (CMTIME_IS_VALID(time)) {
      if (_playing) {
          [self.player pause];
      }
      NSLog(@"拖动进度-----%f",slider.value);
      [self.player seekToTime:time completionHandler:^(BOOL finished) {
    }];
  }
}

// touchUpInside/touchUpOutside
- (IBAction)slidingEnded:(UISlider *)sender {
    if (_playing) {
        // 如果拖动前正在播放，拖动后也要在播放状态
        [self.player play];
    }
}

#pragma mark 根据CMTime生成一个时间字符串
- (NSString *)timeStringWithCMTime:(CMTime)time {
    Float64 seconds = time.value / time.timescale;
    // 把seconds当作时间戳得到一个date
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
    // 格林威治标准时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    // 设置时间显示格式
    [formatter setDateFormat:(seconds / 3600 >= 1) ? @"mm:ss" : @"mm:ss"];
    // 返回这个date的字符串形式
    return [formatter stringFromDate:date];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == playerItemStatusContext) {
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {

            // 视频准备就绪
            dispatch_async(dispatch_get_main_queue(), ^{
                [self readyToPlay];
                self.currentTimeLabel.hidden = NO;
                self.progressView.hidden = NO;
                self.remainTimeLabel.hidden = NO;

            });
        } else {
            // 如果一个不能播放的视频资源加载进来会进到这里
            NSString *alertStr;
            NSLog(@"视频无法播放");

            self.currentTimeLabel.hidden = YES;
            self.progressView.hidden = YES;
            self.remainTimeLabel.hidden = YES;


            /* 不能播放移除工具条 */
            [self.reviewToolView removeFromSuperview];

            //将播放
            [self.playerView removeFromSuperview];

            if ([[self.mediaURL absoluteString] hasPrefix:@"http"]) {
                alertStr = @"视频正在处理中...";
                self.cantPlayReasonLabel.text = @"视频正在处理中...";
            }else{
                alertStr = @"视频无法播放";
                self.cantPlayReasonLabel.text = @"视频无法播放";
            }
            NSLog(@"视频无法播放");
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"温馨提示"
                                                                             message:alertStr
                                                                      preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *done = [UIAlertAction actionWithTitle:@"我知道了"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
//                                                                 [self delayDismissPlayerViewController];
                                                         }];
            [alertVc addAction:done];
            [self presentViewController:alertVc animated:YES completion:nil];
        }
        
        
    } else if (context == playerPlayingContext){

        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)delayDismissPlayerViewController {
    BOOL hasListClass = NO;

    if (!hasListClass) {
        if (self.presentedViewController) {
            [self.presentedViewController dismissViewControllerAnimated:NO completion:^{
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }else{
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark AVPlayerItemStatusReadyToPlay
- (void)readyToPlay {
    // 可以播放
    self.canPlay = YES;
    [self.progressView setEnabled:YES];
    
    self.duration = self.playerItem.duration;
    
    // 未播放前剩余时间就是视频长度
    self.remainTimeLabel.text = [NSString stringWithFormat:@"%@", [self timeStringWithCMTime:self.duration]];
    
    __weak typeof(self) weakSelf = self;
    // 更新当前播放条目的已播时间, CMTimeMake(3, 30) == (Float64)3/30 秒
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(3, 30) queue:nil usingBlock:^(CMTime time) {
        // 当前播放时间
        weakSelf.currentTimeLabel.text = [weakSelf timeStringWithCMTime:time];

        // 更新进度
        weakSelf.progressView.value = CMTimeGetSeconds(time) / CMTimeGetSeconds(weakSelf.duration);
        
    }];
    
    NSLog(@"状态准备就绪 -> %@", @(AVPlayerItemStatusReadyToPlay));

    [self.view bringSubviewToFront:self.progressView];

//    [self handleReviewButtonClick:self.reviewToolView.reviewButton];//准备好就直接播放
}


#pragma mark -

- (void)dealloc {
    [self.player pause];
    
    
    
    [self removeObserver:self forKeyPath:@"playerItem.status" context:playerItemStatusContext];
    
    [self removeObserver:self forKeyPath:@"playing" context:playerPlayingContext];
    
    [self.player removeTimeObserver:self.timeObserver];
    self.timeObserver = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.player = nil;
    self.playerItem = nil;
    self.mediaURL = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
    self.playing = NO;
    self.player = nil;
}


@end
