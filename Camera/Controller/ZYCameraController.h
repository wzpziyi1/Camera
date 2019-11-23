//
//  ZYCameraController.h
//  Camera
//
//  Created by wzp on 2019/11/23.
//  Copyright © 2019 wzp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol ZYCameraControllerDelegate <NSObject>

//设备添加、删除错误抛出
- (void)deviceConfigurationFailedWithError:(NSError *)error;


@end

@interface ZYCameraController : NSObject
@property (nonatomic, strong) id<ZYCameraControllerDelegate>delegate;
@property (nonatomic, strong, readonly) AVCaptureSession *captureSession;

//设置、配置视频补抓session
- (BOOL)setupSession:(NSError **)error;
- (void)startSession;
- (void)stopSession;

//切换摄像头
- (BOOL)switchCameras;
- (BOOL)canSwitchCameras;
@end
