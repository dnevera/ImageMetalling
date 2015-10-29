//
//  IMPView.swift
//  ImageMetalling-00
//
//  Created by denis svinarchuk on 27.10.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

import UIKit
import Metal
import MetalKit

///
/// В этом примере обмениваемся с фильтром через определенную нами структуру.
///
struct IMPShadows {
    //
    // float4 - тип данных экспортируемых из Metal Framework
    // shadows.x - степень применения фильтра
    // shadows.y - вес тени 0-1
    // shadows.z - тональная ширины теней над которыми производим операцию >0-1
    // shadows.w - степень наклона кривой воздействия >=1-5
    //
    var shadows:float4;
};


/**
 * Представление результатов обработки картинки в GCD.
 */
class IMPSHLView: UIView {

    private func updateShadowsUniform(){

        var shadows:IMPShadows = IMPShadows(shadows: float4(shadowsLevel, 1, shadowsWidth, shadowsSlop))

        shadowsLevelUniform = shadowsLevelUniform ??
            self.device.newBufferWithLength(sizeof(IMPShadows),
                options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        memcpy(shadowsLevelUniform.contents(), &shadows, sizeof(IMPShadows))        
    }
    
    var shadowsLevel:Float!{
        didSet(oldValue){
            updateShadowsUniform()
        }
    }
    
    var shadowsWidth:Float!{
        didSet(oldValue){
            if shadowsWidth<0.1 {
                shadowsWidth=0.1
            }
            else if shadowsWidth>1 {
                shadowsWidth=1
            }
            updateShadowsUniform()
        }
    }
    
    var shadowsSlop:Float!{
        didSet(oldValue){
            if  shadowsSlop<1 {
                shadowsSlop=1
            }
            else if shadowsSlop>5 {
                shadowsSlop = 5
            }
            updateShadowsUniform()
        }
    }
    
    private var shadowsLevelUniform:MTLBuffer!=nil
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
        
        shadowsLevel = 1.0
        shadowsSlop  = 1.2
        shadowsWidth = 1
        
        updateShadowsUniform()
    }
    
    func refresh(){
        
        if let actualImageTexture = imageTexture{
            
            let commandBuffer = commandQueue.commandBuffer()
            let encoder = commandBuffer.computeCommandEncoder()

            encoder.setComputePipelineState(pipeline)
            encoder.setTexture(actualImageTexture, atIndex: 0)
            encoder.setTexture(metalView.currentDrawable!.texture, atIndex: 1)
            encoder.setBuffer(self.shadowsLevelUniform, offset: 0, atIndex: 0)
            encoder.dispatchThreadgroups(threadGroups!, threadsPerThreadgroup: threadGroupCount)
            encoder.endEncoding()

            commandBuffer.presentDrawable(metalView.currentDrawable!)
            commandBuffer.commit()
        }
    }
}
