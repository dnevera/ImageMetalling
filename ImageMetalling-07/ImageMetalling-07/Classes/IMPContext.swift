//
//  IMPContext.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import Metal
import OpenGL.GL

protocol IMPContextProvider{
    var context:IMPContext! {get}
}

typealias IMPContextExecution = ((commandBuffer:MTLCommandBuffer) -> Void)

class IMPContext {
    
    private struct sharedContainerType {
        
        var currentMaximumTextureSize:Int?
        func deviceMaximumTextureSize()->Int{
            dispatch_once(&sharedContainerType.pred) {
                var pixelAttributes:[NSOpenGLPixelFormatAttribute] = [UInt32(NSOpenGLPFADoubleBuffer), UInt32(NSOpenGLPFAAccelerated), 0]
                let pixelFormat = NSOpenGLPixelFormat(attributes: &pixelAttributes)
                let context = NSOpenGLContext(format: pixelFormat!, shareContext: nil)
                
                context?.makeCurrentContext()
                
                glGetIntegerv(GLenum(GL_MAX_TEXTURE_SIZE), &sharedContainerType.maxTextureSize)
            }
            return Int(sharedContainerType.maxTextureSize)
        }
        
        private static var pred:dispatch_once_t = 0;
        private static var maxTextureSize:GLint = 0;
    }
    
    private static var sharedContainer = sharedContainerType()
    
    let device:MTLDevice! = MTLCreateSystemDefaultDevice()
    let commandQueue:MTLCommandQueue?
    let defaultLibrary:MTLLibrary?
    let isLasy:Bool
    
    required init(lazy:Bool = false)  {
        isLasy = lazy
        if let device = self.device{
            commandQueue = device.newCommandQueue()
            if let library = device.newDefaultLibrary(){
                defaultLibrary = library
            }
            else{
                fatalError(" *** IMPContext: could not find default library...")
            }
            
        }
        else{
            fatalError(" *** IMPContext: could not get GPU device...")
        }
    }
    
    final func execute(closure: IMPContextExecution) {
        if let commandBuffer = commandQueue?.commandBuffer(){
            
            closure(commandBuffer: commandBuffer)
            commandBuffer.commit()
            
            if isLasy == false {
                commandBuffer.waitUntilCompleted()
            }
        }
    }
    
    static var maximumTextureSize:Int{
        
        set(newMaximumTextureSize){
            IMPContext.sharedContainer.currentMaximumTextureSize = 0
            var size = IMPContext.sharedContainer.deviceMaximumTextureSize()
            if newMaximumTextureSize <= size {
                size = newMaximumTextureSize
            }
            IMPContext.sharedContainer.currentMaximumTextureSize = size
        }
        
        get {
            if let size = IMPContext.sharedContainer.currentMaximumTextureSize{
                return size
            }
            else{
                return IMPContext.sharedContainer.deviceMaximumTextureSize()
            }
        }
        
    }
    
    static func sizeAdjustTo(size inputSize:CGSize, maxSize:Float = Float(IMPContext.maximumTextureSize)) -> CGSize
    {
        if (inputSize.width < CGFloat(maxSize)) && (inputSize.height < CGFloat(maxSize))  {
            return inputSize
        }
        
        var adjustedSize = inputSize
        
        if inputSize.width > inputSize.height {
            adjustedSize = CGSize(width: CGFloat(maxSize), height: ( CGFloat(maxSize) / inputSize.width) * inputSize.height)
        }
        else{
            adjustedSize = CGSize(width: ( CGFloat(maxSize) / inputSize.height) * inputSize.width, height:CGFloat(maxSize))
        }
        
        return adjustedSize;
    }
    
    
}
