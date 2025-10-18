ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
TARGET = iphone:clang:latest:15.0
else
TARGET = iphone:clang:16.5:15.0
export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/
endif

PACKAGE_VERSION = 1.0.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CameraBoostprefs

CameraBoostprefs_FILES = CameraBoostprefs.m
CameraBoostprefs_FRAMEWORKS = UIKit
CameraBoostprefs_PRIVATE_FRAMEWORKS = Preferences
CameraBoostprefs_INSTALL_PATH = /Library/PreferenceBundles
CameraBoostprefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
