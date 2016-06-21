//
//  IMPBezierWarpFilter.swift
//  ImageMetalling-13
//
//  Created by denis svinarchuk on 20.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Foundation
import IMProcessing


public extension IMPFloat2x4x4 {
    
    public subscript(i:Int,j:Int) -> float2 {
        get{
            var mem:[float2] = [float2](count:16, repeatedValue:float2(0))
            var v = vectors
            memcpy(&mem, &v, sizeofValue(vectors))
            return mem[(j%4)+4*(i%4)]
        }
        mutating set {
            var mem:[float2] = [float2](count:16, repeatedValue:float2(0))
            memcpy(&mem, &vectors, sizeofValue(vectors))
            mem[(j%4)+4*(i%4)] = newValue
            memcpy(&vectors, &mem, sizeofValue(vectors))
        }
    }
    
    public subscript(i:Int) -> float2 {
        get{
            var mem:[float2] = [float2](count:16, repeatedValue:float2(0))
            var v = vectors
            memcpy(&mem, &v, sizeofValue(vectors))
            return mem[i%16]
        }
        mutating set {
            var mem:[float2] = [float2](count:16, repeatedValue:float2(0))
            memcpy(&mem, &vectors, sizeofValue(vectors))
            mem[i%16] = newValue
            memcpy(&vectors, &mem, sizeofValue(vectors))
        }
    }

    public func lerp(final final:IMPFloat2x4x4, t:Float) -> IMPFloat2x4x4 {
        var result = IMPFloat2x4x4()
        for i in 0..<4 {
            for j in 0..<4 {
                result[i,j] = self[i,j].lerp(final: final[i,j], t: t)
            }
        }
        return result
    }
}

public class IMLTBezierWarpFilter: IMPTransformFilter {
    
    public var points = IMPFloat2x4x4() {
        didSet{
            controlPoints = IMLTBezierWarpFilter.baseControlPoints

            for i in 0..<4 {
                for j in 0..<4 {
                    controlPoints[i,j] += points[i,j]
                }
            }

            memcpy(buffer.contents(), &controlPoints, buffer.length)
            dirty = true
        }
    }
    
    public static let baseControlPoints = IMPFloat2x4x4(vectors: (
        (float2(0,0),   float2(1/3,0),   float2(2/3,0),   float2(1, 0)),
        (float2(0,1/3), float2(1/3,1/3), float2(2/3,1/3), float2(1, 1/3)),
        (float2(0,2/3), float2(1/3,2/3), float2(2/3,2/3), float2(1, 2/3)),
        (float2(0,1),   float2(1/3,1),   float2(2/3,1),   float2(1, 1)))
    )
    
    var controlPoints:IMPFloat2x4x4 = IMLTBezierWarpFilter.baseControlPoints
    
    override public var backgroundColor: IMPColor {
        didSet{
            var c = backgroundColor.rgba
            memcpy(bgColorBuffer.contents(), &c, bgColorBuffer.length)
            dirty = true
        }
    }
    
    public required init(context: IMPContext) {
        super.init(context: context)
        addGraphics(graphics)
    }
    
    private lazy var graphics:IMPGraphics = IMPGraphics(context: self.context, fragment: "fragment_bezierWarpTransformation")

    override public func configureGraphics(graphics: IMPGraphics, command: MTLRenderCommandEncoder) {
        if graphics == self.graphics {
            command.setFragmentBuffer(buffer, offset: 0, atIndex: 0)
            command.setFragmentBuffer(bgColorBuffer, offset: 0, atIndex: 1)
        }
    }

    lazy var bgColorBuffer:MTLBuffer = self.context.device.newBufferWithLength(sizeof(float4),
                                                                         options: .CPUCacheModeDefaultCache)

    lazy var buffer:MTLBuffer = self.context.device.newBufferWithBytes(&self.controlPoints,
                                                                       length: sizeof(IMPFloat2x4x4),
                                                                       options: .CPUCacheModeDefaultCache)
}
