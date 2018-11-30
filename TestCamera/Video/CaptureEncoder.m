//
//  CaptureEncoder.m
//  VideoRecord
//
//  Created by Jessica on 11/15/16.
//  Copyright © 2016 .inc. All rights reserved.
//

#import "CaptureEncoder.h"

@interface CaptureEncoder()

@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;

@end

@implementation CaptureEncoder

//初始化encoder对象
+(instancetype)encoderWithPath:(NSString *)path height:(NSInteger)height width:(NSInteger)width audioChannel:(int)audioChannel samlpleRate:(Float64)sampleRate{
    CaptureEncoder *encoder = [[CaptureEncoder alloc] init];
    return [encoder encoderWithPath:path height:height width:width audioChannel:audioChannel samlpleRate:sampleRate];
}

-(instancetype)encoderWithPath:(NSString *)path height:(NSInteger)height width:(NSInteger)width audioChannel:(int)audioChannel samlpleRate:(Float64)sampleRate{
    if (self == [super init]) {
        self.path = path;
        //先删除路径下的旧文件
        NSError *error;
        NSFileManager *manager = [NSFileManager defaultManager];
        [manager removeItemAtPath:path error:&error];
        if (error) {
            NSLog(@"删除文件失败");
        }

        //初始化音视频写入对象
        NSURL *url = [NSURL fileURLWithPath:path];
        self.writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:&error];
        self.writer.shouldOptimizeForNetworkUse = YES;

        //初始化音视频输出
        [self initVideoInputWithWidth:width height:height];
        [self initAudioInputWithChannel:audioChannel sampleRate:sampleRate];

    }
    return self;
}


//初始化音视频输出配置信息
-(void)initAudioInputWithChannel:(int)audioChannel sampleRate:(Float64)sampleRate{
    if (audioChannel && sampleRate) {
        NSDictionary *setting = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                 [ NSNumber numberWithInt: audioChannel], AVNumberOfChannelsKey,
                                 [ NSNumber numberWithFloat: sampleRate], AVSampleRateKey,
                                 [ NSNumber numberWithInt: 128000], AVEncoderBitRateKey, nil];
        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:setting];

        //实时数据源
        self.audioInput.expectsMediaDataInRealTime = YES;
        if ([self.writer canAddInput:self.audioInput]) {
            [self.writer addInput:self.audioInput];
        }
    }
}

-(void)initVideoInputWithWidth:(NSInteger)width height:(NSInteger)height{
    if (width && height) {
        NSDictionary *setting = [NSDictionary dictionaryWithObjectsAndKeys:
                                 AVVideoCodecH264, AVVideoCodecKey,
                                 [NSNumber numberWithInteger: width], AVVideoWidthKey,
                                 [NSNumber numberWithInteger: height], AVVideoHeightKey, nil];
        self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:setting];

        //实时数据源
        self.videoInput.expectsMediaDataInRealTime = YES;
        if ([self.writer canAddInput:self.videoInput]) {
            [self.writer addInput:self.videoInput];
        }
    }
}

//正式写入数据
-(void)encodeBuffer:(CMSampleBufferRef)buffer isVideo:(BOOL)isVideo completion:(void (^)(BOOL flag))completion{
    //数据是否准备好
    if (CMSampleBufferDataIsReady(buffer)) {
        //状态不可知的时候,如果是video就写video
        if (self.writer.status == AVAssetWriterStatusUnknown && isVideo) {
            //获取当前时间戳
            CMTime beginTime = CMSampleBufferGetOutputPresentationTimeStamp(buffer);
            //开始写数据,在当前时间戳开启一个会话
            [self.writer startWriting];
            [self.writer startSessionAtSourceTime:beginTime];
        }

        if (self.writer.status == AVAssetWriterStatusFailed) {
            NSLog(@"写入失败--%@",self.writer.error.localizedDescription);
            completion(NO);
            return;
        }

        if (isVideo) {
            if (self.videoInput.isReadyForMoreMediaData) {
                [self.videoInput appendSampleBuffer:buffer];
                completion(YES);
                return;
            }
        }else{
            if (self.audioInput.isReadyForMoreMediaData) {
                [self.audioInput appendSampleBuffer:buffer];
                completion(YES);
                return;
            }
        }
    }else{
        completion(NO);
        return;
    }
}

-(void)completionWithHandler:(void (^)(void))handler{
    NSLog(@"状态-----%ld",(long)self.writer.status);
//    CMTime cmTime = CMTimeMake(60, 1);
//    [self.writer endSessionAtSourceTime:cmTime];
    [self.writer finishWritingWithCompletionHandler:handler];
}

@end
