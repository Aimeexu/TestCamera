//
//  CaptureEngine.h
//  VideoRecord
//
//  Created by Jessica on 11/15/16.
//  Copyright © 2016 .inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface CaptureEngine : NSObject


/**
 中断了
 */
@property (nonatomic, assign) BOOL isBreaked;


/**
 视频路径
 */
@property (nonatomic, copy) NSString *videoPath;

/**
压缩后的视频地址
 */
@property (nonatomic, copy) NSString *handledVideoPath;

/**
 第一帧图片路径
 */
@property (nonatomic, copy) NSString *picPath;


/**
 开始录制的时间
 */
@property (nonatomic, assign) CMTime startTime;


/**
 当前录制的时间
 */
@property (nonatomic, assign) CGFloat currentTime;


/**
 正在录制
 */
@property (nonatomic, assign) BOOL isCapturing;



/**
 最大录制时间
 */
@property (nonatomic, assign) CGFloat maxRecordTime;


/**
 暂停了
 */
@property (nonatomic, assign) BOOL isPaused;



/**
 预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prewView;

/*****************************FUNCTION*******************************************/

/**
 开始采集数据
 */
-(void)captureEngineStartCapture;


/**
 停止采集数据

 @param callBack 回调方法
 */
-(void)captureEngineEndCaptureWithCallBack:(void(^)(UIImage *image, NSString *name))callBack;


/**
 暂停采集数据
 */
-(void)captureEnginePauseCapture;


/**
 恢复采集数据
 */
-(void)captureEngineResumeCapture;


/**
 启动
 */
-(void)start;


/**
 关闭
 */
-(void)shutDown;



/**
 开启闪光灯
 */
-(void)flashLightOn;


/**
 关闭闪光灯
 */
-(void)flashLightOff;


/**
 改变摄像头的方向

 @param isFront 是否是前置摄像头
 */
-(void)changeCameraPositionWithCurrentIsFront:(BOOL)isFront;


/**
 格式转化 mov转成mp4
 @param mediaUrl 视频文件的路劲
 @param callBack 转换完的回调方法
 */
-(void)convertMovToMp4:(NSURL *)mediaUrl callBack:(void(^)(UIImage *stillImage, NSString *name))callBack;

/**
 获取名称为name的视频在沙盒中的具体路径
 
 @param name 暂定为商品ID
 @return 名称为name的视频在沙盒中的具体路径
 */
+ (NSString *)getVideoPathWithName:(NSString *)name;

/**
 获取名称为name的第一帧图片在沙盒中的具体路径
 
 @param name 暂定为商品ID
 @return 名称为name的第一帧图片在沙盒中的具体路径
 */
+ (NSString *)getPicPathWithName:(NSString *)name;

/**
 删除本地存储的视频和图片
 
 @param name 暂定为商品ID
 */
+ (void)deleteVideoAndPicWithName:(NSString *)name;

@end
