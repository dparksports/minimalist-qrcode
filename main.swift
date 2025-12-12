import AVFoundation
import Vision
import Cocoa

print("1. Program launched...")

class Scanner: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    var frameCount = 0
    
    func start() {
        print("4. Configuring Camera...")
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("❌ Error: No camera found or input failed.")
            exit(1)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        // Removed forced BGRA setting to allow default YUV (better for Vision)
        
        session.addInput(input)
        session.addOutput(output)
        
        print("5. Starting Session...")
        // Move startRunning to background thread to prevent blocking the Main Loop
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                print("👀 SCANNING ACTIVE. Hold QR code up to camera.")
                print("(Press Ctrl+C to quit)")
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectBarcodesRequest { request, error in
            guard let results = request.results as? [VNBarcodeObservation] else { return }
            for result in results {
                if let payload = result.payloadStringValue, payload.hasPrefix("WIFI:") {
                    // Play success sound
                    NSSound(named: "Hero")?.play()
                    self.parseAndLog(payload)
                }
            }
        }
        // 1. Scan for QR Code (Prioritize this!)
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
        // 2. Render ASCII Preview (Throttle: Every 30 frames ~= 1 second)
        frameCount += 1
        if frameCount % 30 == 0 {
            let width = 64
            let height = 32
            if let ascii = self.asciiArt(from: pixelBuffer, width: width, height: height) {
                // Move cursor to top-left (ANSI) and print
                print("\u{001B}[H" + ascii)
            }
        }
    }
    
    // Convert PixelBuffer to ASCII Art (Optimized for YUV)
    func asciiArt(from pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> String? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        // YUV usually has 2 planes: Y (Luminance) and UV (Chrominance). We only need Y.
        // If it's not planar (e.g. BGRA from before), this might fail if we don't check.
        // But since we removed the setting, it defaults to YUV.
        
        var baseAddress: UnsafeMutableRawPointer?
        var bytesPerRow: Int
        var totalWidth: Int
        var totalHeight: Int
        
        if CVPixelBufferIsPlanar(pixelBuffer) {
            baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) // Y-Plane
            bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
            totalWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
            totalHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        } else {
            // Fallback for non-planar (shouldn't happen with default settings, but safe)
            baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
            bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            totalWidth = CVPixelBufferGetWidth(pixelBuffer)
            totalHeight = CVPixelBufferGetHeight(pixelBuffer)
        }
        
        guard let safeBase = baseAddress else { return nil }
        let buffer = safeBase.assumingMemoryBound(to: UInt8.self)
        
        var art = ""
        let chars = ["@", "%", "#", "*", "+", "=", "-", ":", ".", " "]
        
        let stepX = totalWidth / width
        let stepY = totalHeight / height
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelX = x * stepX
                let pixelY = y * stepY
                let offset = pixelY * bytesPerRow + pixelX // 1 byte per pixel in Y plane
                
                let brightness = buffer[offset] // Direct luminance value
                let index = (Int(brightness) * (chars.count - 1)) / 255
                art.append(chars[index])
            }
            art.append("\n")
        }
        return art
    }
    
    func parseAndLog(_ payload: String) {
        // Expected Format: WIFI:S:SSID;T:WPA;P:PASSWORD;;
        // Strip "WIFI:" prefix if present so we can parse S: cleanly
        let cleanPayload = payload.hasPrefix("WIFI:") ? String(payload.dropFirst(5)) : payload
        
        var ssid: String?
        var password: String?
        
        let components = cleanPayload.split(separator: ";")
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("S:") {
                ssid = String(trimmed.dropFirst(2))
            } else if trimmed.hasPrefix("P:") {
                password = String(trimmed.dropFirst(2))
            }
        }
        
        if let ssid = ssid, let password = password {
            // Stop scanning so we don't trigger multiple times
            self.session.stopRunning()
            
            DispatchQueue.main.async {
                print("\n✅ FOUND NETWORK: \(ssid)")
                print("✅ FOUND PASSWORD: \(password)")
                
                print("\n❓ Do you want to join this network? [y/N]: ", terminator: "")
                if let response = readLine(), response.lowercased() == "y" || response.lowercased() == "yes" {
                    self.joinNetwork(ssid: ssid, password: password)
                } else {
                    print("👋 Exiting without joining.")
                    exit(0)
                }
            }
        } else {
            print("\(payload)")
        }
    }
    
    func joinNetwork(ssid: String, password: String) {
        print("🔗 Attempting to join network '\(ssid)'...")
        
        // ... (rest of join logic)
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-setairportnetwork", "en0", ssid, password]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            // Only print if there's an error or relevant info, otherwise keep it clean
             if task.terminationStatus != 0 {
                 print(output)
             }
        }
        
        if task.terminationStatus == 0 {
            print("🎉 Successfully joined '\(ssid)'!")
        } else {
            print("⚠️ Failed to join. You might need to check credentials or run with sudo.")
        }
        exit(task.terminationStatus)
    }
}

let scanner = Scanner()

print("2. Checking Permissions...")
switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        print("3. Permission already granted.")
        scanner.start()
    case .notDetermined:
        print("3. Requesting permission (Look for a popup)...")
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                print("3. Permission granted by user.")
                // Must jump back to main thread to start scanning
                DispatchQueue.main.async { scanner.start() }
            } else {
                print("❌ Permission denied.")
                exit(1)
            }
        }
    default:
        print("❌ Permission previously denied. Go to System Settings > Privacy > Camera.")
        exit(1)
}

// CRITICAL: Keep the app running indefinitely to allow the camera to work
RunLoop.main.run()