//
//  MainMetalView.swift
//  EdgeDetector
//
//  Created by Greg on 24/07/2019.
//  Copyright © 2019 GS. All rights reserved.
//

import MetalKit
import CoreVideo
import CoreML

final class MainMetalView: MTKView {
    
    lazy var dataSizeArray: [Float]  =  {
        return [Float(textureSize), Float(textureSize)]
    }()
    lazy var drawableSizeArray: [Float]  =  {
        return [Float(self.drawableSize.width), Float(self.drawableSize.height)]
    }()
    var edgeProbabilities: [Float] = [Float](repeating: 0, count: textureSize*textureSize)
    var pixelBuffer: CVPixelBuffer? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var textureCache: CVMetalTextureCache?
    private var commandQueue: MTLCommandQueue
    private var computePipelineState: MTLComputePipelineState
    
    required init(coder: NSCoder) {
        
        let metalDevice = MTLCreateSystemDefaultDevice()!
        
        commandQueue = metalDevice.makeCommandQueue()!
        let bundle = Bundle.main
        let url = bundle.url(forResource: "default", withExtension: "metallib")
        let library = try! metalDevice.makeLibrary(filepath: url!.path)
        let function = library.makeFunction(name: "colorKernel")!
        
        computePipelineState = try! metalDevice.makeComputePipelineState(function: function)
        
        var textCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textCache) != kCVReturnSuccess {
            fatalError("Unable to allocate texture cache.")
        }
        else {
            textureCache = textCache
        }
        
        super.init(coder: coder)
        device = metalDevice
        
        framebufferOnly = false
        
        drawableSize.width = 720
        drawableSize.height = 1280
    }
    
    override func draw(_ rect: CGRect) {
        autoreleasepool {
            if rect != CGRect.zero {
                self.render(self)
            }
        }
    }
    
    private func render(_ view: MTKView) {
        guard let pixelBuffer = self.pixelBuffer else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut)
        
        guard let cvTexture = cvTextureOut, let inputTexture = CVMetalTextureGetTexture(cvTexture) else {
            print("Failed to create metal texture")
            return
        }
        
        guard let drawable: CAMetalDrawable = self.currentDrawable else { return }
        
        if let commandBuffer = commandQueue.makeCommandBuffer(), let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder() {
            computeCommandEncoder.setComputePipelineState(computePipelineState)
            computeCommandEncoder.setTexture(inputTexture, index: 0)
            computeCommandEncoder.setTexture(drawable.texture, index: 1)
            computeCommandEncoder.setBuffer(device!.makeBuffer(bytes: &edgeProbabilities, length: MemoryLayout<Float>.size*edgeProbabilities.count, options: []), offset: 0, index: 2)
            computeCommandEncoder.setBuffer(device!.makeBuffer(bytes: &drawableSizeArray, length: MemoryLayout<Float>.size*drawableSizeArray.count, options: []), offset: 0, index: 3)
            computeCommandEncoder.setBuffer(device!.makeBuffer(bytes: &dataSizeArray, length: MemoryLayout<Float>.size*dataSizeArray.count, options: []), offset: 0, index: 4)
            computeCommandEncoder.dispatchThreadgroups(inputTexture.threadGroups(), threadsPerThreadgroup: inputTexture.threadGroupCount())
            computeCommandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

extension MTLTexture {
    
    func threadGroupCount() -> MTLSize {
        return MTLSizeMake(8, 8, 1)
    }
    
    func threadGroups() -> MTLSize {
        let groupCount = threadGroupCount()
        return MTLSize(width: (Int(width) + groupCount.width-1)/groupCount.width,
                       height: (Int(height) + groupCount.height-1)/groupCount.height,
                       depth: 1)
    }
}
