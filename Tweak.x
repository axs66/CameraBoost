#define UNRESTRICTED_AVAILABILITY
#import "Common.h"
#import <UIKit/UIColor+Private.h>
#import <UIKit/UIImage+Private.h>
#import <UIKit/UIApplication+Private.h>
#import <version.h>

// 全局变量定义
NSInteger devices[] = { 1, 0, 0, 0, 1, 1 };
NSInteger toFPS[] = { 24, 30, 60, 120, 240 };
NSString *NSTimerPauseDate = @"NSTimerPauseDate";
NSString *NSTimerPreviousFireDate = @"NSTimerPreviousFireDate";

// 函数实现
NSString *title(VideoConfigurationMode mode) {
    switch (mode) {
        case VideoConfigurationModeDefault:
            return @"Default";
        case VideoConfigurationMode1080p60:
            return @"1080p60";
        case VideoConfigurationMode720p120:
            return @"720p120";
        case VideoConfigurationMode720p240:
            return @"720p240";
        case VideoConfigurationMode1080p120:
            return @"1080p120";
        case VideoConfigurationMode4k30:
            return @"4k30";
        case VideoConfigurationMode720p30:
            return @"720p30";
        case VideoConfigurationMode1080p30:
            return @"1080p30";
        case VideoConfigurationMode1080p240:
            return @"1080p240";
        case VideoConfigurationMode4k60:
            return @"4k60";
        case VideoConfigurationMode4k24:
            return @"4k24";
        case VideoConfigurationMode1080p25:
            return @"1080p25";
        case VideoConfigurationMode4k25:
            return @"4k25";
        case VideoConfigurationMode4k120:
            return @"4k120";
        case VideoConfigurationMode4k100:
            return @"4k100";
        case VideoConfigurationModeCount:
            break;
    }
    return @"Unknown";
}

// 偏好设置键
#define kCameraBoostEnabled @"CameraBoostEnabled"
#define kPauseResumeEnabled @"PauseResumeEnabled"
#define kVideoConfigEnabled @"VideoConfigEnabled"
#define kFlashlightToggleEnabled @"FlashlightToggleEnabled"
#define kMillisecondDisplayEnabled @"MillisecondDisplayEnabled"
#define kModeHidingEnabled @"ModeHidingEnabled"
#define kHiddenModes @"HiddenModes"

// 手电筒控制
@interface AVCaptureDevice (CameraBoost)
+ (AVCaptureDevice *)defaultDeviceWithMediaType:(NSString *)mediaType;
- (BOOL)hasTorch;
- (BOOL)isTorchAvailable;
- (BOOL)setTorchMode:(NSInteger)torchMode error:(NSError **)outError;
- (NSInteger)torchMode;
@end

// 手电筒模式常量
#define AVCaptureTorchModeOff 0
#define AVCaptureTorchModeOn 1
#define AVCaptureTorchModeAuto 2

// 私有类声明和函数声明
@interface AVCaptureMovieFileOutput (Private)
- (BOOL)isRecordingPaused;
- (void)pauseRecording;
- (void)resumeRecording;
@end

@interface CAMLiquidShutterRenderer : NSObject
- (void)renderIfNecessary;
@end

@interface UIView (Private)
@property (nonatomic, assign, setter=_setShouldReverseLayoutDirection:) BOOL _shouldReverseLayoutDirection;
@end

extern CGRect UIRectIntegralWithScale(CGRect rect, CGFloat scale);
extern CGFloat UIRoundToViewScale(CGFloat value, UIView *view);

// 类型声明
typedef struct {
    float r, g, b;
} CAMShutterColor;

// 简化的功能实现 - 只保留基本功能，避免复杂的属性声明
%hook CAMViewfinderViewController

- (void)_createVideoControlsIfNecessary {
    %orig;
    // 基本的手电筒按钮功能
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kFlashlightToggleEnabled]) {
        [self createFlashlightButtonIfNecessary];
    }
}

%new(v@:)
- (void)createFlashlightButtonIfNecessary {
    // 简化的手电筒按钮实现
    UIButton *flashlightButton = objc_getAssociatedObject(self, @selector(flashlightButton));
    if (flashlightButton || ![[NSUserDefaults standardUserDefaults] boolForKey:kFlashlightToggleEnabled]) return;
    
    flashlightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [flashlightButton setTitle:@"🔦" forState:UIControlStateNormal];
    flashlightButton.titleLabel.font = [UIFont systemFontOfSize:24];
    flashlightButton.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
    flashlightButton.layer.cornerRadius = 20;
    flashlightButton.frame = CGRectMake(20, 100, 40, 40);
    
    [flashlightButton addTarget:self action:@selector(handleFlashlightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:flashlightButton];
    objc_setAssociatedObject(self, @selector(flashlightButton), flashlightButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new(v@:@)
- (void)handleFlashlightButtonPressed:(UIButton *)button {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device || !device.hasTorch) return;
    
    NSError *error;
    NSInteger currentMode = device.torchMode;
    NSInteger newMode = (currentMode == AVCaptureTorchModeOn) ? AVCaptureTorchModeOff : AVCaptureTorchModeOn;
    
    if ([device setTorchMode:newMode error:&error]) {
        [button setTitle:(newMode == AVCaptureTorchModeOn) ? @"🔦" : @"💡" forState:UIControlStateNormal];
    }
}

%end

%hook CAMCaptureCapabilities

- (bool)interactiveVideoFormatControlAlwaysEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kVideoConfigEnabled];
}

%end

%ctor {
    // 初始化代码
    %init;
}
