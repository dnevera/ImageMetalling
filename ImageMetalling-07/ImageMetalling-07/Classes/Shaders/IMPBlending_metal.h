//
//  IMPBlending_metal.h
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 18.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPBlending_metal_h
#define IMPBlending_metal_h

#ifdef __cplusplus

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

namespace IMProcessing
{
    
    inline  float4 blendNormal(float4 base, float4 overlay){
        
        float4 c2 = base;
        float4 c1 = overlay;
        
        float4 outputColor;
        
        float a = c1.a + c2.a * (1.0 - c1.a);
        float alphaDivisor = a + step(a, 0.0); // Protect against a divide-by-zero blacking out things in the output
        
        outputColor.r = (c1.r * c1.a + c2.r * c2.a * (1.0 - c1.a))/alphaDivisor;
        outputColor.g = (c1.g * c1.a + c2.g * c2.a * (1.0 - c1.a))/alphaDivisor;
        outputColor.b = (c1.b * c1.a + c2.b * c2.a * (1.0 - c1.a))/alphaDivisor;
        outputColor.a = a;
        
        return clamp(outputColor, float4(0.0), float4(1.0));
    }
    
}
#endif

#endif /* IMPBlending_metal_h */
