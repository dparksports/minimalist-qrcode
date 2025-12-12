# Minimalist QR Code Scanner

A simple, native macOS command-line tool to scan Wi-Fi QR codes and extract passwords.

## Installation

### Option 1: Download Binary (Recommended)

Run the following command to download and run the tool on any Mac (Intel or Apple Silicon):

```bash
# Download
curl -L -o wifi_scanner https://github.com/dparksports/minimalist-qrcode/releases/download/v1.2.4/wifi_scanner

# Verify Checksum (Recommended)
echo "82838b6f244d5f816dac22a8ef2cab6335ea8cac2f0ff3798c5deae2fb27b025  wifi_scanner" | shasum -a 256 -c -

# Make executable
chmod +x wifi_scanner

# Run
./wifi_scanner
```

> **Note**: Downloading via `curl` (as shown above) usually avoids macOS "Unidentified Developer" warnings. If you download via a browser, you may need to Right-Click > Open or go to System Settings > Privacy & Security to allow the app to run.


### Option 2: Build from Source

Requirements: macOS with Swift installed (Xcode Command Line Tools).

```bash
# Clone the repository
git clone https://github.com/dparksports/minimalist-qrcode.git
cd minimalist-qrcode

# Compile
sh compile.sh

# Run
./wifi_scanner
```

## Usage

Run the tool and point your camera at a Wi-Fi QR code.

```bash
./wifi_scanner
```

The tool will print the Wi-Fi password if found and exit.
