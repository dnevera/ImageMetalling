//
//  MSLSolverCommon.hpp
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

#ifndef MSLSolverCommon_h
#define MSLSolverCommon_h

#ifndef __METAL_VERSION__

typedef NS_ENUM(uint, MLSSolverKind) {
    MLSSolverKindAffine     = 0,
    MLSSolverKindSimilarity = 1,
    MLSSolverKindRigid      = 2
};

//# define double4 vector_double4
//# define double3 vector_double3
//# define double2 vector_double2
//
//# define double2x2 matrix_double2x2
//# define double3x3 matrix_double3x3
//# define double4x4 matrix_double4x4
//
//# define double2x3 matrix_double2x3
//# define double3x2 matrix_double3x2
//
//# define double3x4 matrix_double3x4
//# define double4x3 matrix_float4x3
//
//# define double2x4 matrix_double2x4
//# define double4x2 matrix_double4x2

#else

typedef enum : uint {
    MLSSolverKindAffine     = 0,
    MLSSolverKindSimilarity = 1,
    MLSSolverKindRigid      = 2
}MLSSolverKind;

#endif

#endif /* MSLSolverCommon_h */
