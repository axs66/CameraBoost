#define UNRESTRICTED_AVAILABILITY
#import "Common.h"
#import <UIKit/UIColor+Private.h>
#import <UIKit/UIImage+Private.h>
#import <UIKit/UIApplication+Private.h>
#import <version.h>
#import <CameraUI/UIFont+CameraUIAdditions.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreText/CoreText.h>
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>

// ===============================
// 全局变量定义
// ===============================
NSInteger devices[] = { 1, 0, 0, 0, 1, 1 };
NSInteger toFPS[] = { 24, 30, 60, 120, 240 };
NSString *NSTimerPauseDate = @"NSTimerPauseDate";
NSString *NSTimerPreviousFireDate = @"NSTimerPreviousFireDate";

// ===============================
// 函数实现
// ===============================
NSString *title(VideoConfigurationMode mode) {
    switch (mode) {
        case VideoConfigurationModeDefault: return @"Default";
        case VideoConfigurationMode1080p60: return @"1080p60";
        case VideoConfigurationMode720p120: return @"720p120";
        case VideoConfigurationMode720p240: return @"720p240";
        case VideoConfigurationMode1080p120: return @"1080p120";
        case VideoConfigurationMode4k30: return @"4k30";
        case VideoConfigurationMode720p30: return @"720p30";
        case VideoConfigurationMode1080p30: return @"1080p30";
        case VideoConfigurationMode1080p240: return @"1080p240";
        case VideoConfigurationMode4k60: return @"4k60";
        case VideoConfigurationMode4k24: return @"4k24";
        case VideoConfigurationMode1080p25: return @"1080p25";
        case VideoConfigurationMode4k25: return @"4k25";
        case VideoConfigurationMode4k120: return @"4k120";
        case VideoConfigurationMode4k100: return @"4k100";
        case VideoConfigurationModeCount: break;
    }
    return @"Unknown";
}

// ===============================
// RecordPause 功能
// ===============================
static void layoutPauseResumeDuringVideoButton(UIView *view, CUShutterButton *button, UIView *shutterButton, CGFloat displayScale, BOOL fixedPosition) {
    CGSize size = [button intrinsicContentSize];
    CGRect rect = UIRectIntegralWithScale(CGRectMake(0, 0, size.width, size.height), displayScale);
    CGRect alignmentRect = [shutterButton alignmentRectForFrame:shutterButton.frame];
    CGFloat midY = CGRectGetMidY(alignmentRect);
    CGFloat y = UIRoundToViewScale(midY - (size.height / 2), view);
    CGFloat x;
    CGRect bounds = view.bounds;
    if ([view _shouldReverseLayoutDirection] || fixedPosition)
        x = CGRectGetMinX(bounds) + 15;
    else
        x = CGRectGetMaxX(bounds) - size.width - 15;
    button.tappableEdgeInsets = UIEdgeInsetsMake(20, 20, 20, 20);
    button.frame = [button frameForAlignmentRect:CGRectMake(x, y, rect.size.width, rect.size.height)];
}

static BOOL shouldHidePauseResumeDuringVideoButton(CAMViewfinderViewController *self) {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kPauseResumeEnabled]) return YES;
    
    CAMCaptureGraphConfiguration *configuration = nil;
    if ([self respondsToSelector:@selector(_currentGraphConfiguration)]) {
        configuration = [self _currentGraphConfiguration];
        if ([self respondsToSelector:@selector(_isSpatialVideoInVideoModeActiveForMode:devicePosition:)] &&
            [self _isSpatialVideoInVideoModeActiveForMode:configuration.mode devicePosition:configuration.devicePosition])
            return YES;
        if (configuration.videoEncodingBehavior > 1)
            return YES;
    }
    CUCaptureController *cuc = [self _captureController];
    if ([cuc respondsToSelector:@selector(isCapturingCTMVideo)] && [cuc isCapturingCTMVideo])
        return YES;
    if (configuration)
        return [self _shouldHideStillDuringVideoButtonForGraphConfiguration:configuration];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self _shouldHideStillDuringVideoButtonForMode:self._currentMode device:self._currentDevice];
#pragma clang diagnostic pop
}

// ===============================
// FlashlightToggle 功能 (UI 按钮)
// ===============================
#define FLASHLIGHT_BUTTON_SIZE 36.0
%hook CAMViewfinderViewController

%property (nonatomic, retain) UIButton *flashlightToggleButton;

%new
- (void)_createFlashlightToggleButtonIfNecessary {
    if (self.flashlightToggleButton) return;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *icon = [UIImage systemImageNamed:@"flashlight.off.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20]];
    [button setImage:icon forState:UIControlStateNormal];
    button.tintColor = UIColor.whiteColor;
    button.frame = CGRectMake(15, 50, FLASHLIGHT_BUTTON_SIZE, FLASHLIGHT_BUTTON_SIZE);
    button.layer.cornerRadius = FLASHLIGHT_BUTTON_SIZE / 2;
    button.layer.masksToBounds = YES;
    button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    [button addTarget:self action:@selector(toggleFlashlightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    self.flashlightToggleButton = button;
}

%new
- (void)toggleFlashlightButtonPressed:(UIButton *)button {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch] && [device isTorchAvailable]) {
        NSError *error = nil;
        [device lockForConfiguration:&error];
        if (!error) {
            if (device.torchMode == AVCaptureTorchModeOn) {
                [device setTorchMode:AVCaptureTorchModeOff];
                [button setImage:[UIImage systemImageNamed:@"flashlight.off.fill"] forState:UIControlStateNormal];
            } else {
                [device setTorchModeOnWithLevel:1.0 error:nil];
                [button setImage:[UIImage systemImageNamed:@"flashlight.on.fill"] forState:UIControlStateNormal];
            }
            [device unlockForConfiguration];
        }
    }
}

%end

// ===============================
// MillisecondDisplay 功能
// ===============================
%hook CAMElapsedTimeView

%new
- (NSString *)formattedElapsedTimeIncludingMilliseconds {
    NSDate *startTime = [self valueForKey:@"__startTime"];
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
    NSInteger minutes = (NSInteger)(elapsed/60);
    NSInteger seconds = (NSInteger)elapsed % 60;
    NSInteger milliseconds = (NSInteger)((elapsed - floor(elapsed)) * 100);
    return [NSString stringWithFormat:@"%02ld:%02ld.%02ld", (long)minutes, (long)seconds, (long)milliseconds];
}

%new
- (void)updateTimeLabel {
    self._timeLabel.text = [self formattedElapsedTimeIncludingMilliseconds];
}

%end

// ===============================
// ModeHiding 功能
// ===============================
%hook CAMCaptureCapabilities

- (BOOL)isSupportedVideoConfiguration:(VideoConfigurationMode)mode forMode:(NSInteger)cameraMode device:(NSInteger)devicePosition {
    NSArray *hiddenModes = [[NSUserDefaults standardUserDefaults] arrayForKey:kHiddenModes] ?: @[];
    NSString *modeTitle = title(mode);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kModeHidingEnabled] && [hiddenModes containsObject:modeTitle])
        return NO;
    return %orig(mode, cameraMode, devicePosition);
}

%end

// ===============================
// TapVideoConfig 功能
// ===============================
%hook CAMViewfinderViewController

- (void)_createFramerateIndicatorViewIfNecessary {
    %orig;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kVideoConfigEnabled]) return;
    CAMFramerateIndicatorView *view = [self valueForKey:@"_framerateIndicatorView"];
    if (!view) return;
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeVideoConfigurationMode:)];
    [view addGestureRecognizer:tap];
}

%new
- (void)changeVideoConfigurationMode:(UITapGestureRecognizer *)gesture {
    NSInteger cameraMode = self._currentGraphConfiguration.mode;
    NSInteger cameraDevice = self._currentGraphConfiguration.device == 0 ? 0 : devices[self._currentGraphConfiguration.device - 1];
    NSString *message = @"选择视频配置:";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CameraBoost" message:message preferredStyle:UIAlertControllerStyleAlert];
    NSMutableDictionary <NSString *, NSNumber *> *modes = [NSMutableDictionary dictionary];
    
    VideoConfigurationMode currentVideoConfigurationMode = [[NSClassFromString(@"CAMUserPreferences") preferences] videoConfiguration];
    CAMCaptureCapabilities *capabilities = [NSClassFromString(@"CAMCaptureCapabilities") capabilities];
    for (VideoConfigurationMode mode = 0; mode < VideoConfigurationModeCount; ++mode) {
        if (mode != currentVideoConfigurationMode && [capabilities isSupportedVideoConfiguration:mode forMode:cameraMode device:cameraDevice])
            modes[title(mode)] = @(mode);
    }
    
    NSArray <NSString *> *sortedArray = [[modes allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (NSString *mode in sortedArray) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:mode style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self _writeUserPreferences];
            CFPreferencesSetAppValue(cameraMode == 2 ? CFSTR("CAMUserPreferenceSlomoConfiguration") : CFSTR("CAMUserPreferenceVideoConfiguration"), (CFNumberRef)modes[mode], CFSTR("com.apple.camera"));
            CFPreferencesAppSynchronize(CFSTR("com.apple.camera"));
            [self readUserPreferencesAndHandleChangesWithOverrides:0];
        }];
        [alert addAction:action];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

%end

// ===============================
// 构造函数
// ===============================
%ctor {
    %init;
}
