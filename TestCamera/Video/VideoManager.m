//
//  VideoManager.m
//  VideoRecord
//
//  Created by Jessica on 11/17/16.
//  Copyright © 2016 .inc. All rights reserved.
//

#import "VideoManager.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

@implementation VideoManager

//获取视频的缩略图
+ (UIImage *)getScreenShotImageFromVideoPath:(NSString *)filePath{

    UIImage *shotImage;
    NSURL *fileURL;
    if ([filePath hasPrefix:@"http://"]) {
        fileURL = [NSURL URLWithString:filePath];
    }else{
       fileURL = [NSURL fileURLWithPath:filePath];
    }

    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];

    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];

    gen.appliesPreferredTrackTransform = YES;

    CMTime time = CMTimeMakeWithSeconds(0.0, 600);

    NSError *error = nil;

    CMTime actualTime;

    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];

    shotImage = [[UIImage alloc] initWithCGImage:image];

    CGImageRelease(image);
    
    return shotImage;
}

//获取视频的大小和时间长度
+(NSString *)getVideoSize:(NSString *)vieoPath {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDic;
    if ([manager fileExistsAtPath:vieoPath isDirectory:&isDic]){
        NSLog(@"是不是文件夹-----%d",isDic);
        CGFloat size = [[manager attributesOfItemAtPath:vieoPath error:nil] fileSize];
        NSLog(@"视频大小--------%@",[NSString stringWithFormat:@"%f",size/(1024.0 * 1024.0)]);
        return [NSString stringWithFormat:@"%f",size/(1024.0 * 1024.0)];
    }else{
        NSLog(@"没有文件");
    }

    return @"";
}


+(void)mergeVideos:(NSArray *)videos completion:(void (^)(BOOL flag, NSString *resultName))completionHandler{

    NSString *videoPath = NSTemporaryDirectory();

    if (videos.count == 0) {
        NSLog(@"请传入视频名称");
        return;
    }

    //创建混合的音视频组成
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];

    CMTime totalDuration = kCMTimeZero;
    NSString *mergeName;
    NSMutableArray *instructions = [NSMutableArray array];

    for (NSInteger i = 0; i < videos.count; i ++) {

        //获取资源文件
        AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[videoPath stringByAppendingPathComponent:videos[i]]]];

        //合并视频后的名称
        if (mergeName == nil) {
            mergeName = [[videos[i] componentsSeparatedByString:@"."] objectAtIndex:0];
        }else{
            mergeName = [mergeName stringByAppendingString:[NSString stringWithFormat:@"+%@",[[videos[i] componentsSeparatedByString:@"."] objectAtIndex:0]]];
        }

        //拿出音频轨道------
        NSError *assetAudioError;
        AVMutableCompositionTrack *assetAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [assetAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:totalDuration error:&assetAudioError];//totalduration之前写的asset.duration是不行的

        //拿出视频的视频轨道做方向调整
        NSError *assetVideoError;
        AVMutableCompositionTrack *assetVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [assetVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:totalDuration error:&assetVideoError];//totalduration之前写的asset.duration是不行的

        //修正视频的方向
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetVideoTrack];
        AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];


        //方向判断并调整
        UIImageOrientation assetOrientation = UIImageOrientationUp;
        BOOL isAssetPortrait = NO;
        CGAffineTransform assetTransform = assetTrack.preferredTransform;

        if (assetTransform.a == 0 && assetTransform.b == 1.0 && assetTransform.c == -1.0 && assetTransform.d == 0) {
            assetOrientation = UIImageOrientationRight;
            isAssetPortrait = YES;
            NSLog(@"right");
        }

        if (assetTransform.a == 0 && assetTransform.b == -1.0 && assetTransform.c == 1.0 && assetTransform.d == 0) {
            assetOrientation = UIImageOrientationLeft;
            isAssetPortrait = YES;
            NSLog(@"left");
        }

        if (assetTransform.a == 1.0 && assetTransform.b == 0 && assetTransform.c == 0 && assetTransform.d == 1.0) {
            assetOrientation = UIImageOrientationUp;
            NSLog(@"up");
        }

        if (assetTransform.a == -1.0 && assetTransform.b == 0 && assetTransform.c == 0 && assetTransform.d == -1.0) {
            assetOrientation = UIImageOrientationDown;
            NSLog(@"down");
        }

        //等比例缩放并旋转方向
        CGFloat assetScaleToFitRatio = 320.0/assetTrack.naturalSize.width;
        CGAffineTransform assetScaleFactor;
        if (isAssetPortrait) {
            assetScaleToFitRatio = 320.0/assetTrack.naturalSize.height;
            assetScaleFactor = CGAffineTransformMakeScale(assetScaleToFitRatio, assetScaleToFitRatio);
            [layerInstruction setTransform:CGAffineTransformConcat(assetTrack.preferredTransform, assetScaleFactor) atTime:kCMTimeZero];
            NSLog(@"isPortrait");
        }else{
            assetScaleFactor = CGAffineTransformMakeScale(assetScaleToFitRatio, assetScaleToFitRatio);
            [layerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(assetTrack.preferredTransform, assetScaleFactor), CGAffineTransformMakeTranslation(0, 160)) atTime:kCMTimeZero];
            NSLog(@"isNotPortrait");
        }


        //累加视频时间
        totalDuration = CMTimeAdd(totalDuration, asset.duration);

        //设置不透明度,下面是totalduration,而且这行代码要放在设置了totaldurtion后面,之前出了bug的
        [layerInstruction setOpacity:0.0 atTime:totalDuration];

        //保存每个视频调整后的视频轨道
        [instructions addObject:layerInstruction];
    }

    //拼接的名字后面跟后缀
    mergeName = [mergeName stringByAppendingString:@".mp4"];

    //设置总的时长
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruction.layerInstructions = instructions;
    NSLog(@"instructions=--------%@",mainInstruction.layerInstructions);

    //设置帧数
    mainComposition.instructions = [NSArray arrayWithObject:mainInstruction];
    mainComposition.frameDuration = CMTimeMake(1, 30);
    mainComposition.renderSize = CGSizeMake(320, 480);

    //导出合并的视频-------------------------------------------------
        NSURL *mergeVideoUrl = [NSURL fileURLWithPath:[videoPath stringByAppendingPathComponent:mergeName]];

    NSLog(@"%@-------%@-------duration---%@",mergeName,mergeVideoUrl,[NSString stringWithFormat:@"%lld",totalDuration.value/totalDuration.timescale]);

    //删除路径下相同名字的文件,不然会报错,导致导出失败
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError *fileExsistError;
//    if ([fileManager fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:mergeName]]) {
//
//        BOOL flag = [fileManager removeItemAtURL:mergeVideoUrl error:&fileExsistError];
//        NSLog(@"删除文件结果-----%d",flag);
//
//        if (fileExsistError) {
//            NSLog(@"文件错误----%@",fileExsistError);
//        }
//
//    }else{
//        NSLog(@"不存在相同的文件");
//    }

    //创建音视频文件导出会话
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
        exporter.outputURL = mergeVideoUrl;
        exporter.outputFileType = AVFileTypeMPEG4;
        exporter.videoComposition = mainComposition;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{

                //结束状态监控
                if (exporter.status == AVAssetExportSessionStatusCompleted) {

                    NSURL *url = exporter.outputURL;
                    NSLog(@"url------%@",url);

                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{

                        //[PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];

                    } completionHandler:^(BOOL success, NSError * _Nullable error) {

                        if (success) {
                            NSLog(@"合并成功");
                            NSLog(@"视频的大小----%@", [self getVideoSize:mergeName]);
                            completionHandler(YES,mergeName);

                        }else{
                            NSLog(@"合并失败%@",error);
                            completionHandler(NO,mergeName);
                        }
                    }];

                }else if(exporter.status == AVAssetExportSessionStatusFailed){

                    NSLog(@"转化失败%@",exporter.error);

                }else if(exporter.status == AVAssetExportSessionStatusWaiting || exporter.status ==
                         AVAssetExportSessionStatusExporting){
                    NSLog(@"正在转化-----------%ld",(long)exporter.status);

                }else{
                    NSLog(@"状态未知或者被打断退出");
                }
            });
        }];
}

@end
