#define UNRESTRICTED_AVAILABILITY
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// 视频配置模式枚举
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

// 全局变量
extern NSInteger devices[];
extern NSInteger toFPS[];
extern NSString *NSTimerPauseDate;
extern NSString *NSTimerPreviousFireDate;

// 函数声明
NSString *title(VideoConfigurationMode mode);

// 类型声明
typedef struct {
    float r, g, b;
} CAMShutterColor;

// 偏好设置键
#define kCameraBoostEnabled @"CameraBoostEnabled"
#define kPauseResumeEnabled @"PauseResumeEnabled"
#define kVideoConfigEnabled @"VideoConfigEnabled"
#define kFlashlightToggleEnabled @"FlashlightToggleEnabled"
#define kMillisecondDisplayEnabled @"MillisecondDisplayEnabled"
#define kModeHidingEnabled @"ModeHidingEnabled"
#define kHiddenModes @"HiddenModes"

@interface CAMElapsedTimeView (Addition)
- (void)pauseTimer;
- (void)resumeTimer;
- (void)updateUI:(BOOL)pause recording:(BOOL)recording;
@end

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

@interface CAMViewfinderViewController (Addition)
@property (retain, nonatomic) UILongPressGestureRecognizer *rpGesture;
@property (nonatomic, retain) CUShutterButton *_pauseResumeDuringVideoButton;
- (void)_createPauseResumeDuringVideoButtonIfNecessary;
- (void)_embedPauseResumeDuringVideoButtonWithLayoutStyle:(NSInteger)layoutStyle;
- (void)_updatePauseResumeDuringVideoButton:(BOOL)paused;
@end

@interface CAMDynamicShutterControl (Addition)
@property (nonatomic, retain) CUShutterButton *pauseResumeDuringVideoButton;
@property (nonatomic, assign) BOOL overrideShutterButtonColor;
@end

@interface CAMBottomBar (Addition)
@property (nonatomic, retain) CUShutterButton *pauseResumeDuringVideoButton;
- (void)_layoutPauseResumeDuringVideoButtonForLayoutStyle:(NSInteger)layoutStyle;
- (void)_layoutPauseResumeDuringVideoButtonForTraitCollection:(UITraitCollection *)traitCollection;
@end

NSString *NSTimerPauseDate = @"NSTimerPauseDate";
NSString *NSTimerPreviousFireDate = @"NSTimerPreviousFireDate";
