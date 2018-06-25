//
//  _MSLSolver.hpp
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

#ifndef ___IMPMSLSolver_hpp
#define ___IMPMSLSolver_hpp

#ifdef __cplusplus

#include <simd/simd.h>

#ifdef __METAL_VERSION__
#define MLS_MAXIMUM_POINTS 512
#else
#define MLS_MAXIMUM_POINTS 4096
#import <Foundation/Foundation.h>
#endif

#include "IMPMatrixExtension.h"
#include "IMPMLSSolverCommon.h"
#include "IMPConstants-Bridging-Metal.h"

using namespace simd;

static inline float2 __slashReflect(float2 point) {
    return (float2){-point.y, point.x};
}

class IMPMLSSolver{
    
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
    IMPMLSSolver(const float2 point, 
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
    count_(count),
    weight_(0),
    p_(p), q_(q)
    {
        
#ifndef __METAL_VERSION__
        w_ = new float[count_];   
        pHat_ = new float2[count_];   
        qHat_ = new float2[count_];   
#endif
        
        solveW();
        solveHat();
        solveM();  
        
#ifndef __METAL_VERSION__
        delete pHat_;
        delete qHat_;
        pHat_=qHat_=0;
#endif
        
    }    
        
    /**
     Return new position for source point

     @param point source point
     @return new position
     */
    float2 value(float2 point) {
        if (count_ <= 0) return point;   
        return (point - pStar_) * M + qStar_;
    }
    
    ~IMPMLSSolver() {
#ifndef __METAL_VERSION__
        delete w_;
        if (pHat_) delete pHat_;
        if (qHat_) delete qHat_;
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
    
    float weight_;
    float2 pStar_;
    float2 qStar_;
    float mu_;
    
    float2x2 M;
    
    void solveW() {
        
        weight_ = 0;
        pStar_ = float2(0);
        qStar_ = float2(0);

        for (int i=0; i<count_ && i<MLS_MAXIMUM_POINTS; i++) {
            
            float d =  pow(distance(p_[i], point_), 2*alpha_);
            
            if (d < FLT_EPSILON)  d = FLT_EPSILON; 
            
            w_[i] = 1.0 / d;
            weight_ = weight_ + w_[i];
            
            pStar_ += w_[i] * p_[i];
            qStar_ += w_[i] * q_[i];

        }
        
        if (weight_ < FLT_EPSILON)  weight_ = FLT_EPSILON;
        
        pStar_ = pStar_ / weight_;                
        qStar_ = qStar_ / weight_;
    }  
    
    void solveHat(){        
        
        mu_ = 0;
        
        float _rmu1 = 0;
        float _rmu2 = 0;
        
        for (int i=0; i<count_ && i<MLS_MAXIMUM_POINTS; i++) {
            
            pHat_[i] = p_[i] - pStar_;                        
            qHat_[i] = q_[i] - qStar_;
            
            switch (kind_) {            
                case MLSSolverKindSimilarity:
                    mu_ += similarityMu(i);
                    break;                
                case MLSSolverKindRigid:
                    _rmu1 += rigidMu1(i); 
                    _rmu2 += rigidMu2(i);
                    break;
                default:
                    break;
            }
        }
        
        switch (kind_) {            
            case MLSSolverKindRigid:
                mu_ = sqrt(_rmu1*_rmu1 + _rmu2*_rmu2);
                break;
            default:
                break;
        }
        
        if (mu_ < FLT_EPSILON)  mu_ = FLT_EPSILON; 
        
        mu_ = 1/mu_;
    }
    
    void solveM() {
        switch (kind_) {
            case MLSSolverKindAffine:
                M = affineM();
                break;
            case MLSSolverKindSimilarity:
            case MLSSolverKindRigid:
                M = similarityM(point_);
                break;
        }
    }  
                   
    float2x2 affineM() {
        float2x2 mi = (float2x2){(float2){0,0},(float2){0,0}};
        float2x2 mj = (float2x2){(float2){0,0},(float2){0,0}};

        for (int i=0; i<count_ && i<MLS_MAXIMUM_POINTS; i++) {
            
            float2x2 pti({
                pHat_[i], 
                float2(0)                
            });
            
            float2x2 ppi({
                (float2){w_[i] * pHat_[i].x, 0.0}, 
                (float2){w_[i] * pHat_[i].y, 0.0}                
            });
            
            mi = mi + (float2x2)(pti * ppi);
            
            
            float2x2 ptj({
                w_[i] * pHat_[i], 
                float2(0)                
            });
            
            float2x2 qpj({
                (float2){qHat_[i].x, 0.0}, 
                (float2){qHat_[i].y, 0.0}                
            });
            
            mj = mj + (float2x2)(ptj * qpj);
        }        
        return inverse(mi) * mj;
    }
    
    
    float similarityMu(int i)  {
        return w_[i]*dot(pHat_[i], pHat_[i]);
    }
    
    float2x2 similarityM(float2 value) {
        
        float2x2 m = (float2x2){(float2){0,0},(float2){0,0}};
        
        for (int i=0; i<count_ && i<MLS_MAXIMUM_POINTS; i++) {
            
            float2 sp = -1 * __slashReflect(pHat_[i]);
            float2 sq = -1 * __slashReflect(qHat_[i]);
            
            float2x2 _p({
                (float2){w_[i] * pHat_[i].x, w_[i] * sp.x}, 
                (float2){w_[i] * pHat_[i].y, w_[i] * sp.y}                
            });
            
            float2x2 _q({qHat_[i], sq});
                        
            m = m + (float2x2)(_p * _q);
        }
        return  mu_ * m; 
    }
    
    float rigidMu1(int i) {
        return w_[i]*dot(qHat_[i], pHat_[i]);        
    }
    
    float rigidMu2(int i) {
        return w_[i]*dot(qHat_[i],  __slashReflect(pHat_[i]));        
    }
};

#endif /* __cplusplus */

#endif /* ___IMPMSLSolver_hpp */
