//
//  mainShaders.metal
//  EdgeDetector
//
//  Created by Greg on 24/07/2019.
//  Copyright © 2019 GS. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void colorKernel(texture2d<float, access::read> inTexture [[ texture(0) ]],
                        texture2d<float, access::write> outTexture [[ texture(1) ]],
                        const device float *edgeProbabilities [[buffer(2)]],
                        const device float *drawableSize [[buffer(3)]],
                        const device float *dataSize [[buffer(4)]],
                        uint2 gid [[ thread_position_in_grid ]]) {
    
    float cols = dataSize[0];
    float rows = dataSize[1];
    
    float drawableWidth = drawableSize[0];
    float drawableHeight = drawableSize[1];
    
    int scaledX = gid.x / drawableWidth * rows;
    int scaledY = gid.y / drawableHeight * cols;

    int index = scaledY + scaledX * rows;
    float edgeProbability = edgeProbabilities[index];
    
    outTexture.write(float4(edgeProbability, edgeProbability, edgeProbability,1.0), gid);
}
