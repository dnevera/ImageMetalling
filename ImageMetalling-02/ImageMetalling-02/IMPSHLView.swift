//
//  IMPView.swift
//  ImageMetalling-02
//
//  Created by denis svinarchuk on 27.10.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

import UIKit
import Metal
import MetalKit

///
/// Параметризация фильтра
///
struct IMPShadowsHighLights {

    ///
    /// Степень фильтрации
    ///
    var level:Float;
    
    /// float3 - тип данных экспортируемых из Metal Framework
    /// .x - вес светов/теней 0-1
    /// .y - тональная ширины светов/теней над которыми производим операцию >0-1
    /// .w - степень подъема/наклона кривой воздействия [1-5]
    ///

    var shadows:float3;
    var highlights:float3;
};


/**
 * Представление результатов обработки картинки в GCD.
 */
class IMPSHLView: UIView {

    private func updateUniform(){

        var shadows:IMPShadowsHighLights = IMPShadowsHighLights(
            level: level,
            shadows: float3(1, shadowsWidth, 1),
            highlights: float3(1, highlightsWidth, 1)
        )

        shadowsHighlightslUniform = shadowsHighlightslUniform ??
            self.device.newBufferWithLength(sizeof(IMPShadowsHighLights),
                options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        memcpy(shadowsHighlightslUniform.contents(), &shadows, sizeof(IMPShadowsHighLights))
    }
    
    var level:Float!{
        didSet(oldValue){
            updateUniform()
        }
    }
    
    var shadowsWidth:Float!{
        didSet(oldValue){
            if shadowsWidth<0.01 {
                shadowsWidth=0.01
            }
            else if shadowsWidth>1 {
                shadowsWidth=1
            }
            updateUniform()
        }
    }
    
    
    var highlightsWidth:Float!{
        didSet(oldValue){
            if highlightsWidth<0.01 {
                highlightsWidth=0.01
            }
            else if highlightsWidth>1 {
                highlightsWidth=1
            }
            updateUniform()
        }
    }
    

    private var shadowsHighlightslUniform:MTLBuffer!=nil
    private let device:MTLDevice! = MTLCreateSystemDefaultDevice()
    private var commandQueue:MTLCommandQueue!=nil
    private var metalView:MTKView!=nil
    private var imageTexture:MTLTexture!=nil
    private var pipeline:MTLComputePipelineState!=nil
    private let threadGroupCount = MTLSizeMake(8, 8, 1)
    private var threadGroups:MTLSize?
    
    func loadImage(file: String){
        autoreleasepool {
            let textureLoader = MTKTextureLoader(device: self.device!)
            if let image = UIImage(named: file){
                imageTexture = try! textureLoader.newTextureWithCGImage(image.CGImage!, options: nil)
                threadGroups = MTLSizeMake(
                    (imageTexture.width+threadGroupCount.width)/threadGroupCount.width,
                    (imageTexture.height+threadGroupCount.height)/threadGroupCount.height, 1)
            }
        }        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        metalView = MTKView(frame: self.bounds, device: self.device)
        metalView.autoResizeDrawable = true
        metalView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        metalView.layer.transform = CATransform3DMakeRotation(CGFloat(M_PI),1.0,0.0,0.0)
        self.addSubview(metalView)
        
        let scaleFactor:CGFloat! = metalView.contentScaleFactor
        metalView.drawableSize = CGSizeMake(self.bounds.width*scaleFactor, self.bounds.height*scaleFactor)
        
        commandQueue = device.newCommandQueue()
        
        let library:MTLLibrary!  = self.device.newDefaultLibrary()
        
        let function:MTLFunction! = library.newFunctionWithName("kernel_adjustSHL")
        
        pipeline = try! self.device.newComputePipelineStateWithFunction(function)
        
        level = 1
        shadowsWidth = 1        
        highlightsWidth = 1
        
        updateUniform()
    }
    
    func refresh(){
        
        if let actualImageTexture = imageTexture{
            
            let commandBuffer = commandQueue.commandBuffer()
            let encoder = commandBuffer.computeCommandEncoder()

            encoder.setComputePipelineState(pipeline)
            encoder.setTexture(actualImageTexture, atIndex: 0)
            encoder.setTexture(metalView.currentDrawable!.texture, atIndex: 1)
            encoder.setBuffer(self.shadowsHighlightslUniform, offset: 0, atIndex: 0)
            encoder.dispatchThreadgroups(threadGroups!, threadsPerThreadgroup: threadGroupCount)
            encoder.endEncoding()

            commandBuffer.presentDrawable(metalView.currentDrawable!)
            commandBuffer.commit()
        }
    }
}
