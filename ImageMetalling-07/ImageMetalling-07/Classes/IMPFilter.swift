//
//  IMPFilter.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import Metal

typealias IMPFilterSorceHandler = ((source:IMPImageProvider) -> Void)
typealias IMPFilterDestinationHandler = ((destination:IMPImageProvider) -> Void)

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
            return getDestination()
        }
    }
    
    var dirty:Bool = true
    
    required init(context: IMPContext) {
        self.context = context
    }
    
    private var functionList:[IMPFunction] = [IMPFunction]()
    private var filterList:[IMPFilter] = [IMPFilter]()
    
    final func addFunction(function:IMPFunction){
        if functionList.contains(function) == false {
            functionList.append(function)
        }
    }
    
    final func removeFunction(function:IMPFunction){
        if let index = functionList.indexOf(function) {
            functionList.removeAtIndex(index)
        }
    }
    
    final func addFilter(filter:IMPFilter){
        if filterList.contains(filter) == false {
            filterList.append(filter)
        }
    }
    
    final func removeFilter(filter:IMPFilter){
        if let index = filterList.indexOf(filter) {
            filterList.removeAtIndex(index)
        }
    }

    var processingWillStart:IMPFilterSorceHandler?
    var processingDidFinish:IMPFilterDestinationHandler?
    
    private var texture:MTLTexture?
    private var destinationContainer:IMPImageProvider?
    
    func getDestination() -> IMPImageProvider? {
        if let t = self.texture{
            if let d = destinationContainer{
                d.texture=t
            }
            else{
                destinationContainer = IMPImageProvider(context: self.context, texture: t)
            }
        }
        return destinationContainer
    }
    
    func configure(function:IMPFunction, command:MTLComputeCommandEncoder){}
    
    func apply(){
        
        if dirty {

            if self.source?.texture == nil {
                dirty = false
                return
            }

            if  functionList.count > 0 {
                
                if let p = processingWillStart{
                    p(source: source!)
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
                        
                        commandEncoder.setTexture(inputTexture, atIndex:0)
                        commandEncoder.setTexture(self.texture, atIndex:1)
                        
                        self.configure(function, command: commandEncoder)
                        
                        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts)
                        commandEncoder.endEncoding()
                        
                        inputTexture = self.texture
                    }
                })
            }
            else if filterList.count > 0 {
                if let p = processingWillStart{
                    p(source: source!)
                }
            }
            
            if self.texture == nil{
                self.texture = self.source?.texture
            }
            
            if filterList.count > 0 {
                
                for filter in self.filterList {

                    filter.source = self.getDestination()
                    self.texture  = filter.destination?.texture
                    
                    if self.texture == nil {
                        fatalError("IMPFilter \(filter) did not return valid texture...")
                    }
                }
                
                if let p = processingDidFinish {
                    p(destination: getDestination()!)
                }
                
            }
            else if functionList.count > 0 {
                if let p = processingDidFinish {
                    p(destination: getDestination()!)
                }
            }
            
            dirty = false
        }
    }
}
