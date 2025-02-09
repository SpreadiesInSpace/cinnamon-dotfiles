#!/bin/bash

# Add and Set 4K @50hz mode
xrandr --newmode "3840x2160_50.00"  586.61  3840 4136 4560 5280  2160 2161 2164 2222  -HSync +Vsync
xrandr --addmode DP-3 3840x2160_50.00
xrandr --output DP-3 --mode 3840x2160_50.00

# Add and Set 4K @60hz mode
xrandr --newmode "3840x2160_60.00"  712.34  3840 4152 4576 5312  2160 2161 2164 2235  -HSync +Vsync
xrandr --addmode DP-3 3840x2160_60.00
#xrandr --output DP-3 --mode 3840x2160_60.00
