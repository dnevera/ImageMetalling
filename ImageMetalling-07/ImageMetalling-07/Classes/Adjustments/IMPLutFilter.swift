//
//  IMPLutFilter.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 20.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

class IMPLutFilter: IMPFilter, IMPAdjustmentProtocol {
    static let defaultAdjustment = IMPAdjustment(blending: IMPBlending(mode: IMPBlendingMode.NORMAL, opacity: 1))
    
    var adjustment:IMPAdjustment!{
        didSet{
            self.updateBuffer(&adjustmentBuffer, context:context, adjustment:&adjustment, size:sizeof(IMPAdjustment))
            self.dirty = true
        }
    }
    
    internal var adjustmentBuffer:MTLBuffer?
    internal var kernel:IMPFunction!
    internal var lut:IMPImageProvider?
    internal var lutDescription = IMPImageProvider.lutDescription()
    
    required init(context: IMPContext, lut:IMPImageProvider, description:IMPImageProvider.lutDescription) {
        
        super.init(context: context)

        updateLut(lut, description: description)
        
        defer{
            self.adjustment = IMPLutFilter.defaultAdjustment
        }
    }
    
    required init(context: IMPContext) {
        fatalError("init(context:) has not been implemented, IMPLutFilter(context: IMPContext, lut:IMPImageProvider, description:IMPImageProvider.lutDescription) should be used instead...")
    }
    
    func updateLut(lut:IMPImageProvider, description:IMPImageProvider.lutDescription){
        var name = "kernel_adjustLut"
        
        if description.type == .D1D {
            name += "D1D"
        }
        else if description.type == .D3D {
            name += "D3D"
        }
        
        if self.lutDescription.type != description.type  || kernel == nil {
            if kernel != nil {
                self.removeFunction(kernel)
            }
            kernel = IMPFunction(context: self.context, name: name)
            self.addFunction(kernel)
        }
        
        self.lut = lut
        self.lutDescription = description
        
        self.dirty = true
    }
    
    override func configure(function: IMPFunction, command: MTLComputeCommandEncoder) {
        if kernel == function {
            command.setTexture(lut?.texture, atIndex: 2)
            command.setBuffer(adjustmentBuffer, offset: 0, atIndex: 0)
        }
    }
}
