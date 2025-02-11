#!/bin/bash

# Add and Set 4K @60hz mode
xrandr --newmode "3840x2160R"  533.00  3840 3888 3920 4000  2160 2163 2168 2222 +hsync -vsync
xrandr --addmode DP-3 "3840x2160R"
xrandr --output DP-3 --mode 3840x2160R

# Add and Set 4K @50hz mode
# xrandr --newmode "3840x2160_50.00"  586.61  3840 4136 4560 5280  2160 2161 2164 2222  -HSync +Vsync
# xrandr --addmode DP-3 3840x2160_50.00
# xrandr --output DP-3 --mode 3840x2160_50.00
