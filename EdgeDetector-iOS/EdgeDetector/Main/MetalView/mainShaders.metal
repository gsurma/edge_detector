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
    
    float dataWidth = dataSize[0];
    float dataHeight = dataSize[1];
    
    float drawableWidth = drawableSize[0];
    float drawableHeight = drawableSize[1];

    int scaledX = gid.x / drawableWidth * dataWidth;
    int scaledY = gid.y / drawableHeight * dataWidth;

    int index = scaledY + scaledX * dataHeight;
    float edgeProbability = edgeProbabilities[index];
    
    float4 originalColor = inTexture.read(gid);
    float4 darkenOriginalColor = mix(originalColor, float4(0.0, 0.0, 0.0, 1.0), half(0.5));
    float4 mixedColor = mix(darkenOriginalColor, float4(1.0, 1.0, 1.0, 1.0), half(edgeProbability));
    outTexture.write(mixedColor, gid);
}
