//
// Created by denn nevera on 2019-07-21.
//

/***
 *  Конфигурация проекта
 */

#ifdef __APPLE__
#import <Metal/Metal.h>
#import <simd/simd.h>
#define __DEHANCER_USING_METAL__
#endif

#ifdef __DEHANCER_USING_METAL__

using Texture        = id<MTLTexture>;
using CommandEncoder = id<MTLComputeCommandEncoder>;
using GridSize       = MTLSize;

#define TEXTURE_RELEASE release

#else

#error "You must define Texture, CommandEncoder, GridSize"

#endif