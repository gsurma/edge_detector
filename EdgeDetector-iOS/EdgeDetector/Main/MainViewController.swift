//
//  MainViewController.swift
//  EdgeDetector
//
//  Created by Greg on 24/07/2019.
//  Copyright © 2019 GS. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

final class MainViewController: UIViewController {
    
    @IBOutlet weak var mainMetalView: MainMetalView!
    private var mainVideoCapture: MainVideoCapture!
    private var edgeDetector: EdgeDetector!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpCamera()
        setUpDetector()
    }
    
    private func setUpCamera() {
        mainVideoCapture = MainVideoCapture()
        mainVideoCapture.delegate = self
        mainVideoCapture.setUp(sessionPreset: AVCaptureSession.Preset.hd1280x720, frameRate: 20) { success in
            if success {
                self.mainVideoCapture.start()
            }
        }
    }
    
    private func setUpDetector() {
        edgeDetector = EdgeDetector()
        edgeDetector.delegate = self
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension MainViewController: VideoCaptureDelegate {
    
    func videoCapture(_ capture: MainVideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        
        DispatchQueue.main.async {
            if let pb = pixelBuffer {
                self.edgeDetector.predict(pixelBuffer: pb)
            }
        }
    }
}

extension MainViewController: EdgeDetectorDelegate {
    
    func predictionCompleted(edgeProbabilities: [Float], pixelBuffer: CVPixelBuffer) {
        DispatchQueue.main.async {
            self.mainMetalView.pixelBuffer = pixelBuffer
            self.mainMetalView.edgeProbabilities = edgeProbabilities
        }
    }
}

