# Leviculum Embedded Node

This repository provides configuration examples, deployment scripts, and optimization guidelines for running a lightweight, zero-dependency, statically-linked Reticulum transport (`lnsd`) and NomadNet/Micron blog server (`lblogd`) on resource-constrained embedded devices (tested on **ASUS RT-AC57U V3**, MIPS Big-Endian architecture, running on ASUSWRT embedded Linux without a hardware FPU).

---

## Origin & Credits

This project is an architectural adaptation and deployment wrapper built upon **Leviculum**—a brilliant independent, protocol-first Rust implementation of the Reticulum Network Stack.

- **Original Project:** [Leviculum](https://codeberg.org/Lew_Palm/leviculum)
- **Original Commit Hash:** `808908b12b802e76e08b4a9067137061087a0d05` (Date: Sept 10, 2026)
- **Original Author:** Lew Palm
- **Original License:** AGPL-3.0-or-later

### Adaptation Details
This specific adaptation for resource-constrained embedded systems and MIPS soft-float architectures was developed by:
- **Adapter:** Ivan Svarkovsky ([ivansvarkovsky@gmail.com](mailto:ivansvarkovsky@gmail.com), [GitHub Profile](https://github.com/Svarkovsky))

---

## Why This Exists

The official Python-based Reticulum implementations are too resource-heavy for low-end routers, thin clients, and embedded devices with 64MB or 128MB of RAM. 

By utilizing the Rust-based **Leviculum** stack compiled with `soft-float` and static linking, we can run a fully-featured Reticulum Node and NomadNet server on embedded hardware with a minimal memory footprint and zero external dependencies.

---

## The Magic of Static Linking & Soft-Float (OS-Independent Portability)

By combining **fully static linking** with `musl-libc` and the Rust **`+soft-float`** compiler feature, we have created what is essentially a **"Portable Executable / AppImage" for embedded Linux**. 

Here is why this approach is a massive game-changer for router and IoT deployments:

### 1. 100% Decoupled from the Operating System & Firmware
Traditional binaries compiled dynamically for embedded Linux are locked to a specific OS environment. If you compile a binary under OpenWrt, it will crash on ASUSWRT with a `not found` error because it cannot find the dynamic linker (`/lib/ld-uClibc.so.0`).
Our statically-linked binaries **completely bypass the router's file system**:
- **Firmware Agnostic:** It runs flawlessly on **ASUSWRT, OpenWrt, DD-WRT, KeeneticOS (NDMS), Padavan, Tomato**, or even stock proprietary TP-Link/D-Link firmware.
- **C-Library Independent:** The binary doesn't care if the router uses `uClibc`, `glibc`, or `musl`. It carries its own optimized, statically-linked `musl-libc` micro-code inside, communicating directly with the Linux kernel via system calls (`syscall`).

### 2. Run Anywhere, No Hardware FPU Needed
Many low-cost MIPS processors (like the ones found in entry-level and mid-range routers) do not have a hardware Floating Point Unit (FPU). Running standard binaries on them triggers slow kernel-level FPU emulation or causes immediate crashes.
- By compiling with the **`+soft-float`** target feature, all floating-point calculations are handled purely in software within the binary itself.
- This ensures the binary runs flawlessly on both "stripped-down" CPUs without an FPU and advanced processors with an FPU (where it simply continues to run software-calculated math safely).

### 3. Bulletproof Kernel Backward Compatibility
Our binaries are compiled targeting an older, highly compatible kernel environment (Linux 3.3.8). In the Linux world, **syscall backward compatibility is absolute**:
- A binary compiled for an older kernel (e.g., `3.x`) will run flawlessly on modern kernels (e.g., `5.15`, `6.1`, `6.6`).
- However, if you compiled targeting a modern kernel, the binary would crash on older routers with `Bad system call` because of modern syscalls like `statx` or `getrandom`. Targeting `3.3.8` ensures your binary is universally compatible across decades of Linux kernel releases.

### 4. Zero-Dependency, One-Click Deployment
No opkg, no pip, no apt, no shared libraries, and no complex dependency trees.
To run the Reticulum stack on any router, a user simply downloads the binary, uploads it to the device (e.g., via FTP or SCP to `/tmp` or `/opt`), runs `chmod +x`, and starts it. It **just works**.

---

## Architectural Boundaries (Where It Won't Run)

While the portability of this static build is phenomenal, it is still bound by the laws of CPU architecture:
1. **MIPS Endianness (The Big-Endian vs Little-Endian Divide):**
   - This build targets **MIPS (Big-Endian)**, which powers Qualcomm Atheros chips (AR9xxx, QCA95xx, QCA55xx, `ath79-generic` target).
   - It will **not** run on **MIPSEL (Little-Endian)** chips like MediaTek/Ralink (MT7620, MT7621, MT7628), which power many entry-level Xiaomi and Keenetic routers. To support those, the project must be compiled targeting `mipsel-unknown-linux-musl`.
2. **Other CPU Architectures:** It will not run on ARMv7, ARMv8/AArch64, or x86_64 routers.




## Resource Footprint (Measured on ASUS RT-AC57U V3)

| Component | RAM Usage | Binary Size (Stripped) | CPU (Idle) | OS Compatibility |
| :--- | :--- | :--- | :--- | :--- |
| **`lnsd`** (Transport) | ~3.2 MB | ~2.1 MB | < 0.5% | Statically linked Linux binary |
| **`lblogd`** (Blog) | ~2.4 MB | ~1.8 MB | < 0.2% | Statically linked Linux binary |
| **Python RNS (Reference)** | ~45–70 MB | N/A (Python libs) | Spikes to 100% | Requires Python 3 + pip dependencies |

---

## Features

- **Soft-Float MIPS Static Binaries:** Statically compiled Rust binaries for MIPS architectures with no hardware FPU.
- **RAM-Cached Blog Storage:** All temporary caches are written to RAM (`/tmp/lblogd_cache`) to protect your flash drive from flash wear.
- **Custom `index.mu` Support (Optional):** Modded `lblogd` that serves an optional custom `index.mu` (supporting ASCII art, pseudographics, or any custom text) directly if it exists in the `posts/` folder. If no custom file is found, the server automatically falls back to generating the default index page.
- **Flexible Network Linking via `socat`:** Allows you to easily forward, redirect, and link network nodes across different topologies. For I2P, it enables connecting your low-resource transport node to either your own local/remote `i2pd` server or third-party/public SAM bridges. This keeps the node's CPU usage minimal by outsourcing heavy cryptographic tasks.
- **ASUSWRT & Entware Persistence:** Scripts placed in `/opt/etc/init.d/` to survive reboots on systems with read-only root filesystems.
- **Built-in HTTP Web Gateway:** `lblogd` includes a lightweight, built-in HTTP server. When enabled, it acts as a local web gateway, allowing any standard web browser (on your phone, PC, or tablet) to access and read your Reticulum blog pages directly over HTTP without needing NomadNet or Sideband clients installed!

---

## Device Directory Structure

*Note: The directory structure below is just a concrete example used in this specific deployment to meet our custom requirements. You are free to organize your directories differently to suit your own environment and design.*

```text
/tmp/mnt/sda1/home/lblogd/
├── .reticulum/		 # Folder automatically created by lnsd on first startup
│   ├── config		 # Reticulum network configuration (must be placed here)
│   └── storage/		 # Reticulum network state (ratchets, discovery, etc.)
├── files/			   # Folder for files you want to share over NomadNet
├── identities/		  # Node identities (auto-generated)
│   └── lblogd
├── lblogd			   # Statically-linked lblogd binary (soft-float)
├── lblogd.log		   # Blog server log file
├── lblogd.toml		  # Blog server configuration
├── lblog.sh			 # Main service start/stop control script
├── lnsd				 # Statically-linked lnsd binary (soft-float)
├── lnsd.log			 # Network transport log file
├── posts/			   # Folder for your Micron blog posts
│   └── index.mu		 # Optional custom homepage (e.g. ASCII art, bypassed if not present)
└── reticulum			# Symlink created manually to expose the hidden .reticulum folder via FTP
```

---


<details>
<summary><b>🛠️ Configuration File Structure & Examples (Click to expand)</b></summary>

### 1. Reticulum Network Configuration (`config`)
The Reticulum network config controls transport, routing, and interfaces. The daemon searches for it at `$HOME/.reticulum/config`.

```toml
[reticulum]
enable_transport = yes          # Enables the node to forward packets on behalf of others
share_instance = yes            # Allows multiple local applications to share this transport
shared_instance_port = 37428    # Standard port for shared local instances
storagepath = /tmp/reticulum/storage # RAM-disk storage to prevent flash drive wear

[logging]
loglevel = 1                    # Log level: 1 (Info), 2 (Warning), 3 (Error), 0 (Debug)

[interfaces]
  # Exposes transport to local Wi-Fi and LAN
  [[Local Wi-Fi Server]]
    type = TCPServerInterface
    enabled = yes
    listen_ip = 0.0.0.0
    listen_port = 4242

  # Connects to global I2P network via the lightweight socat SAM bridge
  [[I2P Bridge Interface]]
    type = I2PInterface
    enabled = yes
    sam_host = 127.0.0.1
    sam_port = 7656
    peers = ["s2hv32euft4t5v4rb6ommh37kcwbwxsjeda33dujx4ool2a3jyfa.b32.i2p"]

  # Connects to public Reticulum community nodes
  [[WDGWars Node]]
    type = TCPClientInterface
    enabled = yes
    target_host = rns.wdgwars.pl
    target_port = 4242
```

#### Official Reticulum Configuration Resources:
- **Official Reticulum Reference Manual:** [reticulum.network/manual/](https://reticulum.network/manual/interfaces.html) - Extensive guide on all interface types, parameters, and routing protocols.
- **Reticulum GitHub Repository:** [github.com/markqvist/Reticulum](https://github.com/markqvist/Reticulum) - The reference implementation with default configurations and examples.

---

### 2. NomadNet/Micron Blog Configuration (`lblogd.toml`)
This file configures the blog server, directories, and post announcing settings. The server searches for it in its active execution directory.

```toml
data_dir = "/tmp/lblogd_cache"  # Blog cache folder (placed in RAM to save flash memory)
posts_dir = "/tmp/mnt/sda1/home/lblogd/posts" # Path to Micron blog posts (.mu files)
files_dir = "/tmp/mnt/sda1/home/lblogd/files" # Path to shared files
max_file_bytes = 10485760       # Limit shared file size to 10MB
watch_posts = true              # Live-reload posts on folder modification

[blog]
title = "My First Reticulum Site"
author = "Administrator"
description = "Lightweight blog running directly from an embedded home router!"
language = "en"

[node]
instance_name = "default"
announce_interval_secs = 21600  # Mesh announcement interval (6 hours)

[web]
acme = false                    # Disable ACME/HTTPS to save system resources
# Bind address for the HTTP Web Gateway.
# By setting this to "0.0.0.0:8180", your blog becomes fully accessible over HTTP 
# to any standard web browser on any device (phone, PC, tablet) connected to your local Wi-Fi!
http_bind = "0.0.0.0:8180"
```

#### Official Micron & NomadNet Resources:
- **NomadNet & Micron Specs:** [github.com/markqvist/nomadnet](https://github.com/markqvist/nomadnet) - Learn about the Micron markup language (.mu), node specifications, and page rendering.
- **Original Leviculum Codeberg:** [codeberg.org/Lew_Palm/leviculum](https://codeberg.org/Lew_Palm/leviculum) - Up-to-date documentation on the Rust-based transport and blog server implementation.

</details>


## Deployment Guide

> ℹ️ **Note:** Pre-compiled static binaries for MIPS Big-Endian (soft-float) are available under the **Releases** tab of this repository. If you prefer to compile them yourself from source, please refer to the [Compilation Guide](#compilation-guide-how-to-build-from-source).

### Step 1: Prepare the Directories & Copy Binaries
Create your working directory on the storage drive (e.g., `/tmp/mnt/sda1/home/lblogd/`) and copy the pre-compiled `lnsd` and `lblogd` binaries there.

### Step 2: Set up I2P Redirection / SAM Bridge (Optional)
Using `socat` is a highly versatile pattern. It allows you to dynamically route and bridge connections. For example, if you run `i2pd` on another machine (e.g., `192.168.5.100`) or wish to connect to a third-party SAM bridge, you can forward the SAM API port `7656` directly to your local node.

Copy `scripts/S50socat` to `/opt/etc/init.d/S50socat` and start it:
```bash
/opt/etc/init.d/S50socat start
```
*This starts a resilient, auto-restarting background loop that forwards your local port `7656` to your I2P server:* `socat TCP4-LISTEN:7656,reuseaddr,fork TCP4:192.168.5.100:7656`.

### Step 3: Deploy Control Scripts
1. Copy `scripts/lblog.sh` to `/tmp/mnt/sda1/home/lblogd/lblog.sh` and make it executable:
   ```bash
   chmod +x /tmp/mnt/sda1/home/lblogd/lblog.sh
   ```

2. **Important for ASUSWRT and Entware Users:** On ASUSWRT, the root directory (`/`) is mounted in a read-only ramfs/squashfs and is wiped on reboot. Place your startup script in `/opt/etc/init.d/S90leviculum` to ensure it survives reboots.

Create `/opt/etc/init.d/S90leviculum` on your device and copy the following script into it:

```bash
#!/bin/sh

# ==============================================================================
# LEVICULUM SERVICE WRAPPER (lnsd + lblogd)
# ==============================================================================
ENABLED=yes
SCRIPT="/tmp/mnt/sda1/home/lblogd/lblog.sh"
# ==============================================================================

start() {
    [ "$ENABLED" != "yes" ] && return
    
    if [ ! -f "$SCRIPT" ]; then
        echo "Error: Leviculum control script not found at $SCRIPT"
        return 1
    fi

    echo "Starting Leviculum services (lnsd + lblogd)..."
    HOME=/tmp/mnt/sda1/home/lblogd "$SCRIPT" start
}

stop() {
    if [ ! -f "$SCRIPT" ]; then
        echo "Error: Leviculum control script not found at $SCRIPT"
        return 1
    fi

    echo "Stopping Leviculum services (lnsd + lblogd)..."
    HOME=/tmp/mnt/sda1/home/lblogd "$SCRIPT" stop
}

restart() {
    if [ ! -f "$SCRIPT" ]; then
        echo "Error: Leviculum control script not found at $SCRIPT"
        return 1
    fi

    echo "Restarting Leviculum services..."
    HOME=/tmp/mnt/sda1/home/lblogd "$SCRIPT" restart
}

status() {
    if [ ! -f "$SCRIPT" ]; then
        echo "Leviculum script is missing."
        return 1
    fi

    HOME=/tmp/mnt/sda1/home/lblogd "$SCRIPT" status
}

case "$1" in
    start)   start ;;
    stop)    stop ;;
    restart) restart ;;
    status)  status ;;
    *)       echo "Usage: $0 {start|stop|restart|status}"; exit 1 ;;
esac
```

3. Make the script executable:
   ```bash
   chmod +x /opt/etc/init.d/S90leviculum
   ```

### Step 4: First Run & Initial Directory Setup (Crucial)
When you start the transport for the first time, it needs to generate its internal configuration and directory structures.

1. **Trigger the first start to auto-generate the directories:**
   ```bash
   /opt/etc/init.d/S90leviculum start
   ```
   *This starts `lnsd`, which will automatically detect that no `.reticulum` directory exists and will create it inside `/tmp/mnt/sda1/home/lblogd/`.*

2. **Stop the service to configure it:**
   ```bash
   /opt/etc/init.d/S90leviculum stop
   ```

3. **Deploy your Reticulum configuration:**
   Copy your network configuration file (you can use `configs/reticulum.config` as a template) directly to `/tmp/mnt/sda1/home/lblogd/.reticulum/config`.

4. **Create the Symlink:**
   Since folders starting with a dot (like `.reticulum`) are hidden by default in most FTP/SFTP clients, you can create a visible symlink. This can be done via SSH, your FTP client's built-in link/symlink creation feature, or any other method you prefer.

   If using SSH, run:
   ```bash
   cd /tmp/mnt/sda1/home/lblogd/
   ln -s .reticulum reticulum
   ```
   *Now you can easily access and edit your Reticulum network config directly through your FTP client via the `reticulum/config` path.*

### Step 5: Start & Monitor
Now everything is configured! Start the services permanently:
```bash
/opt/etc/init.d/S90leviculum start
```

To check current status:
```bash
/opt/etc/init.d/S90leviculum status
```

### Step 6: Verifying and Visiting Your Site
To verify everything works and visit your newly created NomadNet-site:
1. Find your site's destination hash by running:
   ```bash
   cat /tmp/mnt/sda1/home/lblogd/lblogd.log | grep "node destination"
   ```
2. Open NomadNet or Sideband on any device connected to the Reticulum mesh.
3. Navigate to `nomad://<your-destination-hash>/page/index.mu` to visit your site.
4. **Via Standard Web Browser (Clearnet Gateway):**  
   If you enabled `http_bind = "0.0.0.0:8180"` in `lblogd.toml`, simply open your browser on any local device and go to:  
   `http://<your-router-lan-ip>:8180` (e.g., `http://192.168.5.220:8180`).

> 🔒 **Firewall Note:** If accessing the Web Gateway (`:8180`) or local Reticulum TCP server (`:4242`) from other devices on your LAN fails, make sure your router's firewall allows inbound traffic on those ports, or ensure you are connecting from the trusted LAN bridge (`br0`).

---

## Compilation Guide (How to Build From Source)

To compile the binaries yourself from the source code, follow this complete step-by-step guide.

### 1. Clone the Parent Repository
First, clone the original **Leviculum** repository by Lew Palm:
```bash
git clone https://codeberg.org/Lew_Palm/leviculum.git
cd leviculum
```

### 2. Apply Custom Patches
This repository provides two custom patches to make compile and homepage customization easy:

#### A. Apply Custom Homepage Patch (Optional)
By default, `lblogd` automatically generates a list of posts as its index page. Applying this patch modifies `lblogd` to check if a file named `index.mu` exists in your `posts/` directory. If it does, `lblogd` bypasses the auto-generation and serves your custom file directly.

This gives you total control over your homepage: you can design a fully custom landing page, add ASCII art, or change the layout entirely. Whenever you want to update your homepage, you simply replace or edit the `index.mu` file on your active node—**no recompilation of the binary is required!**

```bash
patch -p1 < /path/to/leviculum-embedded-node/patches/lblogd-custom-index.patch
```

#### B. Apply 32-bit Atomics Patch (Required for MIPS compilation)
MIPS processors with no FPU lack hardware 64-bit atomic operations. Applying this patch replaces traffic counters in `leviculum-std` with `AtomicUsize` and casts them to `u64` when serialized, ensuring successful compilation under MIPS.

```bash
patch -p1 < /path/to/leviculum-embedded-node/patches/mips-32bit-atomics.patch
```

### 3. Workarounds for MIPS Architecture
- **Missing `libunwind`:** To bypass the lack of static `libunwind.a` in the SDK, copy `libgcc_eh.a` as `libunwind.a` into the root of the cloned `leviculum` directory:
  ```bash
  cp /home/user/sdk/openwrt-sdk-23.05.3-ath79-generic_gcc-12.3.0_musl.Linux-x86_64/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl/lib/gcc/mips-openwrt-linux-musl/12.3.0/libgcc_eh.a ./libunwind.a
  ```

### 4. Create Cargo Configuration
Create a `.cargo/config.toml` file inside your cloned `leviculum` directory and populate it with the cross-compilation settings:

> **Warning:** Be sure to replace `/home/user/...` with the actual absolute path to your downloaded OpenWrt SDK on your build machine.

```toml
[build]
rustflags = [
    "-C", "target-feature=+crt-static",
    "-C", "target-feature=+soft-float",
    "-C", "link-self-contained=no",
    "--sysroot=/home/user/sdk/openwrt-sdk-23.05.3-ath79-generic_gcc-12.3.0_musl.Linux-x86_64/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl",
    # Points to the directory where you copied libunwind.a (project root)
    "-C", "link-arg=-L.",
    "-C", "link-arg=-L/home/user/sdk/openwrt-sdk-23.05.3-ath79-generic_gcc-12.3.0_musl.Linux-x86_64/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl/lib",
    "-C", "link-arg=-L/home/user/sdk/openwrt-sdk-23.05.3-ath79-generic_gcc-12.3.0_musl.Linux-x86_64/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl/lib/gcc/mips-openwrt-linux-musl/12.3.0",
    "-C", "link-arg=-static",
    "-C", "link-arg=-static-libgcc",
    "-C", "link-arg=-static-libstdc++",
    "-C", "link-arg=-lc",
    "-C", "link-arg=-lm",
    "-C", "link-arg=-lgcc",
]

[unstable]
build-std = ["std","panic_abort"]

[target.mips-unknown-linux-musl]
linker = "/home/user/sdk/openwrt-sdk-23.05.3-ath79-generic_gcc-12.3.0_musl.Linux-x86_64/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl/bin/mips-openwrt-linux-musl-gcc"
```

### 5. Build Commands
Run these commands from the root of the cloned `leviculum` directory to build the statically-linked, soft-float binaries:

```bash
# Build lblogd (blog-server)
cargo +nightly build --target mips-unknown-linux-musl --release -p lblogd -Zbuild-std

# Build lnsd (network transport)
cargo +nightly build --target mips-unknown-linux-musl --release -p leviculum-cli --bin lnsd -Zbuild-std
```

### 6. Strip Debug Symbols (Critical for Size Reduction)
To reduce the binary size significantly so that it consumes minimal storage and memory on your node, use the `strip` utility from the SDK:

```bash
# Strip lblogd
/home/user/sdk/openwrt-sdk-23.05.3-ath79-generic_gcc-12.3.0_musl.Linux-x86_64/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl/bin/mips-openwrt-linux-musl-strip target/mips-unknown-linux-musl/release/lblogd

# Strip lnsd
/home/user/sdk/openwrt-sdk-23.05.3-ath79-generic_gcc-12.3.0_musl.Linux-x86_64/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl/bin/mips-openwrt-linux-musl-strip target/mips-unknown-linux-musl/release/lnsd
```

Once stripped, the binaries are ready to be copied to your node!

---

## License

This deployment wrapper and adaptation are distributed under the terms of the **AGPL-3.0-or-later** license, matching the license of the parent **Leviculum** project.
