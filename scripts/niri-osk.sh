#!/bin/sh
# wvkbd on-screen keyboard toggle for niri, orientation-aware.
#
#   niri-osk.sh          toggle the keyboard
#   niri-osk.sh resize   if the keyboard is up, restart it with the binary,
#                        height and mode matching the current orientation
#
# Landscape: deskintl (full PC layout), overlays windows.
# Portrait:  mobintl (phone layout), reserves space so windows shrink above it.
# Orientation comes from the output's logical size, so it works for panels
# that are natively portrait too.
#
# Called from the bottom-edge swipe gesture and after rotating the screen.

BIN_LANDSCAPE=wvkbd-deskintl
BIN_PORTRAIT=wvkbd-mobintl
ARGS_LANDSCAPE=--non-exclusive
ARGS_PORTRAIT=
OUTPUT=eDP-1
H_LANDSCAPE=260
H_PORTRAIT=360

# Resolve the running niri instance's IPC socket (newest first).
SOCKET=$(ls -t "/run/user/$(id -u)"/niri.wayland-*.sock 2>/dev/null | head -1)
[ -n "$SOCKET" ] && export NIRI_SOCKET="$SOCKET"

orientation() {
    niri msg -j outputs 2>/dev/null | python3 -c \
        "import json,sys; l=json.load(sys.stdin)['$OUTPUT']['logical']; print('portrait' if l['height'] > l['width'] else 'landscape')" 2>/dev/null
}

running() {
    pgrep -x "$BIN_LANDSCAPE" >/dev/null || pgrep -x "$BIN_PORTRAIT" >/dev/null
}

stop() {
    pkill -x "$BIN_LANDSCAPE"
    pkill -x "$BIN_PORTRAIT"
}

# wvkbd picks -H or -L by its own width/height check, so pass both.
start() {
    if [ "$(orientation)" = portrait ]; then
        "$BIN_PORTRAIT" -H "$H_PORTRAIT" -L "$H_PORTRAIT" $ARGS_PORTRAIT >/dev/null 2>&1 &
    else
        "$BIN_LANDSCAPE" -H "$H_LANDSCAPE" -L "$H_LANDSCAPE" $ARGS_LANDSCAPE >/dev/null 2>&1 &
    fi
}

case "${1:-toggle}" in
    toggle)
        if running; then stop; else start; fi
        ;;
    resize)
        if running; then
            stop
            sleep 0.3
            start
        fi
        ;;
esac
