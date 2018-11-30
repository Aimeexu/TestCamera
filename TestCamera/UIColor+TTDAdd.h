//
//  UIColor+TTDAdd.h
//  GTFundC
//
//  Created by xuj on 2017/10/23.
//  Copyright © 2017年 ttd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIColor (TTDAdd)

/**
 设置颜色
 
 @param hexColorString # 格式 或者 0x 格式
 @param alpha 透明度
 @return 设置的颜色
 */
+ (UIColor *)colorWithHexString:(NSString *)hexColorString alpha:(CGFloat)alpha;

@end
