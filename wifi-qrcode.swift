#!/usr/bin/swift
import Foundation
import Vision
import AppKit

// 1. Get image path from arguments
guard CommandLine.arguments.count > 1 else {
    print("Usage: swift wifi_scan.swift <path/to/qrcode.png>")
    exit(1)
}
let imagePath = CommandLine.arguments[1]

// 2. Load the image
guard let nsImage = NSImage(contentsOfFile: imagePath),
      let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Error: Could not load image at \(imagePath)")
    exit(1)
}

// 3. Define the QR detection request
let request = VNDetectBarcodesRequest { request, error in
    guard let results = request.results as? [VNBarcodeObservation], !results.isEmpty else {
        print("No QR code found.")
        exit(0)
    }

    for result in results {
        if let payload = result.payloadStringValue, payload.hasPrefix("WIFI:") {
            extractPassword(from: payload)
            exit(0) // Found it, done.
        }
    }
    print("No Wi-Fi QR code detected.")
}

// 4. Helper to parse the Wi-Fi string (Format: WIFI:S:SSID;T:WPA;P:PASSWORD;;)
func extractPassword(from wifiString: String) {
    let components = wifiString.split(separator: ";")
    var ssid: String?
    var password: String?

    for component in components {
        let trimmed = component.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("S:") {
            ssid = String(trimmed.dropFirst(2))
        } else if trimmed.hasPrefix("P:") {
            password = String(trimmed.dropFirst(2))
        }
    }
    
    if let ssid = ssid, let password = password {
        print("Network: \(ssid)")
        print("Password: \(password)")
        return
    }
    
    print("Wi-Fi QR found, but missing SSID or Password.")
}

// 5. Perform the request
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try? handler.perform([request])