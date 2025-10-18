# 支持通过环境变量切换包类型，默认 rootless
THEOS_PACKAGE_SCHEME ?= rootless

ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CameraBoost

CameraBoost_FILES = Tweak.x
CameraBoost_CFLAGS = -fobjc-arc -I$(THEOS)/include/PSHeader
CameraBoost_FRAMEWORKS = UIKit Foundation CoreFoundation
CameraBoost_PRIVATE_FRAMEWORKS = CameraUI CameraKit

include $(THEOS)/makefiles/tweak.mk

