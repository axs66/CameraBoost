ARCHS = arm64 arm64e
TARGET = iphone:clang:15.0
INSTALL_TARGET_PROCESSES = Camera

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CameraBoost

CameraBoost_FILES = Tweak.x
CameraBoost_CFLAGS = -fobjc-arc
CameraBoost_FRAMEWORKS = UIKit Foundation CoreFoundation
CameraBoost_PRIVATE_FRAMEWORKS = CameraUI CameraKit

include $(THEOS)/makefiles/tweak.mk
