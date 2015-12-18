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

#ifdef __METAL_VERSION__
#else
#endif

///
/// Не будем выдумавыть новые размерности цветовых гистограм - остановимся на магическом 256.
///
static constant uint kIMP_HistogramSize        = 256;
static constant uint kIMP_HistogramMaxChannels = 4;

///
/// Буфер бинов гистограммы
///
struct IMPHistogramBuffer {
    uint channels[kIMP_HistogramMaxChannels][kIMP_HistogramSize];
};

typedef struct {
    float  bins[kIMP_HistogramSize];
    packed_float4 color;
}IMPHistogramLayerComponents;

typedef struct {
    float x;
    float y;
    float width;
    float height;
}IMPHistogramLayerFrame;

struct IMPHistogramLayer {
    IMPHistogramLayerComponents channels[kIMP_HistogramMaxChannels];
    IMPHistogramLayerFrame frame;
    float maxPerChannel;
};

#endif /* IMPHistogramTypes_h */
