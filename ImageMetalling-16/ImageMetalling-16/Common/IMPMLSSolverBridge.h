//
//  MSLSolverBridge.h
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPMLSSolverCommon.h"
#import <simd/simd.h>

@interface IMPMLSSolverBridge : NSObject
- (instancetype) initWith:(simd_float2)point 
                  source:(simd_float2*)source 
             destination:(simd_float2*)destination 
                   count:(int)count 
                    kind:(MLSSolverKind)kind alpha:(float)alpha;
- (simd_float2) value:(simd_float2)point;
@end
