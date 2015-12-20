//
//  IMPTypes.h
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPTypes_h
#define IMPTypes_h

#ifdef __METAL_VERSION__
# include <metal_stdlib>
using namespace metal;
#else
# include <stdlib.h>
# define constant const
#endif

# include <simd/simd.h>


struct IMPCropRegion {
    float top;
    float right;
    float left;
    float bottom;
};

typedef enum : uint {
    LUMINOSITY = 0,
    NORMAL
}IMPBlendingMode;

typedef struct {
    IMPBlendingMode    mode;
    float              opacity;
} IMPBlending;

typedef struct{
    IMPBlending    blending;
} IMPAdjustment;


typedef struct{
    packed_float4  dominantColor;
    IMPBlending    blending;
} IMPWBAdjustment;

typedef struct{
    packed_float4  minimum;
    packed_float4  maximum;
    IMPBlending    blending;
} IMPContrastAdjustment;


#endif /* IMPTypes_h */
