//
//  IMPHistogramTypes.h
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPHistogramTypes_h
#define IMPHistogramTypes_h

#include <metal_stdlib>
#include <simd/simd.h>
#include "../Histogram/IMPHistogramConstatnts.h"

#ifdef __cplusplus

namespace IMP
{
    namespace histogramPreferences {
        static constant int size     = kIMP_HistogramSize;
        static constant int channels = kIMP_HistogramChannels;
        static constant int groups   = kIMP_HistogramGroups;
    };

    struct histogramBuffer {
        metal::atomic_uint channels[histogramPreferences::channels][histogramPreferences::size];
    };

    struct histogramPartialBuffer {
        metal::uint channels[histogramPreferences::channels][histogramPreferences::size];
    };

    typedef histogramPartialBuffer histogramPartialBuffers[histogramPreferences::size];

}

#endif

#endif /* IMPHistogramTypes_h */
