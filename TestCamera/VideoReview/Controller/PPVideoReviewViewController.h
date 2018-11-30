//
//  PPVideoReviewViewController.h
//  PPVideo
//
//  Created by xuj on 2017/4/21.
//  Copyright © 2017年 xuj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "TTDBaseViewController.h"

@interface PPVideoReviewViewController : TTDBaseViewController

/**
 视频时长
 */
@property (nonatomic, assign) NSInteger videoTime;


/**
 第一帧图片
 */
@property (nonatomic, strong) UIImage *firstFrame;

/**
 播放本地视频

 @param url 本地视频url
 @return 构造函数
 */
- (instancetype)initWithLocalMediaURL:(NSURL *)url ;

/**
 播放在线视频

 @param url 在线url
 @return 构造函数
 */
- (instancetype)initWithHTTPLiveStreamingMediaURL:(NSURL *)url;

@end
