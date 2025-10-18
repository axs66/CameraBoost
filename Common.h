#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Timer pause/resume constants
static const void *NSTimerPauseDate = &NSTimerPauseDate;
static const void *NSTimerPreviousFireDate = &NSTimerPreviousFireDate;

// Camera mode and device constants
#define CAMERA_MODE_VIDEO 1
#define CAMERA_MODE_SLOMO 2
#define CAMERA_DEVICE_BACK 0
#define CAMERA_DEVICE_FRONT 1

// Video configuration modes
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

// Utility functions
BOOL checkModeAndDevice(NSInteger mode, NSInteger device);
BOOL isBackCamera(NSInteger device);
NSString *title(VideoConfigurationMode mode);
NSInteger getVideoConfigurationResolution(VideoConfigurationMode mode);
NSInteger getVideoConfigurationFramerate(VideoConfigurationMode mode);
