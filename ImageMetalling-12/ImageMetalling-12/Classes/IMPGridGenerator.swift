//
//  IMPGridGenerator.swift
//  ImageMetalling-12
//
//  Created by denis svinarchuk on 16.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Foundation
import IMProcessing


public class IMPGridGenerator: IMPTransformFilter {
    
    public struct Adjustment{
        public var step              = uint(50)           // step point
        public var color             = float4(1)          // color
        public var subDivisionStep   = uint(4)            // sub division grid
        public var subDivisionColor  = float4(0,0,0,1)    // sub division color
        public var spotAreaColor     = float4(1,1,1,0.8)  // light spot area color
        public var spotArea          = IMPRegion.null     // light spot area
    }
    
    public var adjustment = Adjustment() {
        didSet{
            memcpy(bufferStep.contents(), &adjustment.step, bufferStep.length)
            memcpy(bufferSDiv.contents(), &adjustment.subDivisionStep, bufferStep.length)
            memcpy(bufferColor.contents(), &adjustment.color, bufferColor.length)
            memcpy(bufferSDivColor.contents(), &adjustment.subDivisionColor, bufferSDivColor.length)
            memcpy(bufferSpotAreaColor.contents(), &adjustment.spotAreaColor, bufferSpotAreaColor.length)
            memcpy(bufferSpotArea.contents(), &adjustment.spotArea, bufferSpotArea.length)
            dirty = true
        }
    }
    
    convenience public required init(context: IMPContext) {
        self.init(context: context, vertex: "vertex_transformation", fragment: "fragment_gridGenerator")
    }
    
    override public func configureGraphics(graphics: IMPGraphics, command: MTLRenderCommandEncoder) {
        if graphics == self.graphics {
            command.setFragmentBuffers(buffers, offsets: bufferOffset, withRange: NSMakeRange(0, buffers.count))
        }
    }
    
    lazy var buffers:[MTLBuffer?] = {
        var array = [MTLBuffer?]()
        array.append(self.bufferStep)
        array.append(self.bufferSDiv)
        array.append(self.bufferColor)
        array.append(self.bufferSDivColor)
        array.append(self.bufferSpotAreaColor)
        array.append(self.bufferSpotArea)
        return array
    }()
    
    lazy var bufferOffset:[Int] = [Int](count: self.buffers.count, repeatedValue: 0)
    
    lazy var bufferStep:MTLBuffer = self.context.device.newBufferWithBytes(&self.adjustment.step,
                                                                           length: sizeof(Int),
                                                                           options: .CPUCacheModeDefaultCache)
    
    lazy var bufferSDiv:MTLBuffer = self.context.device.newBufferWithBytes(&self.adjustment.subDivisionStep,
                                                                           length: sizeof(Int),
                                                                           options: .CPUCacheModeDefaultCache)
    
    lazy var bufferColor:MTLBuffer = self.context.device.newBufferWithBytes(&self.adjustment.color,
                                                                            length: sizeof(float4),
                                                                            options: .CPUCacheModeDefaultCache)
    
    lazy var bufferSDivColor:MTLBuffer = self.context.device.newBufferWithBytes(&self.adjustment.subDivisionColor,
                                                                                length: sizeof(float4),
                                                                                options: .CPUCacheModeDefaultCache)
    lazy var bufferSpotAreaColor:MTLBuffer = self.context.device.newBufferWithBytes(&self.adjustment.spotAreaColor,
                                                                               length: sizeof(float4),
                                                                               options: .CPUCacheModeDefaultCache)
    lazy var bufferSpotArea:MTLBuffer = self.context.device.newBufferWithBytes(&self.adjustment.spotArea,
                                                                               length: sizeof(IMPRegion),
                                                                               options: .CPUCacheModeDefaultCache)

}