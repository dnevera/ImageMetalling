//
//  IMPContrastFilter.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 19.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

class IMPContrastFilter:IMPFilter,IMPAdjustmentProtocol{
    
    static let defaultAdjustment = IMPContrastAdjustment(
        minimum: float4([0,0,0,0]),
        maximum: float4([1,1,1,1]),
        blending: IMPBlending(mode: IMPBlendingMode.LUMNINOSITY, opacity: 1))
    
    var adjustment:IMPContrastAdjustment!{
        didSet{
            self.updateBuffer(&adjustmentBuffer, context:context, adjustment:&adjustment, size:sizeof(IMPContrastAdjustment))
            self.dirty = true
        }
    }
    
    internal var adjustmentBuffer:MTLBuffer?
    internal var kernel:IMPFunction!
    
    required init(context: IMPContext) {
        super.init(context: context)
        kernel = IMPFunction(context: self.context, name: "kernel_adjustContrast")
        self.addFunction(kernel)
        defer{
            self.adjustment = IMPContrastFilter.defaultAdjustment
        }
    }
    
    override func configure(function: IMPFunction, command: MTLComputeCommandEncoder) {
        if kernel == function {
            command.setBuffer(adjustmentBuffer, offset: 0, atIndex: 0)
        }
    }
}