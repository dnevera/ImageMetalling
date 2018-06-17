//
//  IMPMatrixExtension.hpp
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 16.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

#ifndef IMPMatrixExtension_hpp
#define IMPMatrixExtension_hpp

#ifdef __cplusplus
#include <simd/simd.h>

#ifndef __METAL_VERSION__ 
#import <Foundation/Foundation.h>
#endif

using namespace simd;

#ifdef __METAL_VERSION__
//
// https://github.com/niswegmann/small-matrix-inverse
//
template <typename T>
METAL_FUNC matrix<T,2,2> inverse(const matrix<T,2,2> __src) 
{    
    float src[4] = {
        __src[0][0],__src[0][1],
        __src[1][0],__src[1][1]        
    };
    
    float dst[4];
    
    /* Compute adjoint: */
    
    dst[0] = + src[3];
    dst[1] = - src[1];
    dst[2] = - src[2];
    dst[3] = + src[0];
    
    /* Compute inverted determinant: */
    
    float det = 1.0f / determinant(__src);
    
    dst[0] *= det;
    dst[1] *= det;
    dst[2] *= det;
    dst[3] *= det;
    
    return (matrix<T,2,2>){
        (vec<T,2>){dst[0],dst[1]},
        (vec<T,2>){dst[2],dst[3]}        
    };
}

template <typename T>
METAL_FUNC matrix<T,3,3> inverse(const matrix<T,3,3> __src)
{
    float src[9] = {
        __src[0][0],__src[0][1],__src[0][2],
        __src[1][0],__src[1][1],__src[1][2],
        __src[2][0],__src[2][1],__src[2][2]
    };
    float dst[9];

    /* Compute adjoint: */
    
    dst[0] = + src[4] * src[8] - src[5] * src[7];
    dst[1] = - src[1] * src[8] + src[2] * src[7];
    dst[2] = + src[1] * src[5] - src[2] * src[4];
    dst[3] = - src[3] * src[8] + src[5] * src[6];
    dst[4] = + src[0] * src[8] - src[2] * src[6];
    dst[5] = - src[0] * src[5] + src[2] * src[3];
    dst[6] = + src[3] * src[7] - src[4] * src[6];
    dst[7] = - src[0] * src[7] + src[1] * src[6];
    dst[8] = + src[0] * src[4] - src[1] * src[3];
    
    /* Compute determinant: */
    
    float det = 1.0f / determinant(__src);
    
    dst[0] *= det;
    dst[1] *= det;
    dst[2] *= det;
    dst[3] *= det;
    dst[4] *= det;
    dst[5] *= det;
    dst[6] *= det;
    dst[7] *= det;
    dst[8] *= det;
    
    return (matrix<T,3,3>){
        (vec<T,3>){dst[0],dst[1],dst[2]},
        (vec<T,3>){dst[3],dst[4],dst[5]},        
        (vec<T,3>){dst[6],dst[7],dst[7]},        
    };
}

template <typename T>
static inline matrix<T,4,4> invert4x4(const matrix<T,4,4> __src)
{
    float src[16] = {
        __src[0][0],__src[0][1],__src[0][2],__src[0][3],
        __src[1][0],__src[1][1],__src[1][2],__src[1][3],
        __src[2][0],__src[2][1],__src[2][2],__src[2][3],
        __src[3][0],__src[3][1],__src[3][2],__src[3][3]
    };
    float dst[16];
    
    /* Compute adjoint: */
    
    dst[0] =
    + src[ 5] * src[10] * src[15]
    - src[ 5] * src[11] * src[14]
    - src[ 9] * src[ 6] * src[15]
    + src[ 9] * src[ 7] * src[14]
    + src[13] * src[ 6] * src[11]
    - src[13] * src[ 7] * src[10];
    
    dst[1] =
    - src[ 1] * src[10] * src[15]
    + src[ 1] * src[11] * src[14]
    + src[ 9] * src[ 2] * src[15]
    - src[ 9] * src[ 3] * src[14]
    - src[13] * src[ 2] * src[11]
    + src[13] * src[ 3] * src[10];
    
    dst[2] =
    + src[ 1] * src[ 6] * src[15]
    - src[ 1] * src[ 7] * src[14]
    - src[ 5] * src[ 2] * src[15]
    + src[ 5] * src[ 3] * src[14]
    + src[13] * src[ 2] * src[ 7]
    - src[13] * src[ 3] * src[ 6];
    
    dst[3] =
    - src[ 1] * src[ 6] * src[11]
    + src[ 1] * src[ 7] * src[10]
    + src[ 5] * src[ 2] * src[11]
    - src[ 5] * src[ 3] * src[10]
    - src[ 9] * src[ 2] * src[ 7]
    + src[ 9] * src[ 3] * src[ 6];
    
    dst[4] =
    - src[ 4] * src[10] * src[15]
    + src[ 4] * src[11] * src[14]
    + src[ 8] * src[ 6] * src[15]
    - src[ 8] * src[ 7] * src[14]
    - src[12] * src[ 6] * src[11]
    + src[12] * src[ 7] * src[10];
    
    dst[5] =
    + src[ 0] * src[10] * src[15]
    - src[ 0] * src[11] * src[14]
    - src[ 8] * src[ 2] * src[15]
    + src[ 8] * src[ 3] * src[14]
    + src[12] * src[ 2] * src[11]
    - src[12] * src[ 3] * src[10];
    
    dst[6] =
    - src[ 0] * src[ 6] * src[15]
    + src[ 0] * src[ 7] * src[14]
    + src[ 4] * src[ 2] * src[15]
    - src[ 4] * src[ 3] * src[14]
    - src[12] * src[ 2] * src[ 7]
    + src[12] * src[ 3] * src[ 6];
    
    dst[7] =
    + src[ 0] * src[ 6] * src[11]
    - src[ 0] * src[ 7] * src[10]
    - src[ 4] * src[ 2] * src[11]
    + src[ 4] * src[ 3] * src[10]
    + src[ 8] * src[ 2] * src[ 7]
    - src[ 8] * src[ 3] * src[ 6];
    
    dst[8] =
    + src[ 4] * src[ 9] * src[15]
    - src[ 4] * src[11] * src[13]
    - src[ 8] * src[ 5] * src[15]
    + src[ 8] * src[ 7] * src[13]
    + src[12] * src[ 5] * src[11]
    - src[12] * src[ 7] * src[ 9];
    
    dst[9] =
    - src[ 0] * src[ 9] * src[15]
    + src[ 0] * src[11] * src[13]
    + src[ 8] * src[ 1] * src[15]
    - src[ 8] * src[ 3] * src[13]
    - src[12] * src[ 1] * src[11]
    + src[12] * src[ 3] * src[ 9];
    
    dst[10] =
    + src[ 0] * src[ 5] * src[15]
    - src[ 0] * src[ 7] * src[13]
    - src[ 4] * src[ 1] * src[15]
    + src[ 4] * src[ 3] * src[13]
    + src[12] * src[ 1] * src[ 7]
    - src[12] * src[ 3] * src[ 5];
    
    dst[11] =
    - src[ 0] * src[ 5] * src[11]
    + src[ 0] * src[ 7] * src[ 9]
    + src[ 4] * src[ 1] * src[11]
    - src[ 4] * src[ 3] * src[ 9]
    - src[ 8] * src[ 1] * src[ 7]
    + src[ 8] * src[ 3] * src[ 5];
    
    dst[12] =
    - src[ 4] * src[ 9] * src[14]
    + src[ 4] * src[10] * src[13]
    + src[ 8] * src[ 5] * src[14]
    - src[ 8] * src[ 6] * src[13]
    - src[12] * src[ 5] * src[10]
    + src[12] * src[ 6] * src[ 9];
    
    dst[13] =
    + src[ 0] * src[ 9] * src[14]
    - src[ 0] * src[10] * src[13]
    - src[ 8] * src[ 1] * src[14]
    + src[ 8] * src[ 2] * src[13]
    + src[12] * src[ 1] * src[10]
    - src[12] * src[ 2] * src[ 9];
    
    dst[14] =
    - src[ 0] * src[ 5] * src[14]
    + src[ 0] * src[ 6] * src[13]
    + src[ 4] * src[ 1] * src[14]
    - src[ 4] * src[ 2] * src[13]
    - src[12] * src[ 1] * src[ 6]
    + src[12] * src[ 2] * src[ 5];
    
    dst[15] =
    + src[ 0] * src[ 5] * src[10]
    - src[ 0] * src[ 6] * src[ 9]
    - src[ 4] * src[ 1] * src[10]
    + src[ 4] * src[ 2] * src[ 9]
    + src[ 8] * src[ 1] * src[ 6]
    - src[ 8] * src[ 2] * src[ 5];
    
    /* Compute determinant: */
    
    float det = 1.0f / determinant(__src);
    
    
    dst[ 0] *= det;
    dst[ 1] *= det;
    dst[ 2] *= det;
    dst[ 3] *= det;
    dst[ 4] *= det;
    dst[ 5] *= det;
    dst[ 6] *= det;
    dst[ 7] *= det;
    dst[ 8] *= det;
    dst[ 9] *= det;
    dst[10] *= det;
    dst[11] *= det;
    dst[12] *= det;
    dst[13] *= det;
    dst[14] *= det;
    dst[15] *= det;
    
    return (matrix<T,4,4>){
        (vec<T,4>){dst[0],dst[1],dst[2],dst[3]},
        (vec<T,4>){dst[4],dst[5],dst[6],dst[7]},        
        (vec<T,4>){dst[8],dst[8],dst[10],dst[11]},        
        (vec<T,4>){dst[12],dst[13],dst[14],dst[15]},        
    };
}

#endif

#endif //__cplusplus

#endif /* IMPMatrixExtension_hpp */
