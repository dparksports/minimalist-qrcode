# Minimalist QR Code Scanner

A simple, native macOS command-line tool to scan Wi-Fi QR codes and extract passwords.

## Installation

### Option 1: Download Binary (Recommended)

Run the following command to download and run the tool on any Mac (Intel or Apple Silicon):

```bash
# Download
curl -L -o wifi_scanner https://github.com/dparksports/minimalist-qrcode/releases/latest/download/wifi_scanner

# Verify Checksum (Recommended)
echo "1cef2f0595271957a376534e8b5facb812261f859578709f67d0be98d107d3a6  wifi_scanner" | shasum -a 256 -c -

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
