#!/bin/sh
set -eu
Xvfb :99 -screen 0 1024x768x24 -nolisten tcp &
sleep 1
openbox >/tmp/openbox.log 2>&1 &
x11vnc -display :99 -localhost -forever -shared -nopw -rfbport 5900 >/tmp/vnc.log 2>&1 &
websockify --web /usr/share/novnc 6080 localhost:5900 >/tmp/websockify.log 2>&1 &
# Wine initializes only this container's disposable home directory.
wineboot -u >/tmp/wineboot.log 2>&1
echo 'READY: isolated reference desktop'
wait
