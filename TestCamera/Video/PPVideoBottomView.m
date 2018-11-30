//
//  PPVideoRightView.m
//  PPVideo
//
//  Created by xuj on 2017/4/25.
//  Copyright © 2017年 xuj. All rights reserved.
//

#import "PPVideoBottomView.h"

@implementation PPVideoBottomView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.changeButton.tag = 1001;
    self.takeVideoButton.tag = 1002;
    self.cancelButton.tag = 1003;
    self.backgroundColor = [UIColor clearColor];
    
}

+ (instancetype)videoRightView {
    return [[[NSBundle mainBundle] loadNibNamed:@"PPVideoBottomView" owner:nil options:nil] firstObject];
}

- (IBAction)rightButtonPressed:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(handleVideoRightButtonClick:)]) {
        [self.delegate handleVideoRightButtonClick:sender];
    }
}


@end
