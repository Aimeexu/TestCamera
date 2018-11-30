//
//  VideoManager.h
//  VideoRecord
//
//  Created by Jessica on 11/17/16.
//  Copyright © 2016 .inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VideoManager : NSObject

+ (UIImage *)getScreenShotImageFromVideoPath:(NSString *)filePath;


//获取视频的大小和时间长度
+(NSString *)getVideoSize:(NSString *)vieoPath;

+(void)mergeVideos:(NSArray *)videos completion:(void(^)(BOOL flag, NSString *resultName))completionHandler;

@end
