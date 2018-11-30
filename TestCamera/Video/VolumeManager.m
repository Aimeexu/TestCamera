//
//  VolumeManager.m
//  VideoRecord
//
//  Created by Jessica on 11/17/16.
//  Copyright © 2016 .inc. All rights reserved.
//

#import "VolumeManager.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VolumeManager()

@end

@implementation VolumeManager


+(UISlider *)getSlider{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    volumeView.frame = CGRectMake(100, 100, 200, 100);
    UISlider *slider;
    for (UIView *view in volumeView.subviews){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            slider = (UISlider*)view;
            break;
        }
    }
    return slider;
}

+(float)getSystemVolume{

    //获取系统音量大小
    float systemVolume = [self getSlider].value;
    NSLog(@"系统音量大小---%f",systemVolume);
    return systemVolume;



}

+(void)setSystemVolume:(NSInteger)volume{
    //修改系统音量大小
    [[self getSlider] setValue:volume animated:NO];

    //修改界面上slider的值
    [[self getSlider] sendActionsForControlEvents:UIControlEventTouchUpInside];
}

@end
