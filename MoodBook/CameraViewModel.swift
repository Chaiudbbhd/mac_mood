import SwiftUI
import AVFoundation
import Vision
import Combine

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @Published var currentMoodText: String = "Scanning…"
    @Published var currentEmoji: String = "🤔"
    @Published var cameraAuthorized = false
    
    private let session = AVCaptureSession()
    private var lastUpdateTime: Date = Date()
    private let updateInterval: TimeInterval = 2.0
    
    override init() {
        super.init()
        checkPermission()
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.setupCamera() }
            }
        default: print("Camera access denied")
        }
    }
    
    private func setupCamera() {
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
        
        session.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        session.addOutput(output)
        
        session.startRunning()
        DispatchQueue.main.async { self.cameraAuthorized = true }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard Date().timeIntervalSince(lastUpdateTime) > updateInterval else { return }
        lastUpdateTime = Date()
        detectMood(from: sampleBuffer)
    }
    
    private func detectMood(from sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self else { return }
            guard let results = request.results as? [VNFaceObservation],
                  let face = results.first else {
                DispatchQueue.main.async {
                    self.setMood(mood: "Sad")
                }
                return
            }
            
            var mood = "Sad"
            
            if let mouth = face.landmarks?.innerLips,
               let leftEye = face.landmarks?.leftEye,
               let rightEye = face.landmarks?.rightEye,
               let leftBrow = face.landmarks?.leftEyebrow,
               let rightBrow = face.landmarks?.rightEyebrow,
               mouth.normalizedPoints.count >= 4,
               leftEye.normalizedPoints.count >= 6,
               rightEye.normalizedPoints.count >= 6,
               leftBrow.normalizedPoints.count >= 2,
               rightBrow.normalizedPoints.count >= 2 {
                
                let leftCorner = mouth.normalizedPoints.first!
                let rightCorner = mouth.normalizedPoints.last!
                let topLip = mouth.normalizedPoints[mouth.normalizedPoints.count / 3]
                let bottomLip = mouth.normalizedPoints[(mouth.normalizedPoints.count * 2) / 3]
                
                let mouthWidth = distance(leftCorner, rightCorner)
                let mouthHeight = distance(topLip, bottomLip)
                let mouthRatio = mouthWidth > 0 ? mouthHeight / mouthWidth : 0
                
                let leftEyeOpen = verticalDistance(leftEye.normalizedPoints[1], leftEye.normalizedPoints[5])
                let rightEyeOpen = verticalDistance(rightEye.normalizedPoints[1], rightEye.normalizedPoints[5])
                
                let browSlope = angleBetween(leftBrow.normalizedPoints[0], leftBrow.normalizedPoints.last!)
                
                // Sleepy
                if mouthRatio > 0.6 && leftEyeOpen < 0.12 && rightEyeOpen < 0.12 {
                    mood = "Sleepy"
                }
                // Happy
                else if mouthRatio > 0.35 && topLip.y > bottomLip.y && leftEyeOpen < 0.18 && rightEyeOpen < 0.18 {
                    mood = "Happy"
                }
                // Laugh
                else if mouthRatio > 0.5 && topLip.y < bottomLip.y {
                    mood = "Laugh"
                }
                // Shock
                else if browSlope > 15 && leftEyeOpen > 0.25 && rightEyeOpen > 0.25 {
                    mood = "Shock"
                }
                // Sad
                else {
                    mood = "Sad"
                }
            }
            
            DispatchQueue.main.async { self.setMood(mood: mood) }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([request])
    }
    
    private func setMood(mood: String) {
        self.currentMoodText = mood
        switch mood {
        case "Sleepy": currentEmoji = "😴"
        case "Happy": currentEmoji = "😄"
        case "Sad": currentEmoji = "😢"
        case "Shock": currentEmoji = "😲"
        case "Laugh": currentEmoji = "😆"
        default: currentEmoji = "🤔"
        }
    }
    
    // Helper functions
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }
    
    private func verticalDistance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        abs(p2.y - p1.y)
    }
    
    private func angleBetween(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return atan2(dy, dx) * 180 / .pi
    }
}
