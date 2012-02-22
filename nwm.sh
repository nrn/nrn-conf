#!/bin/sh
xset b off
xmodmap ./xmodmap
exec /usr/local/bin/coffee /home/nick/github/nwm-user/nwm-user.coffee 2>/home/nick/github/nwm-user/nwm.err.log 1>/home/nick/github/nwm-user/nwm.log
