//
//  IMPHistogramTypes.h
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPHistogramTypes_h
#define IMPHistogramTypes_h

#ifdef __METAL_VERSION__
# include <metal_stdlib>
#else
# include <stdlib.h>
# define constant const
#endif

# include <simd/simd.h>


///
/// Не будем выдумавыть новые размерности цветовых гистограм - остановимся на магическом 256.
///
static constant uint kIMP_HistogramSize        = 256;
static constant uint kIMP_HistogramMaxChannels = 4;

///
/// Буфер бинов гистограммы
///
typedef struct IMPHistogramBuffer {
    uint channels[kIMP_HistogramMaxChannels][kIMP_HistogramSize];
}IMPHistogramBuffer;


typedef struct {
    float channels[kIMP_HistogramMaxChannels][kIMP_HistogramSize];
}IMPHistogramFloatBuffer;

typedef struct {
    float r,g,b,a;
}IMPHistogramLayerComponent;

struct IMPHistogramLayer {
#ifdef __METAL_VERSION__
    float4                      components[kIMP_HistogramMaxChannels];;
    float4                      backgroundColor;
#else
    packed_float4               components[kIMP_HistogramMaxChannels];;
    packed_float4               backgroundColor;
#endif
    bool                        backgroundSource;
};

#endif /* IMPHistogramTypes_h */
