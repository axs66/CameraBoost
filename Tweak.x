#import "Header.h"
#import <CoreText/CoreText.h>

// Global variables for configuration
int subSecondPrecision = 0; // 0=default, 1=1 decimal, 2=2 decimals, 3=3 decimals
BOOL isFlashIndicator = NO;
BOOL torchEnabled = NO;

// Device compatibility arrays
NSInteger devices[] = { 1, 0, 0, 0, 1, 1 };
NSInteger toFPS[] = { 24, 30, 60, 120, 240 };

// Forward declarations
static BOOL shouldHidePauseResumeDuringVideoButton(CAMViewfinderViewController *self);
static void layoutPauseResumeDuringVideoButton(UIView *view, CUShutterButton *button, UIView *shutterButton, CGFloat displayScale, BOOL fixedPosition);

// Utility functions
BOOL checkModeAndDevice(NSInteger mode, NSInteger device) {
    return (mode == CAMERA_MODE_VIDEO || mode == CAMERA_MODE_SLOMO) && device == CAMERA_DEVICE_BACK;
}

BOOL isBackCamera(NSInteger device) {
    return device == CAMERA_DEVICE_BACK;
}

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
        default: return @"Unknown";
    }
}

// ============================================================================
// CAMElapsedTimeView - Sub-second timer functionality
// ============================================================================
%hook CAMElapsedTimeView

- (void)_updateText {
    NSDate *startDate = [self valueForKey:@"__startTime"];
    NSDate *currentDate = [NSDate date];
    NSTimeInterval interval = [currentDate timeIntervalSinceDate:startDate];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:interval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSString *format;
    
    if (subSecondPrecision > 0) {
        switch (subSecondPrecision) {
            case 1: format = @"HH:mm:ss.S"; break;
            case 2: format = @"HH:mm:ss.SS"; break;
            case 3: format = @"HH:mm:ss.SSS"; break;
            default: format = @"HH:mm:ss"; break;
        }
    } else {
        format = @"HH:mm:ss";
    }
    
    dateFormatter.dateFormat = format;
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0.0];
    NSString *timeString = [dateFormatter stringFromDate:timerDate];
    [self _timeLabel].text = timeString;
}

- (void)startTimer {
    NSTimer *updateTimer = [self valueForKey:@"__updateTimer"];
    [updateTimer invalidate];
    NSDate *startTime = [[NSDate alloc] init];
    [self setValue:startTime forKey:@"__startTime"];
    
    NSTimeInterval interval = subSecondPrecision > 0 ? (NSTimeInterval)pow(10, -subSecondPrecision) : 1.0;
    NSTimer *newUpdateTimer = [[NSTimer alloc] initWithFireDate:startTime 
                                                       interval:interval 
                                                         target:self 
                                                       selector:@selector(_updateForTimer:) 
                                                       userInfo:nil 
                                                        repeats:YES];
    [self setValue:newUpdateTimer forKey:@"__updateTimer"];
    [[NSRunLoop currentRunLoop] addTimer:newUpdateTimer forMode:(NSRunLoopMode)kCFRunLoopDefaultMode];
    [[NSRunLoop currentRunLoop] addTimer:newUpdateTimer forMode:UITrackingRunLoopMode];
}

// Timer pause/resume functionality
%new(v@:)
- (void)pauseTimer {
    NSTimer *timer = [self valueForKey:@"__updateTimer"];
    if (timer == nil) return;
    objc_setAssociatedObject(timer, NSTimerPauseDate, [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(timer, NSTimerPreviousFireDate, timer.fireDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    timer.fireDate = [NSDate distantFuture];
}

%new(v@:)
- (void)resumeTimer {
    NSTimer *timer = [self valueForKey:@"__updateTimer"];
    NSDate *pauseDate = objc_getAssociatedObject(timer, NSTimerPauseDate);
    NSDate *previousFireDate = objc_getAssociatedObject(timer, NSTimerPreviousFireDate);
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
        if ([self respondsToSelector:@selector(_recordingImageView)] && self._recordingImageView) {
            CGSize size = CGSizeMake(1, 1);
            UIGraphicsBeginImageContextWithOptions(size, NO, 0);
            [recordingImageColor setFill];
            UIRectFill(CGRectMake(0, 0, size.width, size.height));
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            self._recordingImageView.image = image;
        }
        if (backgroundView) {
            CGSize size = CGSizeMake(1, 1);
            UIGraphicsBeginImageContextWithOptions(size, NO, 0);
            [recordingImageColor setFill];
            UIRectFill(CGRectMake(0, 0, size.width, size.height));
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            backgroundView.image = image;
        }
    }
}

- (void)endTimer {
    NSTimer *timer = [self valueForKey:@"__updateTimer"];
    if (timer == nil) return;
    objc_setAssociatedObject(timer, NSTimerPauseDate, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(timer, NSTimerPreviousFireDate, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if ([self respondsToSelector:@selector(updateUI:recording:)]) {
        [self performSelector:@selector(updateUI:recording:) withObject:@(NO) withObject:@(NO)];
    }
    %orig;
}

%end

// ============================================================================
// CAMViewfinderViewController - Main camera controller
// ============================================================================
%hook CAMViewfinderViewController

%property (nonatomic, retain) CUShutterButton *_pauseResumeDuringVideoButton;

// Flash/Torch control during recording
- (void)_startCapturingVideoWithRequest:(id)arg1 {
    %orig;
    if (checkModeAndDevice(self._currentMode, self._currentDevice))
        self._flashButton.allowsAutomaticFlash = NO;
}

- (BOOL)_shouldShowIndicatorOfType:(NSUInteger)type forGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration {
    return type == 0 && checkModeAndDevice(configuration.mode, configuration.device) && ([self._captureController isCapturingVideo] || [self._captureController isCapturingTimelapse]) ? YES : %orig;
}

- (BOOL)_shouldHideFlashButtonForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration {
    return checkModeAndDevice(configuration.mode, configuration.device) && [self._captureController isCapturingVideo] ? NO : %orig;
}

- (void)_updateTopBarStyleForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration capturing:(BOOL)capturing animated:(BOOL)animated {
    %orig(configuration, isBackCamera(configuration.device) ? NO : capturing, animated);
}

- (void)_handleFlashIndicator {
    isFlashIndicator = YES;
    %orig;
    isFlashIndicator = NO;
}

- (void)_handleUserChangedToFlashMode:(NSInteger)flashMode {
    %orig(flashMode == 2 && isFlashIndicator ? 1 : flashMode);
}

- (void)_updateTorchModeOnControllerForMode:(NSInteger)mode {
    isFlashIndicator = YES;
    %orig;
    isFlashIndicator = NO;
}

// Video configuration control
- (BOOL)_shouldHideFramerateIndicatorForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration {
    return [self._captureController isCapturingVideo] || [self._topBar shouldHideFramerateIndicatorForGraphConfiguration:configuration] ? %orig : (configuration.mode == 1 || configuration.mode == 2 ? NO : %orig);
}

- (BOOL)_shouldHideFramerateIndicatorForMode:(NSInteger)mode device:(NSInteger)device {
    return NO;
}

- (void)_createFramerateIndicatorViewIfNecessary {
    %orig;
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
        [view setValue:@([self _videoConfigurationResolutionForGraphConfiguration:configuration]) forKey:@"resolution"];
        [view setValue:@([self _videoConfigurationFramerateForGraphConfiguration:configuration]) forKey:@"framerate"];
    }
    %orig;
}

- (void)_createVideoConfigurationStatusIndicatorIfNecessary {
    %orig;
    UIControl *view = [self valueForKey:@"__videoConfigurationStatusIndicator"];
    if (!view) return;
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeVideoConfigurationMode:)];
    tap.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:tap];
}

- (void)videoConfigurationStatusIndicatorDidTapFramerate:(id)arg1 {
    if ([self respondsToSelector:@selector(changeVideoConfigurationMode:)]) {
        [self performSelector:@selector(changeVideoConfigurationMode:) withObject:nil];
    }
}

- (void)videoConfigurationStatusIndicatorDidTapResolution:(id)arg1 {
    if ([self respondsToSelector:@selector(changeVideoConfigurationMode:)]) {
        [self performSelector:@selector(changeVideoConfigurationMode:) withObject:nil];
    }
}

%new(v@:@)
- (void)changeVideoConfigurationMode:(UITapGestureRecognizer *)gesture {
    NSInteger cameraMode = self._currentGraphConfiguration.mode;
    NSInteger cameraDevice = self._currentGraphConfiguration.device == 0 ? 0 : devices[self._currentGraphConfiguration.device - 1];
    NSString *message = @"Select video configuration:";
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
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

// Pause/Resume video recording functionality
- (void)_createVideoControlsIfNecessary {
    %orig;
    if ([self respondsToSelector:@selector(_createPauseResumeDuringVideoButtonIfNecessary)]) {
        [self performSelector:@selector(_createPauseResumeDuringVideoButtonIfNecessary)];
    }
}

%new(v@:)
- (void)_createPauseResumeDuringVideoButtonIfNecessary {
    if ([self valueForKey:@"_pauseResumeDuringVideoButton"]) return;
    NSInteger layoutStyle = [self respondsToSelector:@selector(_layoutStyle)] ? self._layoutStyle : 1;
    Class CUShutterButtonClass = %c(CUShutterButton);
    CUShutterButton *button = [CUShutterButtonClass respondsToSelector:@selector(smallShutterButtonWithLayoutStyle:)]
        ? [CUShutterButtonClass smallShutterButtonWithLayoutStyle:layoutStyle]
        : [CUShutterButtonClass smallShutterButton];
    UIView *innerView = button._innerView;
    UIImage *pauseImage;
    if (@available(iOS 13.0, *)) {
        pauseImage = [UIImage systemImageNamed:@"pause.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:24]];
    } else {
        NSBundle *bundle = [NSBundle bundleWithPath:@"/Library/Application Support/CameraBoost.bundle"];
        pauseImage = [UIImage imageNamed:@"pause.fill" inBundle:bundle compatibleWithTraitCollection:nil];
    }
    UIImageView *pauseIcon = [[UIImageView alloc] initWithImage:pauseImage];
    pauseIcon.tintColor = UIColor.whiteColor;
    pauseIcon.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    pauseIcon.contentMode = UIViewContentModeCenter;
    pauseIcon.frame = innerView.bounds;
    pauseIcon.tag = 2024;
    [button addSubview:pauseIcon];
    innerView.hidden = YES;
    [self setValue:button forKey:@"_pauseResumeDuringVideoButton"];
    [button addTarget:self action:@selector(handlePauseResumeDuringVideoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    button.mode = 1;
    button.exclusiveTouch = YES;
    if ([self respondsToSelector:@selector(_embedPauseResumeDuringVideoButtonWithLayoutStyle:)]) {
        [self performSelector:@selector(_embedPauseResumeDuringVideoButtonWithLayoutStyle:) withObject:@(layoutStyle)];
    }
}

%new(v@:l)
- (void)_embedPauseResumeDuringVideoButtonWithLayoutStyle:(NSInteger)layoutStyle {
    CUShutterButton *button = [self valueForKey:@"_pauseResumeDuringVideoButton"];
    BOOL shouldNotEmbed = layoutStyle == 2 ? YES : ([self respondsToSelector:@selector(isEmulatingImagePicker)] ? [self isEmulatingImagePicker] : NO);
    if ([self respondsToSelector:@selector(_shouldCreateAndEmbedControls)] ? [self _shouldCreateAndEmbedControls] : YES) {
        CAMBottomBar *bottomBar = self.viewfinderView.bottomBar;
        if (!shouldNotEmbed) {
            CUShutterButton *existingButton = [bottomBar valueForKey:@"pauseResumeDuringVideoButton"];
            if (existingButton != button) {
                [existingButton removeFromSuperview];
                [bottomBar setValue:button forKey:@"pauseResumeDuringVideoButton"];
                [bottomBar addSubview:button];
            }
        } else
            [bottomBar setValue:nil forKey:@"pauseResumeDuringVideoButton"];
    } else {
        CAMDynamicShutterControl *shutterControl = [self valueForKey:@"_dynamicShutterControl"];
        if (!shouldNotEmbed) {
            CUShutterButton *existingButton = [shutterControl valueForKey:@"pauseResumeDuringVideoButton"];
            if (existingButton != button) {
                [existingButton removeFromSuperview];
                [shutterControl setValue:button forKey:@"pauseResumeDuringVideoButton"];
                [shutterControl addSubview:button];
            }
        } else
            [shutterControl setValue:nil forKey:@"pauseResumeDuringVideoButton"];
    }
}

%new(v@:B)
- (void)_updatePauseResumeDuringVideoButton:(BOOL)paused {
    CUShutterButton *button = [self valueForKey:@"_pauseResumeDuringVideoButton"];
    UIView *innerView = button._innerView;
    UIImageView *pauseIcon = [button viewWithTag:2024];
    innerView.hidden = !paused;
    pauseIcon.hidden = paused;
}

%new(v@:@)
- (void)handlePauseResumeDuringVideoButtonPressed:(CUShutterButton *)button {
    CUCaptureController *cuc = [self _captureController];
    if ([cuc respondsToSelector:@selector(isCapturingCTMVideo)] && [cuc isCapturingCTMVideo]) return;
    if (![cuc isCapturingVideo]) return;
    CAMCaptureEngine *engine = [cuc _captureEngine];
    CAMCaptureMovieFileOutput *movieOutput = [engine movieFileOutput];
    if (movieOutput == nil) return;
    // For iOS 14.5-16.6.1, we'll use a custom pause state tracking
    BOOL pause = NO;
    // Check if we have a custom pause state stored
    NSNumber *pauseState = [movieOutput valueForKey:@"_isPaused"];
    if (pauseState) {
        pause = [pauseState boolValue];
    }
    CAMElapsedTimeView *elapsedTimeView = self._elapsedTimeView;
    if (elapsedTimeView == nil)
        elapsedTimeView = [self.view valueForKey:@"_elapsedTimeView"];
    if ([elapsedTimeView respondsToSelector:@selector(updateUI:recording:)]) {
        [elapsedTimeView performSelector:@selector(updateUI:recording:) withObject:@(pause) withObject:@(YES)];
    }
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
            [shutterControl setValue:@(YES) forKey:@"overrideShutterButtonColor"];
        [shutterControl _updateRendererShapes];
        id renderer = [shutterControl valueForKey:@"_liquidShutterRenderer"];
        // Skip renderIfNecessary call as it's not available in iOS 14.5-16.6.1
        else if ([shutterControl respondsToSelector:@selector(_updateRendererShapes)])
            [shutterControl _updateRendererShapes];
        [shutterControl setValue:@(NO) forKey:@"overrideShutterButtonColor"];
    }
    if ([self respondsToSelector:@selector(_updatePauseResumeDuringVideoButton:)]) {
        [self performSelector:@selector(_updatePauseResumeDuringVideoButton:) withObject:@(pause)];
    }
    if (pause) {
        if ([elapsedTimeView respondsToSelector:@selector(pauseTimer)]) {
            [elapsedTimeView performSelector:@selector(pauseTimer)];
        }
        // For iOS 14.5-16.6.1, we'll use a different approach
        // Since pauseRecording is not available, we'll just update the UI state
        // The actual recording will continue, but we'll track the pause state for UI purposes
        [movieOutput setValue:@(YES) forKey:@"_isPaused"];
    } else {
        if ([elapsedTimeView respondsToSelector:@selector(resumeTimer)]) {
            [elapsedTimeView performSelector:@selector(resumeTimer)];
        }
        // Clear the pause state
        [movieOutput setValue:@(NO) forKey:@"_isPaused"];
    }
}


// Control visibility updates
- (void)updateControlVisibilityAnimated:(BOOL)animated {
    %orig;
    BOOL shouldHide = shouldHidePauseResumeDuringVideoButton(self);
    [[self valueForKey:@"_pauseResumeDuringVideoButton"] setAlpha:shouldHide ? 0 : 1];
    if (!shouldHide)
        if ([self respondsToSelector:@selector(_updatePauseResumeDuringVideoButton:)]) {
            [self performSelector:@selector(_updatePauseResumeDuringVideoButton:) withObject:@(NO)];
        }
}

- (void)_showControlsForGraphConfiguration:(CAMCaptureGraphConfiguration *)graphConfiguration animated:(BOOL)animated {
    %orig;
    BOOL shouldHide = shouldHidePauseResumeDuringVideoButton(self);
    [[self valueForKey:@"_pauseResumeDuringVideoButton"] setAlpha:shouldHide ? 0 : 1];
    if (!shouldHide)
        if ([self respondsToSelector:@selector(_updatePauseResumeDuringVideoButton:)]) {
            [self performSelector:@selector(_updatePauseResumeDuringVideoButton:) withObject:@(NO)];
        }
}

- (void)_showControlsForMode:(NSInteger)mode device:(NSInteger)device animated:(BOOL)animated {
    %orig;
    BOOL shouldHide = shouldHidePauseResumeDuringVideoButton(self);
    [[self valueForKey:@"_pauseResumeDuringVideoButton"] setAlpha:shouldHide ? 0 : 1];
    if (!shouldHide)
        if ([self respondsToSelector:@selector(_updatePauseResumeDuringVideoButton:)]) {
            [self performSelector:@selector(_updatePauseResumeDuringVideoButton:) withObject:@(NO)];
        }
}

- (void)_hideControlsForGraphConfiguration:(CAMCaptureGraphConfiguration *)graphConfiguration animated:(BOOL)animated {
    %orig;
    BOOL shouldHide = shouldHidePauseResumeDuringVideoButton(self);
    [[self valueForKey:@"_pauseResumeDuringVideoButton"] setAlpha:shouldHide ? 0 : 1];
}

- (void)_hideControlsForMode:(NSInteger)mode device:(NSInteger)device animated:(BOOL)animated {
    %orig;
    BOOL shouldHide = shouldHidePauseResumeDuringVideoButton(self);
    [[self valueForKey:@"_pauseResumeDuringVideoButton"] setAlpha:shouldHide ? 0 : 1];
}

%end

// ============================================================================
// CAMBottomBar - Bottom bar controls
// ============================================================================
#define BUTTON_SIZE 47.0
%hook CAMBottomBar

%property (nonatomic, retain) CUShutterButton *pauseResumeDuringVideoButton;

%new(v@:l)
- (void)_layoutPauseResumeDuringVideoButtonForLayoutStyle:(NSInteger)layoutStyle {
    if (![[self class] wantsVerticalBarForLayoutStyle:layoutStyle])
        layoutPauseResumeDuringVideoButton(self, [self valueForKey:@"pauseResumeDuringVideoButton"], self.shutterButton, self.traitCollection.displayScale, NO);
    else {
        CGRect frame = self.frame;
        CGFloat maxY = CGRectGetMaxY(frame) - (2 * (BUTTON_SIZE + 16.0));
        CGFloat midX = CGRectGetWidth(frame) / 2 - (BUTTON_SIZE / 2);
        [[self valueForKey:@"pauseResumeDuringVideoButton"] setFrame:CGRectMake(midX, maxY, BUTTON_SIZE, BUTTON_SIZE)];
    }
}

%new(v@:@)
- (void)_layoutPauseResumeDuringVideoButtonForTraitCollection:(UITraitCollection *)traitCollection {
    if (![[self class] wantsVerticalBarForTraitCollection:traitCollection])
        layoutPauseResumeDuringVideoButton(self, [self valueForKey:@"pauseResumeDuringVideoButton"], self.shutterButton, traitCollection.displayScale, NO);
    else {
        CGRect frame = self.frame;
        CGFloat maxY = CGRectGetMaxY(frame) - (2 * (BUTTON_SIZE + 16.0));
        CGFloat midX = CGRectGetWidth(frame) / 2 - (BUTTON_SIZE / 2);
        [[self valueForKey:@"pauseResumeDuringVideoButton"] setFrame:CGRectMake(midX, maxY, BUTTON_SIZE, BUTTON_SIZE)];
    }
}

- (void)layoutSubviews {
    %orig;
    if ([self respondsToSelector:@selector(layoutStyle)])
        if ([self respondsToSelector:@selector(_layoutPauseResumeDuringVideoButtonForLayoutStyle:)]) {
            [self performSelector:@selector(_layoutPauseResumeDuringVideoButtonForLayoutStyle:) withObject:@([self layoutStyle])];
        }
    else
        if ([self respondsToSelector:@selector(_layoutPauseResumeDuringVideoButtonForTraitCollection:)]) {
            [self performSelector:@selector(_layoutPauseResumeDuringVideoButtonForTraitCollection:) withObject:self.traitCollection];
        }
}

%end

// ============================================================================
// CAMDynamicShutterControl - Dynamic shutter controls
// ============================================================================
%hook CAMDynamicShutterControl

%property (nonatomic, retain) CUShutterButton *pauseResumeDuringVideoButton;
%property (nonatomic, assign) BOOL overrideShutterButtonColor;

- (CAMShutterColor)_innerShapeColor {
    CAMShutterColor color = %orig;
    if ([[self valueForKey:@"overrideShutterButtonColor"] boolValue]) {
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
    layoutPauseResumeDuringVideoButton(self, [self valueForKey:@"pauseResumeDuringVideoButton"], [self _centerOuterView], self.traitCollection.displayScale, YES);
}

%end

// ============================================================================
// CAMFramerateIndicatorView - Framerate indicator
// ============================================================================
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
    switch ([[self valueForKey:@"resolution"] integerValue]) {
        case 1: resolutionLabelFormat = @"FRAMERATE_INDICATOR_720p30"; break;
        case 2: resolutionLabelFormat = @"FRAMERATE_INDICATOR_HD"; break;
        case 3: resolutionLabelFormat = @"FRAMERATE_INDICATOR_4K"; break;
        default: resolutionLabelFormat = @""; break;
    }

    NSNumberFormatter *formatter = [%c(CAMControlStatusIndicator) integerFormatter];
    NSString *resolutionLabel = resolutionLabelFormat;
    NSString *framerateLabel = [formatter stringFromNumber:@(toFPS[[[self valueForKey:@"framerate"] integerValue] - 1])];
    NSString *label = [NSString stringWithFormat:@"%@ · %@", resolutionLabel, framerateLabel];

    NSDictionary *attributes = @{
        @"CTFeatureTypeIdentifier": @(35),
        @"CTFeatureSelectorIdentifier": @(2)
    };
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    UIFontDescriptor *fontDescriptor = [font fontDescriptor];
    NSDictionary *fontAttributes = @{
        (id)kCTFontFeatureSettingsAttribute: attributes
    };
    UIFontDescriptor *newFontDescriptor = [fontDescriptor fontDescriptorByAddingAttributes:fontAttributes];
    UIFont *newFont = [UIFont fontWithDescriptor:newFontDescriptor size:fontSize];

    NSDictionary *attributedStringAttributes = @{
        (id)kCTFontAttributeName: newFont,
        (id)kCTKernAttributeName: @(0.0)
    };

    NSAttributedString *finalLabel = [[NSAttributedString alloc] initWithString:label attributes:attributedStringAttributes];
    self._label.attributedText = finalLabel;
}

%end

// ============================================================================
// CAMCaptureCapabilities - Video format control
// ============================================================================
%hook CAMCaptureCapabilities

- (bool)interactiveVideoFormatControlAlwaysEnabled {
    return true;
}

%end

// ============================================================================
// CUCaptureController - Capture controller
// ============================================================================
%hook CUCaptureController

- (BOOL)isCapturingVideo {
    return isFlashIndicator ? NO : %orig;
}

%end

// ============================================================================
// Utility functions
// ============================================================================
static void layoutPauseResumeDuringVideoButton(UIView *view, CUShutterButton *button, UIView *shutterButton, CGFloat displayScale, BOOL fixedPosition) {
    CGSize size = [button intrinsicContentSize];
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGRect alignmentRect = [shutterButton alignmentRectForFrame:shutterButton.frame];
    CGFloat midY = CGRectGetMidY(alignmentRect);
    CGFloat y = midY - (size.height / 2);
    CGFloat x;
    CGRect bounds = view.bounds;
    if (fixedPosition)
        x = CGRectGetMinX(bounds) + 15;
    else
        x = CGRectGetMaxX(bounds) - size.width - 15;
    button.tappableEdgeInsets = UIEdgeInsetsMake(20, 20, 20, 20);
    button.frame = [button frameForAlignmentRect:CGRectMake(x, y, rect.size.width, rect.size.height)];
}

static BOOL shouldHidePauseResumeDuringVideoButton(CAMViewfinderViewController *self) {
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

// ============================================================================
// Constructor
// ============================================================================
%ctor {
    // Load user preferences
    subSecondPrecision = [[NSUserDefaults standardUserDefaults] integerForKey:@"CameraBoost_SubSecondPrecision"];
    if (subSecondPrecision <= 0) subSecondPrecision = 0;
    
    // Initialize camera
    openCamera10();
    %init;
}
