//
//  MSLSolverBridge.m
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

#import "IMPMLSSolverBridge.h"
#import "IMPMLSSolver.h"
#import "IMPMLSSolver3D.h"
#import "IMPConstants-Bridging-Metal.h"

@implementation IMPMLSSolverBridge
{
    IMPMLSSolver *solver;
}
-(instancetype) initWith:(float2)point source:(float2 *)source destination:(float2 *)destination count:(int)count kind:(MLSSolverKind)kind alpha:(float)alpha {
    
    self = [super init];
    
    if (self) {
        solver = new IMPMLSSolver(point,source,destination,count,kind,alpha);
    }
    
    return self;
}

- (simd_float2) value:(simd_float2)point {
    return solver->value(point);
}

- (void) dealloc {
    delete solver;
}

@end

@implementation IMPMLSSolverBridge3D
{
    IMPMLSSolver3D *solver;
}
-(instancetype) initWith:(float3)point source:(float3 *)source destination:(float3 *)destination count:(int)count kind:(MLSSolverKind)kind alpha:(float)alpha {
    
    self = [super init];
    
    if (self) {
        solver = new IMPMLSSolver3D(point,source,destination,count,kind,alpha);
    }
    
    return self;
}

- (simd_float3) value:(simd_float3)point {
    return solver->value(point);
}

- (void) dealloc {
    delete solver;
}

@end

