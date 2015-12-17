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
# include <simd/simd.h>
#else
# include <stdlib.h>
# define constant const
#endif

///
/// Не будем выдумавыть новые размерности цветовых гистограм - остановимся на магическом 256.
///
static constant int kIMP_HistogramSize     = 256;
static constant int kIMP_HistogramChannels = 4;
static constant int kIMP_HistogramGroups   = 16;

struct IMPHistogramBuffer {
#ifdef __METAL_VERSION__
    simd::atomic_uint channels[kIMP_HistogramChannels][kIMP_HistogramSize];
#else
    uint channels[kIMP_HistogramChannels][kIMP_HistogramSize];
#endif
};

struct IMPHistogramPartialBuffer {
    uint channels[kIMP_HistogramChannels][kIMP_HistogramSize];
};

#endif /* IMPHistogramTypes_h */
