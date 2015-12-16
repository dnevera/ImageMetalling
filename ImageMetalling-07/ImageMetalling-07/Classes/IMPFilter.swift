//
//  IMPFilter.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import Metal

class IMPFilter: NSObject,IMPContextProvider {
    
    var context:IMPContext!
    
    var source:IMPImageProvider?{
        didSet{
            dirty = true
        }
    }
    
    var destination:IMPImageProvider?{
        get{
            
            self.apply()
            
            if let t = self.texture{
                if let d = destinationContainer{
                    d.texture=t
                }
                else{
                    destinationContainer = IMPImageProvider(context: self.context, texture: t)
                }
                return destinationContainer
            }
            return nil
        }
    }
    
    var dirty:Bool = true
    
    required init(context: IMPContext) {
        self.context = context
    }
    
    private var functionList:[IMPFunction] = [IMPFunction]()

    func addFunction(function:IMPFunction){
        if functionList.contains(function) == false {
            functionList.append(function)
        }
    }
    
    func removeFunction(function:IMPFunction){
        if let index = functionList.indexOf(function) {
            functionList.removeAtIndex(index)
        }
    }
    
    private var texture:MTLTexture?
    private var destinationContainer:IMPImageProvider?
    
    func apply(){
        if true {
            
            dirty = false
            
            if  functionList.count > 0 {
                
                if self.source?.texture == nil {
                    return
                }
                

                self.context.execute({ (commandBuffer) -> Void in

                    var inputTexture:MTLTexture! = self.source?.texture

                    for function in self.functionList {
                        
                        let width  = inputTexture.width
                        let height = inputTexture.height
                        
                        let threadgroupCounts = MTLSizeMake(function.groupSize.width, function.groupSize.height, 1);
                        let threadgroups = MTLSizeMake(
                            (width  + threadgroupCounts.width ) / threadgroupCounts.width ,
                            (height + threadgroupCounts.height) / threadgroupCounts.height,
                            1);
                        
                        if self.texture?.width != width || self.texture?.height != height {
                            let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(inputTexture.pixelFormat, width: width, height: height, mipmapped: false)
                            self.texture = self.context.device.newTextureWithDescriptor(descriptor)
                        }
                        
                        let commandEncoder = commandBuffer.computeCommandEncoder()
                        
                        commandEncoder.setComputePipelineState(function.pipeline!)
                        
                        commandEncoder.setTexture(inputTexture, atIndex:0);
                        commandEncoder.setTexture(self.texture, atIndex:1);

                        
                        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts)
                        commandEncoder.endEncoding()
                        
                        inputTexture = self.texture
                    }
                })
            }
        }
    }
}
