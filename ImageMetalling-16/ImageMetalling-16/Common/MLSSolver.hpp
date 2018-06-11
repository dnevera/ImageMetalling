//
//  _MSLSolver.hpp
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

#ifndef ___MSLSolver_hpp
#define ___MSLSolver_hpp

#ifdef __cplusplus

#ifdef __METAL_VERSION__

#include <simd/simd.h>

#define MLS_MAXIMUM_POINTS 1024

#else

#import <Foundation/Foundation.h>
#include <simd/simd.h>
using namespace simd;
#endif

#include "MLSSolverCommon.h"
#include "IMPConstants-Bridging-Metal.h"

class MLSSolver{

public:
    
    
    /**
     Create Mean least square solver

     @param point current point solve for 
     @param p source control points 
     @param q destination control points
     @param count count of control points
     @param kind kind of solver
     @param alpha degree of deforamtion
     */
    MLSSolver(const float2 point, 
#ifndef __METAL_VERSION__              
              const float2 *p, 
              const float2 *q,
#else
              constant float2 *p, 
              constant float2 *q,
#endif
              const int count, 
              const MLSSolverKind kind = MLSSolverKindAffine, 
              const float alpha = 1.0): 
    point_(point),
    kind_(kind), 
    alpha_(alpha), 
    p_(p), q_(q),
    weight(0)
    {    
#ifndef __METAL_VERSION__
        w_ = new float[count_];   
        pHat_ = new float2[count_];   
        qHat_ = new float2[count_];   
#endif
        
        solveW();
    }    
    
    float2 value(float2 point) {
        return point;
    }
    
    ~MLSSolver() {
#ifndef __METAL_VERSION__
        delete w_;
        delete pHat_;
        delete qHat_;
#endif
    }
    
private:
    
    MLSSolverKind kind_;
    float   alpha_;
    int     count_;
    float2  point_;
#ifndef __METAL_VERSION__              
    const float2 *p_;
    const float2 *q_;
    float *w_;
    float2 *pHat_;
    float2 *qHat_;    
#else
    constant float2 *p_;
    constant float2 *q_;
    thread float w_[MLS_MAXIMUM_POINTS];
    thread float2 pHat_[MLS_MAXIMUM_POINTS];
    thread float2 qHat_[MLS_MAXIMUM_POINTS];
#endif
    
    float weight;
        
    void solveW() {
                
        weight = 0;
        
        for (int i=0; i<count_; i++) {
            
            float d =  pow(distance(p_[i], point_), 2*alpha_);
            
            if (d < FLT_EPSILON)  d = FLT_EPSILON; 
            
            w_[i] = 1.0 / d;
            weight = weight + w_[i];
        }
        
        if (weight < FLT_EPSILON)  weight = FLT_EPSILON;
    }    
    
};

#endif /* __cplusplus */

#endif /* ___MSLSolver_hpp */
