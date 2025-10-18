#define UNRESTRICTED_AVAILABILITY
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// ======================
// 视频配置模式
// ======================
typedef NS_ENUM(NSInteger, VideoConfigurationMode) {
    VideoConfigurationModeDefault = 0,
    VideoConfigurationMode1080p60,
    VideoConfigurationMode720p120,
    VideoConfigurationMode720p240,
    VideoConfigurationMode1080p120,
    VideoConfigurationMode4k30,
    VideoConfigurationMode720p30,
    VideoConfigurationMode1080p30,
    VideoConfigurationMode1080p240,
    VideoConfigurationMode4k60,
    VideoConfigurationMode4k24,
    VideoConfigurationMode1080p25,
    VideoConfigurationMode4k25,
    VideoConfigurationMode4k120,
    VideoConfigurationMode4k100,
    VideoConfigurationModeCount
};

// ======================
// 全局变量
// ======================
extern NSInteger devices[];
extern NSInteger toFPS[];
extern NSString *NSTimerPauseDate;
extern NSString *NSTimerPreviousFireDate;

// ======================
// 函数声明
// ======================
NSString *title(VideoConfigurationMode mode);

// ======================
// 类型
// ======================
typedef struct { float r,g,b; } CAMShutterColor;

// ======================
// 前向声明
// ======================
@class CAMElapsedTimeView;
@class CAMViewfinderViewController;
@class CAMDynamicShutterControl;
@class CAMBottomBar;
@class CUShutterButton;
@class CAMCaptureGraphConfiguration;
@class CUCaptureController;
@class CAMCaptureEngine;
@class CAMCaptureMovieFileOutput;
@class CAMFramerateIndicatorView;
@class CAMCaptureCapabilities;
@class CAMUserPreferences;

// ======================
// 偏好设置键
// ======================
#define kCameraBoostEnabled @"CameraBoostEnabled"
#define kPauseResumeEnabled @"PauseResumeEnabled"
#define kVideoConfigEnabled @"VideoConfigEnabled"
#define kFlashlightToggleEnabled @"FlashlightToggleEnabled"
#define kMillisecondDisplayEnabled @"MillisecondDisplayEnabled"
#define kModeHidingEnabled @"ModeHidingEnabled"
#define kHiddenModes @"HiddenModes"

// ======================
// 私有类扩展
// ======================
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

// ======================
// CAMViewfinderViewController 扩展
// ======================
@interface CAMViewfinderViewController : UIViewController
@property (nonatomic, retain) UIButton *flashlightToggleButton;
@property (nonatomic, retain) CUShutterButton *_pauseResumeDuringVideoButton;
@property (nonatomic, strong) id _currentGraphConfiguration;
@property (nonatomic, strong) CAMElapsedTimeView *_elapsedTimeView;
@property (nonatomic, strong) CUShutterButton *_shutterButton;

- (void)_writeUserPreferences;
- (void)readUserPreferencesAndHandleChangesWithOverrides:(NSInteger)overrides;
@end

@interface CAMCaptureCapabilities : NSObject
+ (instancetype)capabilities;
- (BOOL)isSupportedVideoConfiguration:(VideoConfigurationMode)mode forMode:(NSInteger)cameraMode device:(NSInteger)device;
@end

@interface CAMUserPreferences : NSObject
+ (instancetype)preferences;
- (VideoConfigurationMode)videoConfiguration;
@end

@interface CAMElapsedTimeView : UIView
@property (nonatomic, strong) UILabel *_timeLabel;
@property (nonatomic, strong) NSDate *__startTime;
@property (nonatomic, strong) NSTimer *__updateTimer;
- (void)updateUI:(BOOL)pause recording:(BOOL)recording;
@end
