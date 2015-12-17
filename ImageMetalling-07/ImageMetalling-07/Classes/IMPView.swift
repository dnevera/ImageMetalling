//
//  IMPView.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import AppKit
import Metal
import GLKit.GLKMath
import QuartzCore


class IMPView: NSView, IMPContextProvider {
    
    var context:IMPContext!
    
    var filter:IMPFilter?{
        didSet{
            if let s = self.source{
                self.filter?.source = s
            }
        }
    }
    
    var source:IMPImageProvider?{
        didSet{
            if let texture = source?.texture{
                
                layerSizeDidUpdate = true
                
                self.threadGroups = MTLSizeMake(
                    (texture.width+threadGroupCount.width)/threadGroupCount.width,
                    (texture.height+threadGroupCount.height)/threadGroupCount.height, 1)
                
                if let f = self.filter{
                    f.source = source
                }
                
            }
        }
    }
    
    private var texture:MTLTexture?{
        get{
            if let t = self.filter?.destination?.texture{
                return t
            }
            else {
                return self.source?.texture
            }
        }
    }
    
    var isPaused:Bool = false {
        didSet{
            self.timer?.paused = isPaused
        }
    }
    
    init(context contextIn:IMPContext, frame: NSRect){
        super.init(frame: frame)
        context = contextIn
        defer{
            self.configure()
        }
    }
    
    convenience override init(frame frameRect: NSRect) {
        self.init(context: IMPContext(), frame:frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        context = IMPContext()
        defer{
            self.configure()
        }
    }
    
    var backgroundColor:IMPColor = IMPColor.clearColor(){
        didSet{
            metalLayer.backgroundColor = backgroundColor.CGColor
        }
    }
    
    private var pipeline:MTLComputePipelineState?
    private func configure(){
        
        self.wantsLayer = true
        metalLayer = CAMetalLayer()
        self.layer = metalLayer
        
        let library:MTLLibrary!  = self.context.device.newDefaultLibrary()
        
        //
        // Функция которую мы будем использовать в качестве функции фильтра из библиотеки шейдеров.
        //
        let function:MTLFunction! = library.newFunctionWithName("kernel_passthrough")
        
        //
        // Теперь создаем основной объект который будет ссылаться на исполняемый код нашего фильтра.
        //
        pipeline = try! self.context.device.newComputePipelineStateWithFunction(function)                
    }
    
    //
    // TODO: iOS version
    //
    //    class func layerClass() -> AnyClass {
    //        return CAMetalLayer.self;
    //    }
    
    private var timer:IMPDisplayLink!
    
    private var metalLayer:CAMetalLayer!{
        didSet{
            metalLayer.device = self.context.device
            metalLayer.framebufferOnly = false
            metalLayer.pixelFormat = MTLPixelFormat.BGRA8Unorm
            metalLayer.backgroundColor = self.backgroundColor.CGColor
            timer = IMPDisplayLink(selector: refresh)
            timer?.paused = self.isPaused
            layerSizeDidUpdate = true
        }
    }
    
    private let threadGroupCount = MTLSizeMake(8, 8, 1)
    private var threadGroups : MTLSize!
    private let inflightSemaphore = dispatch_semaphore_create(3)
    
    private var scaleFactor:CGFloat{
        get {
            let screen = self.window?.screen ?? NSScreen.mainScreen()
            let scaleFactor = screen?.backingScaleFactor ?? 1.0
            return scaleFactor
        }
    }

    private func refresh() {
        
        if layerSizeDidUpdate {
            
            autoreleasepool({ () -> () in
                
                var drawableSize = self.bounds.size
                
                drawableSize.width *= self.scaleFactor
                drawableSize.height *= self.scaleFactor
                
                metalLayer.drawableSize = drawableSize
                
                layerSizeDidUpdate = false
                
                self.context.execute { (commandBuffer) -> Void in
                                        
                    if let actualImageTexture = self.texture {
                
                        dispatch_semaphore_wait(self.inflightSemaphore, DISPATCH_TIME_FOREVER);

                        commandBuffer.addCompletedHandler({ (commandBuffer) -> Void in
                            dispatch_semaphore_signal(self.inflightSemaphore);
                        })
                        
                        if let drawable = self.metalLayer.nextDrawable(){
                            
                            let encoder = commandBuffer.computeCommandEncoder()
                            
                            encoder.setComputePipelineState(self.pipeline!)
                            
                            encoder.setTexture(actualImageTexture, atIndex: 0)
                            
                            encoder.setTexture(drawable.texture, atIndex: 1)
                            
                            encoder.dispatchThreadgroups(self.threadGroups, threadsPerThreadgroup: self.threadGroupCount)
                            
                            encoder.endEncoding()
                            commandBuffer.presentDrawable(drawable)
                        }
                        else{
                            dispatch_semaphore_signal(self.inflightSemaphore);
                        }
                    }
                }  
            })
        }
    }
    
    override func display() {
        self.refresh()
    }
    
    var layerSizeDidUpdate:Bool = true
    
    override func setFrameSize(newSize: NSSize) {
        super.setFrameSize(CGSize(width: newSize.width/self.scaleFactor, height: newSize.height/self.scaleFactor))
        layerSizeDidUpdate = true
    }
    
    override func setBoundsSize(newSize: NSSize) {
        super.setBoundsSize(newSize)
        layerSizeDidUpdate = true
    }
    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        layerSizeDidUpdate = true
    }
}


private class IMPDisplayLink {
    
    private typealias DisplayLinkCallback = @convention(block) ( CVDisplayLink!, UnsafePointer<CVTimeStamp>, UnsafePointer<CVTimeStamp>, CVOptionFlags, UnsafeMutablePointer<CVOptionFlags>, UnsafeMutablePointer<Void>)->Void
    
    private func displayLinkSetOutputCallback( displayLink:CVDisplayLink, callback:DisplayLinkCallback )
    {
        let block:DisplayLinkCallback = callback
        let myImp = imp_implementationWithBlock( unsafeBitCast( block, AnyObject.self ) )
        let callback = unsafeBitCast( myImp, CVDisplayLinkOutputCallback.self )
        
        CVDisplayLinkSetOutputCallback( displayLink, callback, UnsafeMutablePointer<Void>() )
    }
    
    
    private var displayLink:CVDisplayLink
    
    var paused:Bool = false {
        didSet(oldValue){
            if  paused {
                if CVDisplayLinkIsRunning(displayLink) {
                    CVDisplayLinkStop( displayLink)
                }
            }
            else{
                if !CVDisplayLinkIsRunning(displayLink) {
                    CVDisplayLinkStart( displayLink )
                }
            }
        }
    }
    
    
    required init(selector: ()->Void ){
        
        displayLink = {
            var linkRef:CVDisplayLink?
            CVDisplayLinkCreateWithActiveCGDisplays( &linkRef )
            
            return linkRef!
            
            }()
        
        let callback = { (
            _:CVDisplayLink!,
            _:UnsafePointer<CVTimeStamp>,
            _:UnsafePointer<CVTimeStamp>,
            _:CVOptionFlags,
            _:UnsafeMutablePointer<CVOptionFlags>,
            _:UnsafeMutablePointer<Void>)->Void in
            
            selector()
        }
        
        displayLinkSetOutputCallback( displayLink, callback: callback )
    }
    
    deinit{
        self.paused = true
    }
    
}
