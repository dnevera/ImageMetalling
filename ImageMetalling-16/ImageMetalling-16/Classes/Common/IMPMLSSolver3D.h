//
//  _MSLSolver.hpp
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

#ifndef ___IMPMSLSolver3D_hpp
#define ___IMPMSLSolver3D_hpp

#ifdef __cplusplus

#include <simd/simd.h>

#ifdef __METAL_VERSION__
#define MLS_MAXIMUM_POINTS 4096
#else
#import <Foundation/Foundation.h>
#endif

#include "IMPMatrixExtension.h"
#include "IMPMLSSolverCommon.h"
#include "IMPConstants-Bridging-Metal.h"

using namespace simd;

static inline float3 __slashReflect(float3 point) {
    return (float3){-point.y, point.x, point.z};
}

class IMPMLSSolver3D{
    
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
    IMPMLSSolver3D(const float3 point, 
#ifndef __METAL_VERSION__              
              const float3 *p, 
              const float3 *q,
#else
              constant float3 *p, 
              constant float3 *q,
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
        pHat_ = new float3[count_];   
        qHat_ = new float3[count_];   
#endif
        
        solveW();
        solveStars();
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
    float3 value(float3 point) {
        if (count_ <= 0) return point;   
        return (point - pStar_) * M + qStar_;    
    }
    
    ~IMPMLSSolver3D() {
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
    float3  point_;
#ifndef __METAL_VERSION__              
    const float3 *p_;
    const float3 *q_;
    float *w_;
    float3 *pHat_;
    float3 *qHat_;    
#else
    constant float3 *p_;
    constant float3 *q_;
    thread float w_[MLS_MAXIMUM_POINTS];
    thread float3 pHat_[MLS_MAXIMUM_POINTS];
    thread float3 qHat_[MLS_MAXIMUM_POINTS];
#endif
    
    float weight_;
    float3 pStar_;
    float3 qStar_;
    float mu_;
    
    float3x3 M;
    
    void solveW() {
        
        weight_ = 0;
        
        for (int i=0; i<count_; i++) {
            
            float d =  pow(distance(p_[i], point_), 2*alpha_);
            
            if (d < FLT_EPSILON)  d = FLT_EPSILON; 
            
            w_[i] = 1.0 / d;
            weight_ = weight_ + w_[i];
        }
        
        if (weight_ < FLT_EPSILON)  weight_ = FLT_EPSILON;
    }  
    
    void solveStars() {
        pStar_ = float3(0);
        qStar_ = float3(0);
        
        for (int i=0; i<count_; i++) {
            pStar_ += w_[i] * p_[i];
            qStar_ += w_[i] * q_[i];
        }
        
        pStar_ = pStar_ / weight_;                
        qStar_ = qStar_ / weight_;
    }
    
    void solveHat(){        
        
        mu_ = 0;
        
        float _rmu1 = 0;
        float _rmu2 = 0;
        
        for (int i=0; i<count_; i++) {
            
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
    
    float3x3 affineMj() {
        float3x3 m = (float3x3){(float3){0,0},(float3){0,0},(float3){0,0}};
        
        for (int i=0; i<count_; i++) {
            
            float3x3 pt({
                w_[i] * pHat_[i], 
                float3(0)                
            });
            
            float3x3 qp({
                (float3){qHat_[i].x, 0.0}, 
                (float3){qHat_[i].y, 0.0}                
            });
            
            m = m + (float3x3)(pt * qp);
        }
        return m;
    }
    
    float3x3 affineMi() {
        float3x3 m = (float3x3){(float3){0,0},(float3){0,0},(float3){0,0}};
        
        for (int i=0; i<count_; i++) {
            
            float3x3 pt({
                pHat_[i], 
                float3(0)                
            });
            
            float3x3 pp({
                (float3){w_[i] * pHat_[i].x, 0.0}, 
                (float3){w_[i] * pHat_[i].y, 0.0}                
            });
            
            m = m + (float3x3)(pt * pp);
        }        
        return m;
    }
    
    float3x3 affineM() {
        return inverse(affineMi()) * affineMj();
    }
    
    float similarityMu(int i)  {
        return w_[i]*dot(pHat_[i], pHat_[i]);
    }
    
    float3x3 similarityM(float3 value) {
        
        float3x3 m = (float3x3){(float3){0,0},(float3){0,0},(float3){0,0}};
        
        for (int i=0; i<count_; i++) {
            
            float3 sp = -1 * __slashReflect(pHat_[i]);
            float3 sq = -1 * __slashReflect(qHat_[i]);
            
            float3x3 _p({
                (float3){w_[i] * pHat_[i].x, w_[i] * sp.x}, 
                (float3){w_[i] * pHat_[i].y, w_[i] * sp.y}                
            });
            
            float3x3 _q({qHat_[i], sq});
                        
            m = m + (float3x3)(_p * _q);
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

#endif /* ___IMPMSLSolver3D_hpp */
