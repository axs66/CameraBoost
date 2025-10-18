#define UNRESTRICTED_AVAILABILITY
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// 前向声明
@class CAMElapsedTimeView;
@class CAMViewfinderViewController;
@class CAMDynamicShutterControl;
@class CAMBottomBar;
@class CAMModeDial;
@class CUShutterButton;
@class CAMCaptureGraphConfiguration;

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

// 接口扩展 - 这些类别定义已移动到 Tweak.x 文件中
