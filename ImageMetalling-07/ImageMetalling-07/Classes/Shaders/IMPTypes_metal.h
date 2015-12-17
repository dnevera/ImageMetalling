//
//  IMPTypes.h
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPTypes_h
#define IMPTypes_h

#include <simd/simd.h>

#ifdef __cplusplus

namespace IMP
{
    struct cropRegion {
        float top;
        float right;
        float left;
        float bottom;
    };
}

#endif


#endif /* IMPTypes_h */
