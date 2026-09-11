#!/bin/sh

BASE_DIR="/tmp/mnt/sda1/home/lblogd"
LNSD_BIN="$BASE_DIR/lnsd"
LBLOGD_BIN="$BASE_DIR/lblogd"
LBLOGD_TOML="$BASE_DIR/lblogd.toml"
LNSD_LOG="$BASE_DIR/lnsd.log"
LBLOGD_LOG="$BASE_DIR/lblogd.log"
CACHE_DIR="/tmp/lblogd_cache"
IDENTITIES_DIR="$BASE_DIR/identities"

start() {
    echo "Starting lnsd network transport..."
    if ps | grep -v grep | grep -q "$LNSD_BIN"; then
        echo "[-] lnsd is already running."
    else
        "$LNSD_BIN" > "$LNSD_LOG" 2>&1 &
        echo "[+] lnsd successfully started in the background."
        echo "Waiting for lnsd to initialize and open IPC port 37428..."
        i=1
        while [ $i -le 15 ]; do
            if netstat -an | grep -q "37428"; then
                echo "[+] lnsd is now listening on port 37428."
                break
            fi
            sleep 1
            i=$((i+1))
        done
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
    echo "Stopping lblogd blog server..."
    if ps | grep -v grep | grep -q "$LBLOGD_BIN"; then
        killall -9 lblogd >/dev/null 2>&1
        echo "[+] lblogd successfully stopped."
    else
        echo "[-] lblogd is not running."
    fi

    echo "Stopping lnsd network transport..."
    if ps | grep -v grep | grep -q "$LNSD_BIN"; then
        killall -9 lnsd >/dev/null 2>&1
        echo "[+] lnsd successfully stopped."
    else
        echo "[-] lnsd is not running."
    fi
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
