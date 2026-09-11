#!/bin/sh

BASE_DIR="/tmp/mnt/sda1/home/lblogd"
LNSD_BIN="$BASE_DIR/lnsd"
LBLOGD_BIN="$BASE_DIR/lblogd"
LBLOGD_TOML="$BASE_DIR/lblogd.toml"
LNSD_LOG="$BASE_DIR/lnsd.log"
LBLOGD_LOG="$BASE_DIR/lblogd.log"
CACHE_DIR="/tmp/lblogd_cache"
IDENTITIES_DIR="$BASE_DIR/identities"

export HOME="$BASE_DIR"

start() {
    echo "Starting lnsd network transport..."
    if ps | grep -v grep | grep -q "$LNSD_BIN"; then
        echo "[-] lnsd is already running."
    else
        "$LNSD_BIN" > "$LNSD_LOG" 2>&1 &
        echo "[+] lnsd successfully started in the background."
        # Classic race condition fix: Give lnsd a moment to initialize and open its IPC socket
        echo "Waiting for lnsd to initialize and create IPC socket..."
        sleep 3
    fi

    echo "Preparing cache in RAM..."
    mkdir -p "$CACHE_DIR"
    rm -rf "$CACHE_DIR/identities"
    ln -sf "$IDENTITIES_DIR" "$CACHE_DIR/identities"

    echo "Starting lblogd blog server..."
    if ps | grep -v grep | grep -q "$LBLOGD_BIN"; then
        echo "[-] lblogd is already running."
    else
        "$LBLOGD_BIN" --config "$LBLOGD_TOML" > "$LBLOGD_LOG" 2>&1 &
        echo "[+] lblogd successfully started in the background."
    fi
}

stop() {
    echo "Stopping lblogd and lnsd services..."
    killall -9 lblogd lnsd 2>/dev/null
    echo "[-] Services stopped."
}

status() {
    echo "=== Process Status ==="
    if ps | grep -v grep | grep -q "$LNSD_BIN"; then
        echo "lnsd:  [RUNNING]"
    else
        echo "lnsd:  [STOPPED]"
    fi

    if ps | grep -v grep | grep -q "$LBLOGD_BIN"; then
        echo "lblogd: [RUNNING]"
    else
        echo "lblogd: [STOPPED]"
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 2
        start
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
