//
//  PPReviewHitView.m
//  PPSDK
//
//  Created by Jessica on 29/06/2017.
//  Copyright © 2017 . All rights reserved.
//

#import "PPReviewHitView.h"

@implementation PPReviewHitView

-(void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [UIColor whiteColor];
    self.reviewButton.backgroundColor = [UIColor clearColor];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
        if (view == nil) {
            // 转换坐标系
            CGPoint newPoint = [self.reviewButton convertPoint:point fromView:self];
            // 判断触摸点是否在button上
            if (CGRectContainsPoint(self.reviewButton.bounds, newPoint) && self.alpha) {
                view = self.reviewButton;
        }
}
    return view;
}

- (IBAction)reRecordingButtonClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(handleReRecordingButtonClick:)]) {
        [self.delegate handleReRecordingButtonClick:self.reRecording];
    }
}

- (IBAction)reviewButtonClick:(id)sender {
    //隐藏后还响应的bug
    if ([self.delegate respondsToSelector:@selector(handleReviewButtonClick:)]) {
        [self.delegate handleReviewButtonClick:self.reviewButton];
    }
}

- (IBAction)confirmButtonClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(handleConfirmButtonClick:)]) {
        [self.delegate handleConfirmButtonClick:self.confirmButton];
    }
}


@end
