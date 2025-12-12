import AVFoundation
import Vision
import Cocoa

print("1. Program launched...")

class Scanner: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    
    func start() {
        print("4. Configuring Camera...")
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("❌ Error: No camera found or input failed.")
            exit(1)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
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
                    self.parseAndLog(payload)
                }
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func parseAndLog(_ payload: String) {
        // Expected Format: WIFI:S:SSID;T:WPA;P:PASSWORD;;
        let components = payload.split(separator: ";")
        for component in components {
            if component.trimmingCharacters(in: .whitespaces).hasPrefix("P:") {
                let password = component.dropFirst(2)
                
                // Print clearly and exit
                print("\n✅ FOUND PASSWORD: \(password)")
                exit(0)
            }
        }
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