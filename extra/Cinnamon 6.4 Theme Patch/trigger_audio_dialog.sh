#!/bin/bash

gdbus call --session --dest org.Cinnamon.AudioDeviceSelection   --object-path /org/Cinnamon/AudioDeviceSelection   --method org.Cinnamon.AudioDeviceSelection.Open   '[ "HEADPHONES", "MICROPHONE" ]'
