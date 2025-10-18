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

// 毫秒显示相关
@interface CAMElapsedTimeView (MillisecondDisplay)
@property (nonatomic, retain) UILabel *millisecondLabel;
@property (nonatomic, retain) NSTimer *millisecondTimer;
@end

// 模式隐藏相关
@interface CAMModeDial (ModeHiding)
@property (nonatomic, retain) NSMutableSet *hiddenModes;
@end

// 手电筒按钮
@interface CAMViewfinderViewController (FlashlightButton)
@property (nonatomic, retain) UIButton *flashlightButton;
- (void)createFlashlightButtonIfNecessary;
- (void)updateFlashlightButtonVisibility;
- (void)handleFlashlightButtonPressed:(UIButton *)button;
@end

// 毫秒显示实现
%hook CAMElapsedTimeView

%property (nonatomic, retain) UILabel *millisecondLabel;
%property (nonatomic, retain) NSTimer *millisecondTimer;

- (void)startTimer {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kMillisecondDisplayEnabled]) {
        [self startMillisecondTimer];
    }
}

- (void)endTimer {
    [self stopMillisecondTimer];
    %orig;
}

%new(v@:)
- (void)startMillisecondTimer {
    [self stopMillisecondTimer];
    self.millisecondTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateMillisecondDisplay) userInfo:nil repeats:YES];
}

%new(v@:)
- (void)stopMillisecondTimer {
    [self.millisecondTimer invalidate];
    self.millisecondTimer = nil;
}

%new(v@:)
- (void)updateMillisecondDisplay {
    if (!self.millisecondLabel) {
        [self createMillisecondLabel];
    }
    
    NSDate *startTime = [self valueForKey:@"__startTime"];
    if (startTime) {
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
        int minutes = (int)(elapsed / 60);
        int seconds = (int)elapsed % 60;
        int milliseconds = (int)((elapsed - (int)elapsed) * 1000);
        
        self.millisecondLabel.text = [NSString stringWithFormat:@".%03d", milliseconds];
        self.millisecondLabel.hidden = NO;
    } else {
        self.millisecondLabel.hidden = YES;
    }
}

%new(v@:)
- (void)createMillisecondLabel {
    if (self.millisecondLabel) return;
    
    self.millisecondLabel = [[UILabel alloc] init];
    self.millisecondLabel.font = [UIFont systemFontOfSize:14];
    self.millisecondLabel.textColor = UIColor.whiteColor;
    self.millisecondLabel.textAlignment = NSTextAlignmentLeft;
    self.millisecondLabel.backgroundColor = UIColor.clearColor;
    
    [self addSubview:self.millisecondLabel];
    
    // 布局约束
    self.millisecondLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.millisecondLabel.leadingAnchor constraintEqualToAnchor:self._timeLabel.trailingAnchor constant:2],
        [self.millisecondLabel.centerYAnchor constraintEqualToAnchor:self._timeLabel.centerYAnchor]
    ]];
}

%end

// 手电筒按钮实现
%hook CAMViewfinderViewController

%property (nonatomic, retain) UIButton *flashlightButton;

- (void)_createVideoControlsIfNecessary {
    %orig;
    [self createFlashlightButtonIfNecessary];
}

%new(v@:)
- (void)createFlashlightButtonIfNecessary {
    if (self.flashlightButton || ![[NSUserDefaults standardUserDefaults] boolForKey:kFlashlightToggleEnabled]) return;
    
    self.flashlightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.flashlightButton setTitle:@"🔦" forState:UIControlStateNormal];
    self.flashlightButton.titleLabel.font = [UIFont systemFontOfSize:24];
    self.flashlightButton.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
    self.flashlightButton.layer.cornerRadius = 20;
    self.flashlightButton.frame = CGRectMake(20, 100, 40, 40);
    
    [self.flashlightButton addTarget:self action:@selector(handleFlashlightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.flashlightButton];
    [self updateFlashlightButtonVisibility];
}

%new(v@:)
- (void)updateFlashlightButtonVisibility {
    if (!self.flashlightButton) return;
    
    BOOL shouldShow = [[NSUserDefaults standardUserDefaults] boolForKey:kFlashlightToggleEnabled] && 
                     [self._captureController isCapturingVideo];
    self.flashlightButton.hidden = !shouldShow;
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

- (void)updateControlVisibilityAnimated:(BOOL)animated {
    %orig;
    [self updateFlashlightButtonVisibility];
}

%end

// 模式隐藏功能
%hook CAMModeDial

%property (nonatomic, retain) NSMutableSet *hiddenModes;

- (void)setHiddenModes:(NSMutableSet *)hiddenModes {
    objc_setAssociatedObject(self, @selector(hiddenModes), hiddenModes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableSet *)hiddenModes {
    NSMutableSet *modes = objc_getAssociatedObject(self, @selector(hiddenModes));
    if (!modes) {
        modes = [NSMutableSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kHiddenModes] ?: @[]];
        self.hiddenModes = modes;
    }
    return modes;
}

- (void)layoutSubviews {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kModeHidingEnabled]) {
        [self updateModeVisibility];
    }
}

%new(v@:)
- (void)updateModeVisibility {
    NSArray *subviews = self.subviews;
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"CAMModeDialItem")]) {
            NSInteger mode = [subview valueForKey:@"mode"];
            BOOL shouldHide = [self.hiddenModes containsObject:@(mode)];
            subview.hidden = shouldHide;
        }
    }
}

%end

// 毫秒显示功能
%hook CAMElapsedTimeView

%property (nonatomic, retain) UILabel *millisecondLabel;
%property (nonatomic, retain) NSTimer *millisecondTimer;

- (void)startTimer {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kMillisecondDisplayEnabled]) {
        [self startMillisecondTimer];
    }
}

- (void)endTimer {
    [self stopMillisecondTimer];
    %orig;
}

%new(v@:)
- (void)startMillisecondTimer {
    [self stopMillisecondTimer];
    self.millisecondTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateMillisecondDisplay) userInfo:nil repeats:YES];
}

%new(v@:)
- (void)stopMillisecondTimer {
    [self.millisecondTimer invalidate];
    self.millisecondTimer = nil;
}

%new(v@:)
- (void)updateMillisecondDisplay {
    if (!self.millisecondLabel) {
        [self createMillisecondLabel];
    }
    
    NSDate *startTime = [self valueForKey:@"__startTime"];
    if (startTime) {
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
        int minutes = (int)(elapsed / 60);
        int seconds = (int)elapsed % 60;
        int milliseconds = (int)((elapsed - (int)elapsed) * 1000);
        
        self.millisecondLabel.text = [NSString stringWithFormat:@".%03d", milliseconds];
        self.millisecondLabel.hidden = NO;
    } else {
        self.millisecondLabel.hidden = YES;
    }
}

%new(v@:)
- (void)createMillisecondLabel {
    if (self.millisecondLabel) return;
    
    self.millisecondLabel = [[UILabel alloc] init];
    self.millisecondLabel.font = [UIFont systemFontOfSize:14];
    self.millisecondLabel.textColor = UIColor.whiteColor;
    self.millisecondLabel.textAlignment = NSTextAlignmentLeft;
    self.millisecondLabel.backgroundColor = UIColor.clearColor;
    
    [self addSubview:self.millisecondLabel];
    
    // 布局约束
    self.millisecondLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.millisecondLabel.leadingAnchor constraintEqualToAnchor:self._timeLabel.trailingAnchor constant:2],
        [self.millisecondLabel.centerYAnchor constraintEqualToAnchor:self._timeLabel.centerYAnchor]
    ]];
}

%end

// 合并 RecordPause 功能
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
        if ([self respondsToSelector:@selector(_isSpatialVideoInVideoModeActiveForMode:devicePosition:)] && [self _isSpatialVideoInVideoModeActiveForMode:configuration.mode devicePosition:configuration.devicePosition])
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

%hook CAMDynamicShutterControl

%property (nonatomic, retain) CUShutterButton *pauseResumeDuringVideoButton;
%property (nonatomic, assign) BOOL overrideShutterButtonColor;

- (CAMShutterColor)_innerShapeColor {
    CAMShutterColor color = %orig;
    if (self.overrideShutterButtonColor) {
        CGFloat r, g, b;
        [UIColor.systemYellowColor getRed:&r green:&g blue:&b alpha:nil];
        color.r = r;
        color.g = g;
        color.b = b;
    }
    return color;
}

- (void)layoutSubviews {
    %orig;
    layoutPauseResumeDuringVideoButton(self, self.pauseResumeDuringVideoButton, [self _centerOuterView], self.traitCollection.displayScale, YES);
}

%end

%hook CAMElapsedTimeView

%new(v@:)
- (void)pauseTimer {
    NSTimer *timer = [self valueForKey:@"__updateTimer"];
    if (timer == nil) return;
    objc_setAssociatedObject(timer, (__bridge const void *)(NSTimerPauseDate), [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(timer, (__bridge const void *)(NSTimerPreviousFireDate), timer.fireDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    timer.fireDate = [NSDate distantFuture];
}

%new(v@:)
- (void)resumeTimer {
    NSTimer *timer = [self valueForKey:@"__updateTimer"];
    NSDate *pauseDate = objc_getAssociatedObject(timer, (__bridge const void *)NSTimerPauseDate);
    NSDate *previousFireDate = objc_getAssociatedObject(timer, (__bridge const void *)NSTimerPreviousFireDate);
    const NSTimeInterval pauseTime = -[pauseDate timeIntervalSinceNow];
    timer.fireDate = [NSDate dateWithTimeInterval:pauseTime sinceDate:previousFireDate];
    NSDate *newStartDate = [NSDate dateWithTimeInterval:pauseTime sinceDate:[self valueForKey:@"__startTime"]];
    [self setValue:newStartDate forKey:@"__startTime"];
}

%new(v@:BB)
- (void)updateUI:(BOOL)pause recording:(BOOL)recording {
    BOOL isBadgeStyle = [self respondsToSelector:@selector(usingBadgeAppearance)] && [self usingBadgeAppearance];
    UIColor *defaultColor = [self respondsToSelector:@selector(_backgroundRedColor)] ? [self _backgroundRedColor] : UIColor.redColor;
    UIImageView *backgroundView = nil;
    @try {
        backgroundView = [self valueForKey:@"_backgroundView"];
    } @catch (NSException *exception) {}
    if (isBadgeStyle) {
        backgroundView.tintColor = pause ? UIColor.systemYellowColor : (recording ? defaultColor : UIColor.clearColor);
    } else {
        UIColor *recordingImageColor = pause ? UIColor.systemYellowColor : defaultColor;
        self._timeLabel.textColor = pause ? UIColor.systemYellowColor : UIColor.whiteColor;
        if ([self respondsToSelector:@selector(_recordingImageView)] && self._recordingImageView)
            self._recordingImageView.image = [self._recordingImageView.image _flatImageWithColor:recordingImageColor];
        if (backgroundView)
            backgroundView.image = [backgroundView.image _flatImageWithColor:recordingImageColor];
    }
}

- (void)endTimer {
    NSTimer *timer = [self valueForKey:@"__updateTimer"];
    if (timer == nil) return;
    objc_setAssociatedObject(timer, (__bridge const void *)(NSTimerPauseDate), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(timer, (__bridge const void *)(NSTimerPreviousFireDate), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self updateUI:NO recording:NO];
    %orig;
}

%end

#define BUTTON_SIZE 47.0
%hook CAMBottomBar

%property (nonatomic, retain) CUShutterButton *pauseResumeDuringVideoButton;

%new(v@:l)
- (void)_layoutPauseResumeDuringVideoButtonForLayoutStyle:(NSInteger)layoutStyle {
    if (![[self class] wantsVerticalBarForLayoutStyle:layoutStyle])
        layoutPauseResumeDuringVideoButton(self, self.pauseResumeDuringVideoButton, self.shutterButton, self.traitCollection.displayScale, NO);
    else {
        CGRect frame = self.frame;
        CGFloat maxY = CGRectGetMaxY(frame) - (2 * (BUTTON_SIZE + 16.0));
        CGFloat midX = CGRectGetWidth(frame) / 2 - (BUTTON_SIZE / 2);
        self.pauseResumeDuringVideoButton.frame = CGRectMake(midX, maxY, BUTTON_SIZE, BUTTON_SIZE);
    }
}

%new(v@:@)
- (void)_layoutPauseResumeDuringVideoButtonForTraitCollection:(UITraitCollection *)traitCollection {
    if (![[self class] wantsVerticalBarForTraitCollection:traitCollection])
        layoutPauseResumeDuringVideoButton(self, self.pauseResumeDuringVideoButton, self.shutterButton, traitCollection.displayScale, NO);
    else {
        CGRect frame = self.frame;
        CGFloat maxY = CGRectGetMaxY(frame) - (2 * (BUTTON_SIZE + 16.0));
        CGFloat midX = CGRectGetWidth(frame) / 2 - (BUTTON_SIZE / 2);
        self.pauseResumeDuringVideoButton.frame = CGRectMake(midX, maxY, BUTTON_SIZE, BUTTON_SIZE);
    }
}

- (void)layoutSubviews {
    %orig;
    if ([self respondsToSelector:@selector(layoutStyle)])
        [self _layoutPauseResumeDuringVideoButtonForLayoutStyle:[self layoutStyle]];
    else
        [self _layoutPauseResumeDuringVideoButtonForTraitCollection:self.traitCollection];
}

%end

%hook CAMViewfinderViewController

%property (nonatomic, retain) CUShutterButton *_pauseResumeDuringVideoButton;

- (void)_createVideoControlsIfNecessary {
    %orig;
    [self _createPauseResumeDuringVideoButtonIfNecessary];
}

%new(v@:B)
- (void)_updatePauseResumeDuringVideoButton:(BOOL)paused {
    CUShutterButton *button = self._pauseResumeDuringVideoButton;
    UIView *innerView = button._innerView;
    UIImageView *pauseIcon = [button viewWithTag:2024];
    innerView.hidden = !paused;
    pauseIcon.hidden = paused;
}

%new(v@:)
- (void)_createPauseResumeDuringVideoButtonIfNecessary {
    if (self._pauseResumeDuringVideoButton || ![[NSUserDefaults standardUserDefaults] boolForKey:kPauseResumeEnabled]) return;
    NSInteger layoutStyle = [self respondsToSelector:@selector(_layoutStyle)] ? self._layoutStyle : 1;
    Class CUShutterButtonClass = %c(CUShutterButton);
    CUShutterButton *button = [CUShutterButtonClass respondsToSelector:@selector(smallShutterButtonWithLayoutStyle:)]
        ? [CUShutterButtonClass smallShutterButtonWithLayoutStyle:layoutStyle]
        : [CUShutterButtonClass smallShutterButton];
    UIView *innerView = button._innerView;
    UIImage *pauseImage = [UIImage systemImageNamed:@"pause.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:24]];
    UIImageView *pauseIcon = [[UIImageView alloc] initWithImage:pauseImage];
    pauseIcon.tintColor = UIColor.whiteColor;
    pauseIcon.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    pauseIcon.contentMode = UIViewContentModeCenter;
    pauseIcon.frame = innerView.bounds;
    pauseIcon.tag = 2024;
    [button addSubview:pauseIcon];
    innerView.hidden = YES;
    self._pauseResumeDuringVideoButton = button;
    [button addTarget:self action:@selector(handlePauseResumeDuringVideoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    button.mode = 1;
    button.exclusiveTouch = YES;
    [self _embedPauseResumeDuringVideoButtonWithLayoutStyle:layoutStyle];
}

%new(v@:l)
- (void)_embedPauseResumeDuringVideoButtonWithLayoutStyle:(NSInteger)layoutStyle {
    CUShutterButton *button = self._pauseResumeDuringVideoButton;
    BOOL shouldNotEmbed = layoutStyle == 2 ? YES : ([self respondsToSelector:@selector(isEmulatingImagePicker)] ? [self isEmulatingImagePicker] : NO);
    if ([self respondsToSelector:@selector(_shouldCreateAndEmbedControls)] ? [self _shouldCreateAndEmbedControls] : YES) {
        CAMBottomBar *bottomBar = self.viewfinderView.bottomBar;
        if (!shouldNotEmbed) {
            CUShutterButton *existingButton = bottomBar.pauseResumeDuringVideoButton;
            if (existingButton != button) {
                [existingButton removeFromSuperview];
                bottomBar.pauseResumeDuringVideoButton = button;
                [bottomBar addSubview:button];
            }
        } else
            bottomBar.pauseResumeDuringVideoButton = nil;
    } else {
        CAMDynamicShutterControl *shutterControl = [self valueForKey:@"_dynamicShutterControl"];
        if (!shouldNotEmbed) {
            CUShutterButton *existingButton = shutterControl.pauseResumeDuringVideoButton;
            if (existingButton != button) {
                [existingButton removeFromSuperview];
                shutterControl.pauseResumeDuringVideoButton = button;
                [shutterControl addSubview:button];
            }
        } else
            shutterControl.pauseResumeDuringVideoButton = nil;
    }
}

%new(v@:@)
- (void)handlePauseResumeDuringVideoButtonPressed:(CUShutterButton *)button {
    CUCaptureController *cuc = [self _captureController];
    if ([cuc respondsToSelector:@selector(isCapturingCTMVideo)] && [cuc isCapturingCTMVideo]) return;
    if (![cuc isCapturingVideo]) return;
    CAMCaptureEngine *engine = [cuc _captureEngine];
    CAMCaptureMovieFileOutput *movieOutput = [engine movieFileOutput];
    if (movieOutput == nil) return;
    BOOL pause = ![movieOutput isRecordingPaused];
    CAMElapsedTimeView *elapsedTimeView = self._elapsedTimeView;
    if (elapsedTimeView == nil)
        elapsedTimeView = [self.view valueForKey:@"_elapsedTimeView"];
    [elapsedTimeView updateUI:pause recording:YES];
    CUShutterButton *shutterButton = self._shutterButton;
    if (shutterButton) {
        UIColor *shutterColor = pause ? UIColor.systemYellowColor : ([shutterButton respondsToSelector:@selector(_innerCircleColorForMode:spinning:)] ? [shutterButton _innerCircleColorForMode:shutterButton.mode spinning:NO] : [shutterButton _colorForMode:shutterButton.mode]);
        shutterButton._innerView.layer.backgroundColor = shutterColor.CGColor;
    }
    CAMDynamicShutterControl *shutterControl = nil;
    @try {
        shutterControl = [self valueForKey:@"_dynamicShutterControl"];
    } @catch (NSException *exception) {}
    if (shutterControl) {
        if (pause)
            shutterControl.overrideShutterButtonColor = YES;
        [shutterControl _updateRendererShapes];
        CAMLiquidShutterRenderer *renderer = [shutterControl valueForKey:@"_liquidShutterRenderer"];
        if ([renderer respondsToSelector:@selector(renderIfNecessary)])
            [renderer renderIfNecessary];
        else if ([shutterControl respondsToSelector:@selector(_updateRendererShapes)])
            [shutterControl _updateRendererShapes];
        shutterControl.overrideShutterButtonColor = NO;
    }
    [self _updatePauseResumeDuringVideoButton:pause];
    if (pause) {
        [elapsedTimeView pauseTimer];
        [movieOutput pauseRecording];
    } else {
        [elapsedTimeView resumeTimer];
        [movieOutput resumeRecording];
    }
}

- (void)updateControlVisibilityAnimated:(BOOL)animated {
    %orig;
    BOOL shouldHide = shouldHidePauseResumeDuringVideoButton(self);
    self._pauseResumeDuringVideoButton.alpha = shouldHide ? 0 : 1;
    if (!shouldHide)
        [self _updatePauseResumeDuringVideoButton:NO];
    [self updateFlashlightButtonVisibility];
}

- (void)_showControlsForGraphConfiguration:(CAMCaptureGraphConfiguration *)graphConfiguration animated:(BOOL)animated {
    %orig;
    BOOL shouldHide = shouldHidePauseResumeDuringVideoButton(self);
    self._pauseResumeDuringVideoButton.alpha = shouldHide ? 0 : 1;
    if (!shouldHide)
        [self _updatePauseResumeDuringVideoButton:NO];
    [self updateFlashlightButtonVisibility];
}

- (void)_showControlsForMode:(NSInteger)mode device:(NSInteger)device animated:(BOOL)animated {
    %orig;
    BOOL shouldHide = shouldHidePauseResumeDuringVideoButton(self);
    self._pauseResumeDuringVideoButton.alpha = shouldHide ? 0 : 1;
    if (!shouldHide)
        [self _updatePauseResumeDuringVideoButton:NO];
    [self updateFlashlightButtonVisibility];
}

- (void)_hideControlsForGraphConfiguration:(CAMCaptureGraphConfiguration *)graphConfiguration animated:(BOOL)animated {
    %orig;
    BOOL shouldHide = shouldHidePauseResumeDuringVideoButton(self);
    self._pauseResumeDuringVideoButton.alpha = shouldHide ? 0 : 1;
    [self updateFlashlightButtonVisibility];
}

- (void)_hideControlsForMode:(NSInteger)mode device:(NSInteger)device animated:(BOOL)animated {
    %orig;
    BOOL shouldHide = shouldHidePauseResumeDuringVideoButton(self);
    self._pauseResumeDuringVideoButton.alpha = shouldHide ? 0 : 1;
    [self updateFlashlightButtonVisibility];
}

%end

// 合并 TapVideoConfig 功能
%hook CAMFramerateIndicatorView

%property (nonatomic, assign) NSInteger resolution;
%property (nonatomic, assign) NSInteger framerate;

- (void)setStyle:(NSInteger)style {
    [self setValue:@(style) forKey:@"_style"];
    [self _updateForAppearanceChange];
}

- (void)_updateAppearance {
    CGFloat fontSize = 0.0;
    NSInteger layoutStyle = self.layoutStyle;

    if (layoutStyle <= 4 && (23 >> layoutStyle)) {
        [self._borderImageView setHidden:0x1D >> layoutStyle];
        fontSize = 14.0;
    }

    NSString *resolutionLabelFormat;
    switch (self.resolution) {
        case 1:
            resolutionLabelFormat = @"FRAMERATE_INDICATOR_720p30";
            break;
        case 2:
            resolutionLabelFormat = @"FRAMERATE_INDICATOR_HD";
            break;
        case 3:
            resolutionLabelFormat = @"FRAMERATE_INDICATOR_4K";
            break;
        default:
            resolutionLabelFormat = @"";
            break;
    }

    NSNumberFormatter *formatter = [%c(CAMControlStatusIndicator) integerFormatter];
    NSString *resolutionLabel = CAMLocalizedFrameworkString(resolutionLabelFormat);
    NSString *framerateLabel = [formatter stringFromNumber:@(toFPS[self.framerate - 1])];
    NSString *label = [NSString stringWithFormat:@"%@ · %@", resolutionLabel, framerateLabel];

    NSDictionary *attributes = @{
        @"CTFeatureTypeIdentifier": @(35),
        @"CTFeatureSelectorIdentifier": @(2)
    };
    UIFont *font = [UIFont cui_cameraFontOfSize:fontSize];
    UIFontDescriptor *fontDescriptor = [font fontDescriptor];
    NSDictionary *fontAttributes = @{
        (id)kCTFontFeatureSettingsAttribute: attributes
    };
    UIFontDescriptor *newFontDescriptor = [fontDescriptor fontDescriptorByAddingAttributes:fontAttributes];
    UIFont *newFont = [UIFont fontWithDescriptor:newFontDescriptor size:fontSize];

    NSDictionary *attributedStringAttributes = @{
        (id)kCTFontAttributeName: newFont,
        (id)kCTKernAttributeName: @([UIFont cui_cameraKerningForFont:newFont])
    };

    NSAttributedString *finalLabel = [[NSAttributedString alloc] initWithString:label attributes:attributedStringAttributes];
    self._label.attributedText = finalLabel;
}

%end

%hook CAMCaptureCapabilities

- (bool)interactiveVideoFormatControlAlwaysEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kVideoConfigEnabled];
}

%end

%hook CAMViewfinderViewController

- (BOOL)_shouldHideFramerateIndicatorForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kVideoConfigEnabled]) return %orig;
    return [self._captureController isCapturingVideo] || [self._topBar shouldHideFramerateIndicatorForGraphConfiguration:configuration] ? %orig : (configuration.mode == 1 || configuration.mode == 2 ? NO : %orig);
}

- (BOOL)_shouldHideFramerateIndicatorForMode:(NSInteger)mode device:(NSInteger)device {
    return [UIApplication shouldMakeUIForDefaultPNG];
}

- (void)_createFramerateIndicatorViewIfNecessary {
    %orig;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kVideoConfigEnabled]) return;
    CAMFramerateIndicatorView *view = [self valueForKey:@"_framerateIndicatorView"];
    if (!view) return;
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeVideoConfigurationMode:)];
    tap.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:tap];
}

- (void)_updateFramerateIndicatorTextForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration {
    CAMFramerateIndicatorView *view = [self valueForKey:@"_framerateIndicatorView"];
    if (view) {
        view.resolution = [self _videoConfigurationResolutionForGraphConfiguration:configuration];
        view.framerate = [self _videoConfigurationFramerateForGraphConfiguration:configuration];
    }
    %orig;
}

- (void)_createVideoConfigurationStatusIndicatorIfNecessary {
    %orig;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kVideoConfigEnabled]) return;
    UIControl *view = [self valueForKey:@"__videoConfigurationStatusIndicator"];
    if (!view) return;
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeVideoConfigurationMode:)];
    tap.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:tap];
}

- (void)videoConfigurationStatusIndicatorDidTapFramerate:(id)arg1 {
    [self changeVideoConfigurationMode:nil];
}

- (void)videoConfigurationStatusIndicatorDidTapResolution:(id)arg1 {
    [self changeVideoConfigurationMode:nil];
}

%new(v@:@)
- (void)changeVideoConfigurationMode:(UITapGestureRecognizer *)gesture {
    NSInteger cameraMode = self._currentGraphConfiguration.mode;
    NSInteger cameraDevice = self._currentGraphConfiguration.device == 0 ? 0 : devices[self._currentGraphConfiguration.device - 1];
    NSString *message = @"选择视频配置:";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CameraBoost" message:message preferredStyle:UIAlertControllerStyleAlert];
    NSMutableDictionary <NSString *, NSNumber *> *modes = [NSMutableDictionary dictionary];
    VideoConfigurationMode currentVideoConfigurationMode = [[NSClassFromString(@"CAMUserPreferences") preferences] videoConfiguration];
    CAMCaptureCapabilities *capabilities = [NSClassFromString(@"CAMCaptureCapabilities") capabilities];
    for (VideoConfigurationMode mode = 0; mode < VideoConfigurationModeCount; ++mode) {
        if (mode != currentVideoConfigurationMode) {
            if ([capabilities isSupportedVideoConfiguration:mode forMode:cameraMode device:cameraDevice])
                modes[title(mode)] = @(mode);
        }
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
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

%end

%ctor {
    openCamera10();
    %init;
}
