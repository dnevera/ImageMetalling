//
//  IMPGridGenerator.swift
//  ImageMetalling-12
//
//  Created by denis svinarchuk on 16.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Foundation
import IMProcessing


/// Photo plate transformation filter
public class IMPGridGenerator: IMPTransformFilter {
    
    public struct Adjustment{
        public var step         = uint(50)             // step point
        public var color        = float4(1)            // color
        public var subDivisionStep   = uint(4)         // sub division grid
        public var subDivisionColor  = float4(0,0,0,1) // sub division color
    }
    
    public var adjustment = Adjustment() {
        didSet{
            memcpy(bufferStep.contents(), &adjustment.step, bufferStep.length)
            memcpy(bufferSDiv.contents(), &adjustment.subDivisionStep, bufferStep.length)
            memcpy(bufferColor.contents(), &adjustment.color, bufferColor.length)
            memcpy(bufferSDivColor.contents(), &adjustment.subDivisionColor, bufferSDivColor.length)
            dirty = true
        }
    }
    
    convenience public required init(context: IMPContext) {
        self.init(context: context, vertex: "vertex_transformation", fragment: "fragment_gridGenerator")
    }
    
    override public func configureGraphics(graphics: IMPGraphics, command: MTLRenderCommandEncoder) {
        if graphics == self.graphics {
            command.setFragmentBuffer(bufferStep, offset: 0, atIndex: 0)
            command.setFragmentBuffer(bufferSDiv, offset: 0, atIndex: 1)
            command.setFragmentBuffer(bufferColor, offset: 0, atIndex: 2)
            command.setFragmentBuffer(bufferSDivColor, offset: 0, atIndex: 3)
        }
    }
    
    lazy var bufferStep:MTLBuffer = self.context.device.newBufferWithBytes(&self.adjustment.step, length: sizeof(Int), options: .CPUCacheModeDefaultCache)
    lazy var bufferSDiv:MTLBuffer = self.context.device.newBufferWithBytes(&self.adjustment.subDivisionStep, length: sizeof(Int), options: .CPUCacheModeDefaultCache)
    lazy var bufferColor:MTLBuffer = self.context.device.newBufferWithBytes(&self.adjustment.color, length: sizeof(float4), options: .CPUCacheModeDefaultCache)
    lazy var bufferSDivColor:MTLBuffer = self.context.device.newBufferWithBytes(&self.adjustment.subDivisionColor, length: sizeof(float4), options: .CPUCacheModeDefaultCache)
}