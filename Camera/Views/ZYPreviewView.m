//
//  ZYPreviewView.m
//  Camera
//
//  Created by wzp on 2019/11/18.
//  Copyright © 2019 wzp. All rights reserved.
//

#import "ZYPreviewView.h"

#define kBoxBounds CGRectMake(0.0f, 0.0f, 150, 150.0f)

@interface ZYPreviewView()
@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapRecognizer;

@property (nonatomic, strong) UIView *focusView;
@property (nonatomic, strong) UIView *exposureView;
@end

@implementation ZYPreviewView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initializeUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self initializeUI];
    }
    return self;
}

+ (Class)layerClass
{
    //在UIView 重写layerClass 类方法可以让创建视图实例自定义图层
    //重写layerClass方法并返回AVCaptureVideoPrevieLayer类对象
    return [AVCaptureVideoPreviewLayer class];
}

//相关UI、手势，单击、双击 单击聚焦、双击曝光
- (void)initializeUI
{
    //设置画面填充方式
    [((AVCaptureVideoPreviewLayer *)self.layer) setVideoGravity:AVLayerVideoGravityResize];
    
    self.singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusRecognizer:)];
    self.singleTapRecognizer.numberOfTouchesRequired = 1;
    self.doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exposureRecognizer:)];
    self.doubleTapRecognizer.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:self.singleTapRecognizer];
    [self addGestureRecognizer:self.doubleTapRecognizer];
    [self.singleTapRecognizer requireGestureRecognizerToFail:self.doubleTapRecognizer];
    
    _focusView = [self viewWithColor:[UIColor colorWithRed:0.102 green:0.636 blue:1.000 alpha:1.000]];
    _exposureView = [self viewWithColor:[UIColor colorWithRed:1.000 green:0.421 blue:0.054 alpha:1.000]];
    [self addSubview:_focusView];
    [self addSubview:_focusView];
}

- (UIView *)viewWithColor:(UIColor *)color
{
    UIView *view = [[UIView alloc] initWithFrame:kBoxBounds];
    view.backgroundColor = [UIColor clearColor];
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = 5.0f;
    view.hidden = YES;
    return view;
}

- (void)runBoxAnimationOnView:(UIView *)view point:(CGPoint)point {
    view.center = point;
    view.hidden = NO;
    [UIView animateWithDuration:0.15f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
                     }
                     completion:^(BOOL complete) {
                         double delayInSeconds = 0.5f;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                             view.hidden = YES;
                             view.transform = CGAffineTransformIdentity;
                         });
                     }];
}

//将屏幕上的点转换为摄像头上画面的点
- (CGPoint)fetchCaptureDevicePointFromPoint:(CGPoint)point
{
    AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)self.layer;
    return [layer captureDevicePointOfInterestForPoint:point];
}

#pragma mark - Tap Recognizer

//聚焦
- (void)focusRecognizer:(UITapGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self];
    [self runBoxAnimationOnView:self.focusView point:point];
    if ([self.delegate respondsToSelector:@selector(focusAtPoint:)]) {
        [self.delegate focusAtPoint:[self fetchCaptureDevicePointFromPoint:point]];
    }
}

//曝光
- (void)exposureRecognizer:(UITapGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self];
    [self runBoxAnimationOnView:self.exposureView point:point];
    if ([self.delegate respondsToSelector:@selector(exposureAtPoint:)]) {
        [self.delegate exposureAtPoint:[self fetchCaptureDevicePointFromPoint:point]];
    }
}

#pragma mark - getter && setter
- (AVCaptureSession *)session
{
    return ((AVCaptureVideoPreviewLayer *)self.layer).session;
}

- (void)setSession:(AVCaptureSession *)session
{
    //AVCaptureVideoPreviewLayer 实例，并且设置AVCaptureSession 将捕捉数据直接输出到图层中，并确保与会话状态同步。
    [((AVCaptureVideoPreviewLayer *)self.layer) setSession:session];
}

- (void)setFocusEnable:(BOOL)focusEnable
{
    _focusEnable = focusEnable;
    self.singleTapRecognizer.enabled = focusEnable;
}

- (void)setExposureEnable:(BOOL)exposureEnable
{
    _exposureEnable = exposureEnable;
    self.doubleTapRecognizer.enabled = exposureEnable;
}

@end
