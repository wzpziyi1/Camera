//
//  ZYPreviewView.h
//  Camera
//
//  Created by wzp on 2019/11/18.
//  Copyright © 2019 wzp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol ZYPreviewViewDelegate <NSObject>

- (void)focusAtPoint:(CGPoint)point;
- (void)exposureAtPoint:(CGPoint)point;

@end

@interface ZYPreviewView : UIView
//session关联AVCaptureVideoPreviewLayer、 激活AVCaptureSession
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, weak) id<ZYPreviewViewDelegate>delegate;

@property (nonatomic, assign) BOOL focusEnable;
@property (nonatomic, assign) BOOL exposureEnable;


@end
