#!/bin/sh
# Prints the index Godot gives the MacBook's built-in screen, for `--screen` (window runs must open there, not on the
# external monitor). Godot numbers the main display 0: when the MacBook is the main display it is 0, otherwise 1.
if system_profiler SPDisplaysDataType 2>/dev/null | awk '/Built-in/{b=1} b&&/Main Display: Yes/{f=1} /^        [^ ].*:$/{b=0} END{exit !f}'; then
	echo 0
else
	n=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -c "Resolution:")
	if [ "$n" -gt 1 ]; then echo 1; else echo 0; fi
fi
