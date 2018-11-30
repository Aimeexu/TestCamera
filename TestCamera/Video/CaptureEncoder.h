//
//  CaptureEncoder.h
//  VideoRecord
//
//  Created by Jessica on 11/15/16.
//  Copyright © 2016 .inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface CaptureEncoder : NSObject

@property (nonatomic, copy) NSString *path;


//初始化encoder对象
+(instancetype)encoderWithPath:(NSString *)path height:(NSInteger)height width:(NSInteger)width audioChannel:(int)audioChannel samlpleRate:(Float64)sampleRate;

//写数据
-(void)encodeBuffer:(CMSampleBufferRef)buffer isVideo:(BOOL)isVideo completion:(void(^)(BOOL flag))completion;

//录制视频结束的时候调用
-(void)completionWithHandler:(void(^)(void))handler;

@end
