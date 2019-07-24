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

class MainViewController: UIViewController {
    
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
        mainVideoCapture.setUp(sessionPreset: AVCaptureSession.Preset.hd1920x1080, frameRate: 30) { success in
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
                self.mainMetalView.pixelBuffer = pb
                self.edgeDetector.predict(pixelBuffer: pb)
            }
        }
    }
}

extension MainViewController: EdgeDetectorDelegate {
    
    func predictionCompleted(edgeProbabilities: [Float]) {
        
    }
}

