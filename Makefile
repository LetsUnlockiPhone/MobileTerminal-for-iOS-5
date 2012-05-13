CC = arm-apple-darwin9-gcc

CFLAGS = -Wall -Os -std=gnu99 -march=armv6 -mcpu=arm1176jzf-s

ifdef DEBUG
	CFLAGS += -g -DDEBUG
endif

LDFLAGS = -march=armv6 -mcpu=arm1176jzf-s -lobjc -lcurses \
		  -F${PKG_ROOT}/System/Library/PrivateFrameworks \
		  -framework CoreFoundation \
		  -framework Foundation \
		  -framework UIKit \
		  -framework QuartzCore \
		  -framework ImageIO \
		  -framework CoreGraphics \
		  -framework GraphicsServices \
		  -bind_at_load -multiply_defined suppress

SRCS = \
	   Sources/main.m \
	   Sources/MobileTerminal.m \
	   Sources/Misc/Color.m \
	   Sources/Misc/ColorMap.m \
	   Sources/Misc/Constants.m \
	   Sources/Misc/Log.m \
	   Sources/Misc/Settings.m \
	   Sources/Misc/Tools.m \
	   Sources/Preferences/ColorWidgets.m \
	   Sources/Preferences/Preferences.m \
	   Sources/Preferences/PreferencesGroup.m \
	   Sources/Preferences/PreferencesDataSource.m \
	   Sources/Terminal/SubProcess.m \
	   Sources/Terminal/VT100Screen.m \
	   Sources/Terminal/VT100Terminal.m \
	   Sources/UI/GestureView.m \
	   Sources/UI/Keyboard.m \
	   Sources/UI/MainViewController.m \
	   Sources/UI/Menu.m \
	   Sources/UI/PieView.m \
	   Sources/UI/PTYTextView.m

OBJS := $(SRCS:.m=.o)

all:	svnversion Terminal

svnversion:
	python ./Sources/Misc/svnversion.py

Terminal: $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

%.o:	%.m
	$(CC) $(CFLAGS) -I. -ISources/{,Misc,Preferences,Terminal,UI} -c $< -o $@

clean: 
	@rm -f $(OBJS) Terminal

