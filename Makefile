# Slashlib legacy iOS application. Build with Theos on Linux.
TARGET := iphone:clang:9.3:6.0
ARCHS := armv7
SDKVERSION := 9.3

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := Slashlib

Slashlib_FILES := $(wildcard Sources/*.m)
Slashlib_FRAMEWORKS := UIKit Foundation CoreFoundation Security ImageIO QuartzCore CoreGraphics
Slashlib_CFLAGS := -fblocks -fno-objc-arc -Wno-deprecated-declarations
Slashlib_INSTALL_PATH := /Applications
Slashlib_RESOURCE_FILES := $(wildcard Resources/Icon*.png)

include $(THEOS_MAKE_PATH)/application.mk
