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

// 私有类最小接口声明
@interface CUShutterButton : UIButton
@property (nonatomic) UIEdgeInsets tappableEdgeInsets;
- (CGSize)intrinsicContentSize;
- (CGRect)frameForAlignmentRect:(CGRect)rect;
@end

@interface CAMViewfinderViewController : UIViewController
@property (nonatomic, readonly) NSInteger _currentMode;
@property (nonatomic, readonly) NSInteger _currentDevice;
- (id)_currentGraphConfiguration;
- (BOOL)_isSpatialVideoInVideoModeActiveForMode:(NSInteger)mode devicePosition:(NSInteger)position;
- (BOOL)_shouldHideStillDuringVideoButtonForGraphConfiguration:(id)configuration;
- (BOOL)_shouldHideStillDuringVideoButtonForMode:(NSInteger)mode device:(NSInteger)device;
- (id)_captureController;
@end

@interface CAMCaptureGraphConfiguration : NSObject
@property (nonatomic) NSInteger mode;
@property (nonatomic) NSInteger devicePosition;
@property (nonatomic) NSInteger videoEncodingBehavior;
@end

@interface CUCaptureController : NSObject
- (BOOL)isCapturingCTMVideo;
@end

@interface CAMDynamicShutterControl : NSObject
@property (nonatomic) BOOL overrideShutterButtonColor;
@end

// 已有私有扩展
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
