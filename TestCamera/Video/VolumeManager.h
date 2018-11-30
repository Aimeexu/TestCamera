//
//  VolumeManager.h
//  VideoRecord
//
//  Created by Jessica on 11/17/16.
//  Copyright © 2016 .inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VolumeManager : NSObject

+(float)getSystemVolume;
+(void)setSystemVolume:(NSInteger)volume;

@end
