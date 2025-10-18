#define UNRESTRICTED_AVAILABILITY
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreText/CoreText.h>

// ===============================
// 视频配置模式枚举
// ===============================
typedef NS_ENUM(NSInteger, VideoConfigurationMode) {
    VideoConfigurationModeDefault = 0,
    VideoConfigurationMode1080p60 = 1,
    VideoConfigurationMode720p120 = 2,
    VideoConfigurationMode720p240 = 3,
    VideoConfigurationMode1080p120 = 4,
    VideoConfigurationMode4k30 = 5,
    VideoConfigurationMode720p30 = 6,
    VideoConfigurationMode1080p30 = 7,
    VideoConfigurationMode1080p240 = 8,
    VideoConfigurationMode4k60 = 9,
    VideoConfigurationMode4k24 = 10,
    VideoConfigurationMode1080p25 = 11,
    VideoConfigurationMode4k25 = 12,
    VideoConfigurationMode4k120 = 13,
    VideoConfigurationMode4k100 = 14,
    VideoConfigurationModeCount
};

// ===============================
// 全局变量
// ===============================
extern NSInteger devices[];
extern NSInteger toFPS[];
extern NSString *NSTimerPauseDate;
extern NSString *NSTimerPreviousFireDate;

// ===============================
// 函数声明
// ===============================
NSString *title(VideoConfigurationMode mode);

// ===============================
// 类型声明
// ===============================
typedef struct {
    float r, g, b;
} CAMShutterColor;

// ===============================
// 偏好设置键
// ===============================
#define kCameraBoostEnabled @"CameraBoostEnabled"
#define kPauseResumeEnabled @"PauseResumeEnabled"
#define kVideoConfigEnabled @"VideoConfigEnabled"
#define kFlashlightToggleEnabled @"FlashlightToggleEnabled"
#define kMillisecondDisplayEnabled @"MillisecondDisplayEnabled"
#define kModeHidingEnabled @"ModeHidingEnabled"
#define kHiddenModes @"HiddenModes"

// ===============================
// 私有类接口声明
// ===============================

@interface CUShutterButton : UIButton
@property (nonatomic) UIEdgeInsets tappableEdgeInsets;
@property (nonatomic) NSInteger mode;
@property (nonatomic, strong) UIView *_innerView;
+ (instancetype)smallShutterButtonWithLayoutStyle:(NSInteger)layoutStyle;
+ (instancetype)smallShutterButton;
- (CGSize)intrinsicContentSize;
- (CGRect)frameForAlignmentRect:(CGRect)rect;
@end

@interface CAMCaptureGraphConfiguration : NSObject
@property (nonatomic) NSInteger mode;
@property (nonatomic) NSInteger devicePosition;
@property (nonatomic) NSInteger videoEncodingBehavior;
@end

@interface CUCaptureController : NSObject
- (BOOL)isCapturingVideo;
- (BOOL)isCapturingCTMVideo;
- (id)_captureEngine;
@end

@interface CAMDynamicShutterControl : NSObject
@property (nonatomic) BOOL overrideShutterButtonColor;
@property (nonatomic, retain) CUShutterButton *pauseResumeDuringVideoButton;
- (void)_updateRendererShapes;
@end

@interface CAMElapsedTimeView : UIView
@property (nonatomic, strong) UILabel *_timeLabel;
@property (nonatomic, strong) UIImageView *_recordingImageView;
- (void)pauseTimer;
- (void)resumeTimer;
- (void)updateUI:(BOOL)pause recording:(BOOL)recording;
@end

@interface CAMViewfinderViewController : UIViewController
@property (nonatomic, readonly) NSInteger _currentMode;
@property (nonatomic, readonly) NSInteger _currentDevice;
@property (nonatomic, strong) CAMElapsedTimeView *_elapsedTimeView;
@property (nonatomic, strong) CUShutterButton *_shutterButton;
@property (nonatomic, strong) CAMDynamicShutterControl *_dynamicShutterControl;

- (CAMCaptureGraphConfiguration *)_currentGraphConfiguration;
- (CUCaptureController *)_captureController;
- (BOOL)_isSpatialVideoInVideoModeActiveForMode:(NSInteger)mode devicePosition:(NSInteger)position;
- (BOOL)_shouldHideStillDuringVideoButtonForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration;
- (BOOL)_shouldHideStillDuringVideoButtonForMode:(NSInteger)mode device:(NSInteger)device;
@end

@interface CAMLiquidShutterRenderer : NSObject
- (void)renderIfNecessary;
@end

@interface CAMBottomBar : UIView
@property (nonatomic, retain) CUShutterButton *pauseResumeDuringVideoButton;
@property (nonatomic, strong) CUShutterButton *shutterButton;
@end

// ===============================
// 私有扩展
// ===============================
@interface AVCaptureMovieFileOutput (Private)
- (BOOL)isRecordingPaused;
- (void)pauseRecording;
- (void)resumeRecording;
@end

@interface UIView (Private)
@property (nonatomic, assign, setter=_setShouldReverseLayoutDirection:) BOOL _shouldReverseLayoutDirection;
@end

// ===============================
// UI 计算工具函数
// ===============================
extern CGRect UIRectIntegralWithScale(CGRect rect, CGFloat scale);
extern CGFloat UIRoundToViewScale(CGFloat value, UIView *view);
