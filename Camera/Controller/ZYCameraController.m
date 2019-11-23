//
//  ZYCameraController.m
//  Camera
//
//  Created by wzp on 2019/11/23.
//  Copyright © 2019 wzp. All rights reserved.
//

#import "ZYCameraController.h"

@interface ZYCameraController()
@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong, readwrite) AVCaptureSession *captureSession;
//记录当前工作的摄像头，用来切换摄像头
@property (nonatomic, strong) AVCaptureDeviceInput *activeVideoInput;

//从摄像头补抓图片
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;
//将Quick Time 电影录制到文件系统
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieOutput;

//摄像头个数
@property (nonatomic, assign) NSInteger cameraCount;

@end

@implementation ZYCameraController

#pragma mark - 初始化配置
- (instancetype)init
{
    if (self = [super init]) {
        self.videoQueue = dispatch_queue_create("com.zycameracontroller", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (BOOL)setupSession:(NSError **)error
{
    //创建捕捉会话
    self.captureSession = [[AVCaptureSession alloc] init];
    
    //设置图像的分辨率
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    //拿到默认的视频补抓device，默认为后置摄像头
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //为会话添加捕捉设备，需要将设备封装成AVCaptureDeviceInput对象
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
    
    if (!videoInput) {
        return NO;
    }
    
    //判断session能否添加设备
    if ([self.captureSession canAddInput:videoInput]) {
        [self.captureSession addInput:videoInput];
        self.activeVideoInput = videoInput;
    }
    
    //获取音频补抓设备，返回麦克风设备
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:error];
    
    if (!audioInput) {
        return NO;
    }
    
    //添加音频补抓设备
    if ([self.captureSession canAddInput:audioInput]) {
        [self.captureSession addInput:audioInput];
    }
    
    //AVCaptureStillImageOutput 实例 从摄像头捕捉静态图片
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    //设置捕捉到JPEG格式的图片
    self.imageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
    //输出连接判断
    if ([self.captureSession canAddOutput:self.imageOutput]) {
        [self.captureSession addOutput:self.imageOutput];
    }
    
    //创建一个AVCaptureMovieFileOutput 实例，用于将Quick Time 电影录制到文件系统
    self.movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.captureSession canAddOutput:self.movieOutput]) {
        [self.captureSession addOutput:self.movieOutput];
    }
    return YES;
}

- (void)startSession
{
    //检查session是否处于运行状态
    if (![self.captureSession isRunning]) {
        dispatch_async(self.videoQueue, ^{
            [self.captureSession startRunning];
        });
    }
}

- (void)stopSession
{
    if ([self.captureSession isRunning]) {
        dispatch_async(self.videoQueue, ^{
            [self.captureSession stopRunning];
        });
    }
}

#pragma mark - 摄像头切换配置

//切换摄像头
- (BOOL)switchCameras;
{
    //判断是否有多个摄像头
    if (![self canSwitchCameras]) {
        return NO;
    }
    
    //获取当前摄像头的反向设备
    NSError *error = nil;
    AVCaptureDevice *videoDevice = [self inactiveCaptureDevice];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    if (!videoInput) {
        //创建AVCaptureDeviceInput错误，抛出
        self.delegate == nil ? nil : [self.delegate deviceConfigurationFailedWithError:error];
        return NO;
    }
    
    //标注原配置变化开始
    [self.captureSession beginConfiguration];
    //先移除原有的
    [self.captureSession removeInput:self.activeVideoInput];
    //添加新的，如果不能添加，需要恢复原有的摄像头
    if ([self.captureSession canAddInput:videoInput]) {
        [self.captureSession addInput:videoInput];
        self.activeVideoInput = videoInput;
    }
    else {
        //新设备无法加入。则将原本的视频捕捉设备重新加入到捕捉会话中
        [self.captureSession addInput:self.activeVideoInput];
        error = [NSError errorWithDomain:@"switchCameras addInput failure" code:-1 userInfo:nil];
    }
    //配置完成后， AVCaptureSession commitConfiguration 会分批的将所有变更整合在一起。
    [self.captureSession commitConfiguration];
    
    if (error) {
        self.delegate == nil ? nil : [self.delegate deviceConfigurationFailedWithError:error];
        return NO;
    }
    return YES;
}

- (BOOL)canSwitchCameras
{
    return self.cameraCount > 1;
}

//返回当前未激活的摄像头，如果active设备是后置(前置)摄像头则返回前置(后置)
- (AVCaptureDevice *)inactiveCaptureDevice
{
    AVCaptureDevice *device = nil;
    if (self.cameraCount > 1) {
        AVCaptureDevicePosition position = [self activeCamera].position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
        return [self cameraWithPosition:position];
    }
    return device;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    //遍历可用的视频设备 并返回position的device
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)activeCamera
{
    return self.activeVideoInput.device;
}

#pragma mark - getter && setter
- (NSInteger)cameraCount
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}
@end
