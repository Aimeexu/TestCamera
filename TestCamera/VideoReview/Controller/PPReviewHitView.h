//
//  PPReviewHitView.h
//  PPSDK
//
//  Created by Jessica on 29/06/2017.
//  Copyright © 2017 . All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PPReviewHitViewDelegate<NSObject>

-(void)handleReRecordingButtonClick:(UIButton *)btn;
-(void)handleReviewButtonClick:(UIButton *)btn;
-(void)handleConfirmButtonClick:(UIButton *)btn;

@end

@interface PPReviewHitView : UIView
@property (weak, nonatomic) IBOutlet UIButton *reRecording;
@property (weak, nonatomic) IBOutlet UIButton *reviewButton;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (nonatomic, weak) id<PPReviewHitViewDelegate> delegate;

@end
