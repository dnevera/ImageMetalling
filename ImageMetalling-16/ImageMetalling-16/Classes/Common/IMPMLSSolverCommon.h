//
//  MSLSolverCommon.hpp
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

#ifndef IMPMSLSolverCommon_h
#define IMPMSLSolverCommon_h

#ifndef __METAL_VERSION__

typedef NS_ENUM(uint, MLSSolverKind) {
    MLSSolverKindAffine     = 0,
    MLSSolverKindSimilarity = 1,
    MLSSolverKindRigid      = 2
};

#else

typedef enum : uint {
    MLSSolverKindAffine     = 0,
    MLSSolverKindSimilarity = 1,
    MLSSolverKindRigid      = 2
}MLSSolverKind;

#endif
#endif /* IMPMSLSolverCommon_h */
