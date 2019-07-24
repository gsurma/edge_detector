//
//  EdgeDetector.swift
//  EdgeDetector
//
//  Created by Greg on 24/07/2019.
//  Copyright © 2019 GS. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import Vision

protocol EdgeDetectorDelegate {
    func predictionCompleted(edgeProbabilities: [Float], pixelBuffer: CVPixelBuffer)
}

final class EdgeDetector  {
    
    var delegate: EdgeDetectorDelegate?
    private let semaphore: DispatchSemaphore!
    private var model: VNCoreMLModel!
    private var request: VNCoreMLRequest!
    private var pixelBuffer: CVPixelBuffer!
    
    public init() {
        self.semaphore = DispatchSemaphore(value: 1)
        self.model = try! VNCoreMLModel(for: EdgeDetectorModel().model)
        self.request = VNCoreMLRequest(model: self.model, completionHandler: visionRequestDidComplete)
        self.request.imageCropAndScaleOption = .scaleFill
    }

    func predict(pixelBuffer: CVPixelBuffer) {
        guard semaphore.wait(timeout: .now()) == .success  else {
            return
        }
        self.pixelBuffer = pixelBuffer
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation.leftMirrored)
        predict(handler: handler)
    }
    
    private func predict(handler: VNImageRequestHandler) {
        DispatchQueue.global().async {
            do {
                try handler.perform([self.request])
            } catch let error {
                print("Prediction error: \(error)")
            }
        }
    }
    
    private func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let observation = request.results?.first as? VNCoreMLFeatureValueObservation, let value = observation.featureValue.multiArrayValue {
            let bufferSize = value.shape.lazy.map { $0.intValue }.reduce(1, { $0 * $1 })
            let dataPointer = UnsafeMutableBufferPointer(start: value.dataPointer.assumingMemoryBound(to: Double.self), count: bufferSize)
            var edgeProbabilities = [Float](repeating: 0, count: bufferSize)
            for x in 0..<textureSize {
                for y in 0..<textureSize {
                    let index = x * textureSize + y
                    let rawValue = dataPointer[index]
                    let result = sigmoid(input: rawValue)
                    edgeProbabilities[index] = Float(result)
                }
            }
            delegate?.predictionCompleted(edgeProbabilities: edgeProbabilities, pixelBuffer: pixelBuffer)
        }
        semaphore.signal()
    }
    
    private func sigmoid(input: Double) -> Double {
        return 1 / (1 + exp(-input))
    }
}
