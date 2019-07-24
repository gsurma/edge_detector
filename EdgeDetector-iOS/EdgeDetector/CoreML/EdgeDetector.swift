//
//  EdgeDetector.swift
//  EdgeDetector
//
//  Created by Greg on 24/07/2019.
//  Copyright © 2019 GS. All rights reserved.
//

import Foundation

import Foundation
import UIKit
import CoreML
import Vision

protocol EdgeDetectorDelegate {
    func predictionCompleted(edgeProbabilities: [Float])
}

final class EdgeDetector  {
    
    var delegate: EdgeDetectorDelegate?
    private let maxInflightBuffers = 3
    private let semaphore: DispatchSemaphore!
    private var model: VNCoreMLModel!
    private var inflightBuffer = 0
    private var requests = [VNCoreMLRequest]()
    
    public init() {
        self.semaphore = DispatchSemaphore(value: maxInflightBuffers)
        self.model = try! VNCoreMLModel(for: EdgeDetectorModel().model)
        for _ in 0..<maxInflightBuffers {
            let request = VNCoreMLRequest(model: self.model, completionHandler: visionRequestDidComplete)
            request.imageCropAndScaleOption = .scaleFill
            requests.append(request)
        }
    }

    func predict(pixelBuffer: CVPixelBuffer) {
        guard semaphore.wait(timeout: .now()) == .success  else {
            return
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation.leftMirrored)
        predict(handler: handler)
    }
    
    private func predict(handler: VNImageRequestHandler) {
        let inflightIndex = inflightBuffer
        inflightBuffer += 1
        if inflightBuffer >= maxInflightBuffers {
            inflightBuffer = 0
        }
        
        DispatchQueue.global().async {
            let request = self.requests[inflightIndex]
            do {
                try handler.perform([request])
            } catch let error {
                print("Error: \(error)")
            }
        }
    }
    
    private func sigmoid(input: Double) -> Double {
        return 1 / (1 + exp(-input))
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
            delegate?.predictionCompleted(edgeProbabilities: edgeProbabilities)
        }
        semaphore.signal()
    }
}
