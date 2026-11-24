# Slashlib iOS 6 — Theos application build (Linux/macOS)
# Build against the iOS 9.3 SDK while keeping iOS 6.0 as the deployment target.
# The 9.3 SDK is the newest SDK supported by the traditional Linux Theos toolchain
# and still contains the ARMv7 headers/libraries needed by this legacy target.

TARGET := iphone:clang:9.3:6.0
ARCHS := armv7
SDKVERSION := 9.3

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := Slashlib

Slashlib_FILES := $(wildcard Sources/*.m)
Slashlib_FRAMEWORKS := UIKit Foundation Security ImageIO QuartzCore CoreGraphics
Slashlib_CFLAGS := -fblocks -fno-objc-arc -Wno-deprecated-declarations
Slashlib_INSTALL_PATH := /Applications
Slashlib_RESOURCE_FILES := $(wildcard Resources/Icon*.png) Resources/Info.plist

# The root control file is read by Theos for both IPA and Debian packaging.
# Run `make package PACKAGE_FORMAT=ipa` and then `make package PACKAGE_FORMAT=deb`.
PACKAGE_FORMAT ?= ipa

include $(THEOS_MAKE_PATH)/application.mk
