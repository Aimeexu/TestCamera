//
//  CaptureEngine.m
//  VideoRecord
//
//  Created by Jessica on 11/15/16.
//  Copyright © 2016 .inc. All rights reserved.
//

#import "CaptureEngine.h"
#import "CaptureEncoder.h"
#import <Photos/Photos.h>

@interface CaptureEngine()<AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate>
{
    AVCaptureVideoPreviewLayer *_layer;
    int _audioChannel;//信道
    Float64 _sampleRate;//采样率
    NSInteger _height;//视频分辨率高
    NSInteger _width;//视频分辨率宽

    CMTime _timeOffset;//时间偏移
    CMTime _lastVideoTime;//上次录制视频的时间
    CMTime _lastAudioTime;//上次录制的音频的时间
}

@property (nonatomic, strong) AVCaptureSession *session;

//保存当前存到视频的名字
@property (nonatomic, copy) NSString *videoName;


@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput;//前置摄像头输入
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput;//后置摄像头输入
@property (nonatomic, strong) AVCaptureDeviceInput *micphoneInput;//micphone输入

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOut;//视频输出
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOut;//音频输出
@property (nonatomic, strong) AVCaptureMetadataOutput *medaDataOut;//元数据输出

@property (nonatomic, strong) dispatch_queue_t queue;//音视频处理的队列

@property (nonatomic, strong) CaptureEncoder *encoder;

@property (nonatomic, strong) AVCaptureConnection *videoConnection;//视频连接器
@property (nonatomic, strong) AVCaptureConnection *audioConnection;//音频连接器
@property (nonatomic, strong) AVCaptureConnection *metaDataConnection;//元数据连机器

@property (nonatomic, strong) UIView *faceTrackView;
@property (nonatomic, strong) NSMutableArray *faceids;

//当前摄像头是不是前置摄像头
@property (nonatomic, assign) BOOL isDevicePositionFront;

@end

@implementation CaptureEngine

-(NSMutableArray *)faceids{
    if (_faceids == nil) {
        _faceids = [NSMutableArray array];
    }
    return _faceids;
}

-(UIView *)faceTrackView{
    if (_faceTrackView == nil) {
        _faceTrackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        _faceTrackView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.3];
    }
    return _faceTrackView;
}


//初始化默认值,600s录制时间
-(instancetype)init{
    if (self == [super init]) {
        if (!self.maxRecordTime) {
            self.maxRecordTime = 600.0;
        }
    }
    return self;
}

//音频连接器
-(AVCaptureConnection *)audioConnection{
    if (_audioConnection == nil) {
        _audioConnection = [self.audioDataOut connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

//视频连接器
-(AVCaptureConnection *)videoConnection{
    if (_videoConnection == nil) {
        _videoConnection = [self.videoDataOut connectionWithMediaType:AVMediaTypeVideo];
    }
    return _videoConnection;
}

//队列
-(dispatch_queue_t)queue{
    if (_queue == nil) {
        _queue = dispatch_queue_create("com.ppd.capturevideo.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _queue;
}

//输出
-(AVCaptureVideoDataOutput *)videoDataOut{
    if (_videoDataOut == nil) {
        _videoDataOut = [[AVCaptureVideoDataOutput alloc] init];
        [_videoDataOut setSampleBufferDelegate:self queue:self.queue];
        NSDictionary *setting = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,nil];
        _videoDataOut.videoSettings = setting;
    }
    return _videoDataOut;
}

-(AVCaptureAudioDataOutput *)audioDataOut{
    if (_audioDataOut == nil) {
        _audioDataOut = [[AVCaptureAudioDataOutput alloc] init];
        [_audioDataOut setSampleBufferDelegate:self queue:self.queue];
    }
    return _audioDataOut;
}

-(AVCaptureMetadataOutput *)medaDataOut{
    if (_medaDataOut == nil) {
        _medaDataOut = [[AVCaptureMetadataOutput alloc] init];
        [_medaDataOut setMetadataObjectsDelegate:self queue:self.queue];
    }
    return _medaDataOut;
}

//摄像头输入
-(AVCaptureDeviceInput *)backCameraInput{
    if (_backCameraInput == nil) {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput  alloc] initWithDevice:[self cameroWithPosition:AVCaptureDevicePositionBack] error:&error];
        if (error) {
            NSLog(@"后置摄像头获取失败");
        }
    }
    self.isDevicePositionFront = NO;
    return _backCameraInput;
}

-(AVCaptureDeviceInput *)frontCameraInput{
    if (_frontCameraInput == nil) {
        NSError *error;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameroWithPosition:AVCaptureDevicePositionFront] error:&error];
        if (error) {
            NSLog(@"前置摄像头获取失败");
        }
    }
    self.isDevicePositionFront = YES;
    return _frontCameraInput;
}

-(AVCaptureDeviceInput *)micphoneInput{
    if (_micphoneInput == nil) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _micphoneInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            NSLog(@"获取micphone失败");
        }
    }
    return _micphoneInput;
}

//获取可用的摄像头
-(AVCaptureDevice *)cameroWithPosition:(AVCaptureDevicePosition)position{

    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        AVCaptureDeviceDiscoverySession *dissession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDuoCamera,AVCaptureDeviceTypeBuiltInTelephotoCamera,AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
        for (AVCaptureDevice *device in dissession.devices) {
            if ([device position] == position ) {
                return device;
            }
        }
    }else{
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if ([device position] == position) {
                return device;
            }
        }
    }
    return nil;
}

-(AVCaptureSession *)session{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetMedium]) {
            _session.sessionPreset = AVCaptureSessionPresetMedium;
        }

        //添加输入-----默认back摄像头
        if ([_session canAddInput:self.frontCameraInput]) {
            [_session addInput:self.frontCameraInput];
        }

        if ([_session canAddInput:self.micphoneInput]) {
            [_session addInput:self.micphoneInput];
        }

        //添加输出--------------
        if ([_session canAddOutput:self.audioDataOut]) {
            [_session addOutput:self.audioDataOut];
            self.audioConnection = [self.audioDataOut connectionWithMediaType:AVMediaTypeAudio];
        }

        if ([_session canAddOutput:self.videoDataOut]) {
            [_session addOutput:self.videoDataOut];
            self.videoConnection =  [self.videoDataOut connectionWithMediaType:AVMediaTypeVideo];

            NSInteger widtdh = [UIScreen mainScreen].bounds.size.width;
            NSInteger height = [UIScreen mainScreen].bounds.size.height;

            _width = (widtdh%4) == 0 ? widtdh:(widtdh-widtdh%4);
            _height = (height%4) == 0 ? height:(height-height%4);
        }
        
        //解决前置摄像头录制视频左右颠倒问题
        [self videoMirored];
        //设置录视频的方向
        self.videoConnection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
        
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return _session;
}

- (void)statusBarOrientationChange:(NSNotification *)notification {
    //设置录视频的方向
    self.videoConnection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
    self.prewView.connection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
}

/**
 解决前置摄像头录制视频左右颠倒问题                                               
 */
- (void)videoMirored {
    AVCaptureSession* session = (AVCaptureSession *)self.session;
    for (AVCaptureVideoDataOutput* output in session.outputs) {
        
        for (AVCaptureConnection * av in output.connections) {
            
//            av.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
            
            if (self.isDevicePositionFront) {
                
                if (av.supportsVideoMirroring) {
                    
                    av.videoMirrored = YES;
                }
            }
        }
    }
}

/**
 设置录制视频方向

 @return ipad上只允许横屏
 */
- (AVCaptureVideoOrientation) videoOrientationFromCurrentDeviceOrientation {
    UIInterfaceOrientation interfaceOrientation = UIApplication.sharedApplication.statusBarOrientation;
    switch (interfaceOrientation) {

        case UIInterfaceOrientationPortrait: {
            return AVCaptureVideoOrientationPortrait;
        }

        default:
            return AVCaptureVideoOrientationPortrait;
    }
}

/**
 显示view上视频方向

 @return ipad上只允许横屏
 */
- (AVCaptureVideoPreviewLayer *)prewView{
    if (_layer == nil) {
        _layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _layer.connection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
    }
    return _layer;
}

//设置音频格式
-(void)configAudioFormat:(CMSampleBufferRef)sampleBuffer{
    CMFormatDescriptionRef ref = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription(ref);
    _sampleRate = audioDesc->mSampleRate;
    _audioChannel = audioDesc->mChannelsPerFrame;
}

//计算时间差
-(void)timeOffsetWithSampleBuffer:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo{
    CMTime presentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CMTime lastTime = isVideo ? _lastVideoTime : _lastAudioTime;
    if (lastTime.flags & kCMTimeFlags_Valid) {
        if (_timeOffset.flags & kCMTimeFlags_Valid) {
            presentTime = CMTimeSubtract(presentTime, lastTime);
        }

        CMTime offset = CMTimeSubtract(presentTime, lastTime);
        if (_timeOffset.value == 0) {
            _timeOffset = offset;
        }else{
            _timeOffset = CMTimeAdd(_timeOffset, offset);
        }
    }

    _lastVideoTime.flags = 0;
    _lastAudioTime.flags = 0;
}

//计算上次录制的时间
-(void)getLastTimeWithSampleBuffer:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo{
    CMTime present = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CMTime duration = CMSampleBufferGetDuration(sampleBuffer);
    if (duration.value > 0) {
        present = CMTimeAdd(present, duration);
    }
    if (isVideo) {
        _lastVideoTime = present;
    }else{
        _lastAudioTime = present;
    }
}

//支持人脸识别的代理方法
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count) {
        NSLog(@"人脸个数-----%@",metadataObjects);
        for (AVMetadataFaceObject *obj in metadataObjects) {

            for (NSNumber *faceid in self.faceids) {

                if (faceid == [NSNumber numberWithInteger:obj.faceID]) {
                    break;
                }else{
                    [self.faceids addObject:[NSNumber numberWithInteger:obj.faceID]];
                }
            }

            CGRect rect = obj.bounds;

            //坐标系转换-90
            self.faceTrackView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width*(1 - rect.origin.y - rect.size.height/2.0), [UIScreen mainScreen].bounds.size.height*(rect.origin.x + rect.size.width/2.0), rect.size.height * [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height * rect.size.width);
        }
    }else{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"noface" object:nil];
    }
}

//代理方法
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    BOOL isVideo = YES;
    @synchronized (self) {
        if (captureOutput != self.videoDataOut) {
            isVideo = NO;
        }

        if (!self.isCapturing || self.isPaused) {
            return;
        }

        //音频
        if ((self.encoder == nil) && !isVideo) {
            [self configAudioFormat:sampleBuffer];
//            NSString *name = [self formatNameWithType:@"mp4"];
//            self.videoPath = [[self getVideoPath] stringByAppendingPathComponent:name];
            self.encoder = [CaptureEncoder encoderWithPath:self.videoPath height:_height width:_width audioChannel:_audioChannel samlpleRate:_sampleRate];
        }

        //是否中断过
        if (self.isBreaked || self.isPaused) {
            //NSLog(@"中断过");
            if (isVideo) {
                return;
            }

            self.isBreaked = NO;

            //计算暂停的时间偏移
            [self timeOffsetWithSampleBuffer:sampleBuffer isVideo:isVideo];
        }else{
            //NSLog(@"没有中断过");
        }

        //对sampleBuffer引用计数,防止在修改的时候被释放
        CFRetain(sampleBuffer);
        if (_timeOffset.value > 0) {
            CFRelease(sampleBuffer);

            //调整时间后的sampleBuffer
            sampleBuffer = [self adjustSampleBuffer:sampleBuffer offsetTime:_timeOffset];

        }

        //上次的录制时间
        [self getLastTimeWithSampleBuffer:sampleBuffer isVideo:isVideo];
    }

    CMTime presentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (self.startTime.value == 0) {
        self.startTime = presentTime;
    }
    CMTime sub = CMTimeSubtract(presentTime, self.startTime);
    self.currentTime = CMTimeGetSeconds(sub);

    //录制完成的时间
    if (self.currentTime >= self.maxRecordTime) {
        if ((self.currentTime - self.maxRecordTime) < 0.1) {
            //计算进度并显示
            //NSLog(@"完成了的-----进度-------------%f",self.currentTime/self.maxRecordTime);
            //NSLog(@"完成了的---当前时间------%f",self.currentTime);
        }
        return;
    }
        //计算进度并显示
       // NSLog(@"未录制完成-----进度-------------%f",self.currentTime/self.maxRecordTime);
        //NSLog(@"未录制完成----------当前时间------%f",self.currentTime);


    //进行数据编码
    [self.encoder encodeBuffer:sampleBuffer isVideo:isVideo completion:^(BOOL flag) {
        if (flag) {
            //NSLog(@"编码数据成功");
        }
    }];
    
    CFRelease(sampleBuffer);
}

//调整数据的时间
-(CMSampleBufferRef)adjustSampleBuffer:(CMSampleBufferRef)sampleBuffer offsetTime:(CMTime)offsetTime{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &count);
    CMSampleTimingInfo *info = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, count, info, &count);
    for (CMItemCount i = 0; i < count; i++) {
        info[i].decodeTimeStamp = CMTimeSubtract(info[i].decodeTimeStamp, offsetTime);
        info[i].presentationTimeStamp = CMTimeSubtract(info[i].presentationTimeStamp, offsetTime);
    }
    CMSampleBufferRef ref;
    CMSampleBufferCreateCopyWithNewTiming(nil, sampleBuffer, count, info, &ref);
    free(info);
    return ref;
}

//获取视频存放的地址
- (NSString *)videoPath {
    return [CaptureEngine getVideoPathWithName:_videoPath];
}

//压缩后的视频地址
-(NSString *)handledVideoPath{
    return [NSString stringWithFormat:@"%@-new.mp4",[self.videoPath substringToIndex:self.videoPath.length-4]];
}

- (NSString *)picPath {
    return [CaptureEngine getPicPathWithName:_picPath];
}

/**
 获取名称为name的视频在沙盒中的具体路径

 @param name 暂定为商品ID
 @return 名称为name的视频在沙盒中的具体路径
 */
+ (NSString *)getVideoPathWithName:(NSString *)name {
//    NSString *homePath = NSTemporaryDirectory();
    NSArray*paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *homePath = [paths objectAtIndex:0];
    if(!homePath) {
        NSLog(@"Documents目录未找到");
        return @"";
    }
    BOOL isDir = NO;
    NSFileManager *manager = [NSFileManager defaultManager];

    BOOL exist = [manager fileExistsAtPath:homePath isDirectory:&isDir];
    //不存在就创建
    if (!(isDir == YES && exist == YES)) {
        [manager createDirectoryAtPath:homePath withIntermediateDirectories:YES attributes:nil error:nil];
    };
    NSString *videoPath = [NSString stringWithFormat:@"%@/%@-doubleRecord.mp4", homePath, name];
    return videoPath;
}

/**
 获取名称为name的第一帧图片在沙盒中的具体路径
 
 @param name 暂定为商品ID
 @return 名称为name的第一帧图片在沙盒中的具体路径
 */
+ (NSString *)getPicPathWithName:(NSString *)name {
//    NSString *homePath = NSTemporaryDirectory();
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *homePath = [paths objectAtIndex:0];
    if(!homePath) {
        NSLog(@"Documents目录未找到");
        return @"";
    }
    BOOL isDir = NO;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSLog(@"%@", [manager contentsOfDirectoryAtPath:homePath error:nil]);
    BOOL exist = [manager fileExistsAtPath:homePath isDirectory:&isDir];
    //不存在就创建
    if (!(isDir == YES && exist == YES)) {
        [manager createDirectoryAtPath:homePath withIntermediateDirectories:YES attributes:nil error:nil];
    };
    NSString *picPath = [NSString stringWithFormat:@"%@/%@-doubleRecord.png", homePath, name];
    return picPath;
}

/**
 删除本地存储的视频和图片

 @param name 暂定为商品ID
 */
+ (void)deleteVideoAndPicWithName:(NSString *)name {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *homePath = [paths objectAtIndex:0];
    if(!homePath) {
        NSLog(@"Documents目录未找到");
        return;
    }
    BOOL isDir = NO;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSLog(@"删除之前%@", [manager contentsOfDirectoryAtPath:homePath error:nil]);
    BOOL exist = [manager fileExistsAtPath:homePath isDirectory:&isDir];
    //不存在就创建
    if (!(isDir == YES && exist == YES)) {
        return;
    };
    NSString *videoPath = [NSString stringWithFormat:@"%@/%@-doubleRecord.png", homePath, name];
    [manager removeItemAtPath:videoPath error:nil];
    NSString *picPath = [NSString stringWithFormat:@"%@/%@-doubleRecord.mp4", homePath, name];
    [manager removeItemAtPath:picPath error:nil];
    NSLog(@"删除之后%@", [manager contentsOfDirectoryAtPath:homePath error:nil]);
}


//开启闪光灯
-(void)flashLightOn{
    AVCaptureDevice *back = [self cameroWithPosition:AVCaptureDevicePositionBack];
    if (back.torchMode == AVCaptureTorchModeOff) {
        [back lockForConfiguration:nil];
        back.torchMode = AVCaptureTorchModeOn;

        AVCapturePhotoSettings * setting = [AVCapturePhotoSettings photoSettings];
        setting.flashMode = AVCaptureFlashModeOn;
        [back unlockForConfiguration];
    }
}

//关闭闪光灯
-(void)flashLightOff{
    AVCaptureDevice *back = [self cameroWithPosition:AVCaptureDevicePositionBack];
    if (back.torchMode == AVCaptureTorchModeOn) {
        [back lockForConfiguration:nil];
        back.torchMode = AVCaptureTorchModeOff;
        AVCapturePhotoSettings *setting = [AVCapturePhotoSettings photoSettings];
        setting.flashMode = AVCaptureFlashModeOff;
        [back unlockForConfiguration];
    }
}

//切换摄像头方向
-(void)changeCameraPositionWithCurrentIsFront:(BOOL)isFront{
    NSLog(@"切换摄像头方向");

    __block CATransition *animation;
    [UIView animateWithDuration:0.5 animations:^{
        animation = [CATransition animation];
        animation.duration = .5f;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.type = @"oglFlip";
        [self.prewView addAnimation:animation forKey:nil];
        if (isFront) {
            animation.subtype = kCATransitionFromLeft;
            self.isDevicePositionFront = YES;

            NSLog(@"切换摄像头------前变后----");
            [self.session stopRunning];
            [self.session removeInput:self.backCameraInput];

            if ([self.session canAddInput:self.frontCameraInput]) {

                [self.session addInput:self.frontCameraInput];
            }

        }else{

            animation.subtype = kCATransitionFromRight;
            self.isDevicePositionFront = NO;
            NSLog(@"切换摄像头------后变前----");
            [self.session stopRunning];
            [self.session removeInput:self.frontCameraInput];

            if ([self.session canAddInput:self.backCameraInput]) {
                [self.session addInput:self.backCameraInput];
            }
        }

        AVCaptureConnection *videoConnection = nil;
        for ( AVCaptureConnection *connection in [self.videoDataOut connections])
        {
            NSLog(@"%@", connection);
            for ( AVCaptureInputPort *port in [connection inputPorts] )
            {
                NSLog(@"%@", port);
                if ( [[port mediaType] isEqual:AVMediaTypeVideo] )
                {
                    videoConnection = connection;
                }
            }
        }

        if([videoConnection isVideoOrientationSupported]) // **Here it is, its always false**
        {
            [videoConnection setVideoOrientation:[UIDevice currentDevice].orientation];
        }

        [self videoMirored];

    } completion:^(BOOL finished) {
        //
        [self.session startRunning];
    }];
}

//格式转换
-(void)convertMovToMp4:(NSURL *)mediaUrl callBack:(void (^)(UIImage *stillImage, NSString *name))callBack{
    AVAsset *asset = [AVAsset assetWithURL:mediaUrl];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetLowQuality];//设置输出分辨率
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeMPEG4;
//    self.videoPath = [[self getVideoPath] stringByAppendingPathComponent:[self formatNameWithType:@"mp4"]];
    exportSession.outputURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@-new.mp4",[self.videoPath substringToIndex:self.videoPath.length-4]]];
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self getMovieFirstFrameImageCallBack:callBack];
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                NSLog(@"转换成功");
            }else if (exportSession.status == AVAssetExportSessionStatusFailed){
                NSLog(@"转换失败");
            }else if (exportSession.status == AVAssetExportSessionStatusWaiting || exportSession.status == AVAssetExportSessionStatusExporting){
                NSLog(@"正在转换");
            }else{
                NSLog(@"转换不知道在干啥");
            }
        });
    }];

}

//获取视频第一帧的图片
-(void)getMovieFirstFrameImageCallBack:(void(^)(UIImage *image, NSString *name))callBack{
    NSURL *url = [NSURL fileURLWithPath:self.videoPath];
    AVAsset *asset = [[AVURLAsset alloc]initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = true;
    CMTime thumbTime = CMTimeMakeWithSeconds(0, 60);
    generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;

    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        if (!error) {
            if (result == AVAssetImageGeneratorSucceeded) {
                UIImage *thumbImage = [UIImage imageWithCGImage:image];
                NSData *imageData = UIImagePNGRepresentation(thumbImage);
                [imageData writeToFile:self.picPath atomically:YES];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    callBack(thumbImage,self.videoName);
                    NSLog(@"回调一张图片");
                });
            }else{
                //NSLog(@"result------%ld",(long)result);
            }
        }else{
            NSLog(@"error-----%@",error.localizedDescription);
        }
    }];
}

//开始录制
-(void)captureEngineStartCapture{

    @synchronized(self) {
        if (!self.isCapturing) {
            self.encoder = nil;
            self.isPaused = NO;
            self.isBreaked = NO;
            _timeOffset = CMTimeMake(0, 0);
            self.isCapturing = YES;
            NSLog(@"开始采集数据");
        }
    }
}

//停止录制---------回调方法里返回保存的视频的名字
-(void)captureEngineEndCaptureWithCallBack:(void (^)(UIImage *image,NSString *name))callBack {
    //移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    NSLog(@"正在录制----%d",self.isCapturing);

    @synchronized (self) {
        if (self.isCapturing) {
//            NSString *path = self.encoder.path;
//            NSURL *url = [NSURL fileURLWithPath:path];
            self.isCapturing = NO;
            dispatch_async(self.queue, ^{
                [self.encoder completionWithHandler:^{
                    self.isCapturing = NO;
                    self.encoder = nil;
                    //NSLog(@"😑-----停止的时候的进度-----%f",self.currentTime/self.maxRecordTime);
                    //NSLog(@"😑-----停止的时候当前时间------%f",self.currentTime);
                    self.startTime = CMTimeMake(0, 0);
                    self.currentTime = 0;

//                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
//                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
//                        if (success) {
//                            NSLog(@"😑----停止然后保存成功");
//                        }else{
//                            NSLog(@"😑-----停止但是保存失败%@",error);
//                        }
//                    }];
                    [self getMovieFirstFrameImageCallBack:callBack];
                }];
            });
        }
    }
}

//暂停
-(void)captureEnginePauseCapture{
    @synchronized(self) {
        if (self.isCapturing) {
            self.isPaused = YES;
            self.isBreaked = YES;
            NSLog(@"暂停采集数据----");
        }
    }
}

//恢复录制
-(void)captureEngineResumeCapture{
    @synchronized(self) {
        if (self.isPaused) {
        NSLog(@"恢复录制");
            self.isPaused = NO;
        }
    }
}

//开启会话
-(void)start{
    self.startTime = CMTimeMake(0, 0);
    self.isCapturing = NO;
    self.isPaused = NO;
    self.isBreaked = NO;
    [self.session startRunning];
    NSLog(@"开启会话");
}

//关闭会话
-(void)shutDown{
    self.startTime = CMTimeMake(0, 0);
    if (self.session) {
        [self.session stopRunning];
    }
    NSLog(@"关闭会话");
    [self.encoder completionWithHandler:^{
        NSLog(@"关闭会话");
    }];
}



@end
