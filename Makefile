TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlitchPulse
GlitchPulse_FILES = Tweak.x
GlitchPulse_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
GlitchPulse_FRAMEWORKS = UIKit QuartzCore
GlitchPulse_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
