//
//  ViewController.swift
//  ImageMetalling-02
//
//  Created by denis svinarchuk on 31.10.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

import UIKit

class DPCustomFilter: DPFilter {
    
    var adjustment:Float=0{
        didSet(oldValue){
            adjustmentUniform = adjustmentUniform ?? self.context.device.newBufferWithLength(sizeof(Float), options: MTLResourceOptions.CPUCacheModeDefaultCache)
            memcpy(adjustmentUniform.contents(), &adjustment, sizeof(Float))
        }
    }
    
    private var kernelFunction:DPFunction!=nil
    private var adjustmentUniform:MTLBuffer!=nil
    
    required init!(context aContext: DPContext!) {
        
        super.init(context: aContext)
        
        if let actualKernelFunction = DPFunction(functionName: "kernel_adjustCustom", context: self.context){
            kernelFunction = actualKernelFunction
            self.addFunction(kernelFunction)
        }
        else{
            NSLog(" *** error load kernel_adjustSaturation function...")
        }
    }
    
    override func configureFunction(function: DPFunction!, uniform commandEncoder: MTLComputeCommandEncoder!) {
        if function == kernelFunction{
            commandEncoder.setBuffer(adjustmentUniform, offset: 0, atIndex: 0)
        }
    }

}

class ViewController: UIViewController, DPFilterProtocol {

    var liveView:UIView!=nil
    
    var camera:DPCameraManager!=nil

    var exposureFilter:DPExposureFilter!=nil
    
    var customFilter:DPCustomFilter!=nil
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        camera.start()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        camera.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        liveView = UIView(frame: CGRectMake( 0, 20,
            self.view.bounds.size.width,
            self.view.bounds.size.height*3/4
            ));
        self.view .addSubview(liveView)
    
        camera = DPCameraManager(outputContainerPreview: liveView)
        
        exposureFilter = DPExposureFilter(context: DPContext.newLazyContext())
        exposureFilter.adjustment.exposure = 0.5
        exposureFilter.adjustment.blending.mode = Int32(DP_BLENDING_LUMINOSITY.rawValue)
        
        customFilter = DPCustomFilter(context: exposureFilter.context)
        customFilter.adjustment = 0.5
        
        exposureFilter.addFilter(customFilter)
        
        camera.liveViewFilter = exposureFilter
    }
    
}

