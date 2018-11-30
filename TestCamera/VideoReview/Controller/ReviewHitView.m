//
//  ReviewHitView.m
//  PPSDK
//
//  Created by Jessica on 29/06/2017.
//  Copyright © 2017 . All rights reserved.
//

#import "ReviewHitView.h"

@implementation ReviewHitView


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
UIView *view = [super hitTest:point withEvent:event];
if (view == nil) {
    // 转换坐标系
    for (id btn in view.subviews) {
        if ([btn isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)btn;
            CGPoint newPoint = [button convertPoint:point fromView:self];
            // 判断触摸点是否在button上
            if (CGRectContainsPoint(button.bounds, newPoint)) {
                view = button;
            }
        }
    }
}
    return view;
}



@end
