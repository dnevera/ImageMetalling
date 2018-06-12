//
//  IMPColorPlaneFilter.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 12.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Foundation
import IMProcessing

public class CommonPlaneFilter: IMPFilter {
    public var reference:float3            = float3(0)   { didSet{ dirty = true } }
    public var space:IMPColorSpace         = .rgb        { didSet{ dirty = true } }
    public var spaceChannels:(Int,Int) = (0,1)       { didSet{ dirty = true } }
    
    public override func configure(complete: IMPFilter.CompleteHandler?) {
        super.extendName(suffix: "Common Plane")
        let ci = NSImage(color:NSColor.darkGray, size:NSSize(width: 400, height: 400))
        source = IMPImage(context: context, image: ci)
        super.configure(complete: complete)
    }
}

public class IMPColorPlaneFilter: CommonPlaneFilter {

    public typealias Controls=MLSControls

    public var controls:Controls = Controls(p: [], q: []) {
        didSet{
            let length = MemoryLayout<float2>.size * self.controls.p.count
                        
            if self.pBuffer.length == length {
                memcpy(self.pBuffer.contents(), self.controls.p, length)
                memcpy(self.qBuffer.contents(), self.controls.q, length)
            }
            else {
                
                self.pBuffer = self.context.device.makeBuffer(
                    bytes: self.controls.p,
                    length: length,
                    options: [])!
                
                self.qBuffer = self.context.device.makeBuffer(
                    bytes: self.controls.q,
                    length: length,
                    options: [])!                
            }
            
            dirty = true
        }
    }
    
    override public func configure(complete: IMPFilter.CompleteHandler?) {
        
        super.extendName(suffix: "Plane Filter")
        super.configure(complete: nil)
                
        let kernel = IMPFunction(context: self.context, kernelName: "kernel_mlsPlaneTransform")
        
        kernel.optionsHandler = {(shader, commandEncoder, input, output) in                       
                        
            commandEncoder.setBytes(&self.reference, 
                                    length: MemoryLayout.size(ofValue: self.reference), 
                                    index: 0)
            
            var index = self.space.index
            commandEncoder.setBytes(&index, 
                                    length: MemoryLayout.size(ofValue: index), 
                                    index: 1)
            
            var pIndices = uint2(UInt32(self.spaceChannels.0),UInt32(self.spaceChannels.1))
            commandEncoder.setBytes(&pIndices, 
                                    length: MemoryLayout.size(ofValue: pIndices), 
                                    index: 2)
            
            commandEncoder.setBuffer(self.pBuffer, 
                                     offset: 0, 
                                     index: 3)
            
            commandEncoder.setBuffer(self.qBuffer, 
                                     offset: 0, 
                                     index: 4)
            
            var count = self.controls.p.count
            commandEncoder.setBytes(&count, 
                                    length: MemoryLayout.stride(ofValue: count), 
                                    index: 5)
            
            var kind = self.controls.kind
            commandEncoder.setBytes(&kind, 
                                    length: MemoryLayout.stride(ofValue: kind), 
                                    index: 6)
            
            var alpha = self.controls.alpha
            commandEncoder.setBytes(&alpha, 
                                    length: MemoryLayout.stride(ofValue: alpha), 
                                    index: 7)
            
        }
        
        add(function: kernel) { (image) in
            complete?(image)
        }
    }
    
    private lazy var pBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout.size(ofValue: [float2]()), options:[])!
    private lazy var qBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout.size(ofValue: [float2]()), options:[])!   
}


public extension NSImage {
    
    public func resize(factor level: CGFloat) -> NSImage {
        let _image = self
        let newRect: NSRect = NSMakeRect(0, 0, _image.size.width, _image.size.height)
        
        let imageSizeH: CGFloat = _image.size.height * level
        let imageSizeW: CGFloat = _image.size.width * level
        
        let newImage = NSImage(size: NSMakeSize(imageSizeW, imageSizeH))
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = NSImageInterpolation.medium
        
        _image.draw(in: NSMakeRect(0, 0, imageSizeW, imageSizeH), from: newRect, operation: .sourceOver, fraction: 1)
        newImage.unlockFocus()
        
        return newImage
    }
    
    convenience init(color: NSColor, size: NSSize) {
        self.init(size: size)
        lockFocus()
        color.drawSwatch(in: NSMakeRect(0, 0, size.width, size.height))
        unlockFocus()
    }
    
    public static var typeExtensions:[String] {
        return NSImage.imageTypes.map { (name) -> String in
            return name.components(separatedBy: ".").last!
        }
    }
    
    public class func getMeta(contentsOf url: URL) -> [String: AnyObject]? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        guard let properties =  CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: AnyObject] else { return nil }
        return properties
    }
    
    public class func getSize(contentsOf url: URL) -> NSSize? {
        guard let properties = NSImage.getMeta(contentsOf: url) else { return nil }
        if let w = properties[kCGImagePropertyPixelWidth as String]?.floatValue,
            let h = properties[kCGImagePropertyPixelHeight as String]?.floatValue {
            return NSSize(width: w.cgfloat, height: h.cgfloat)
        }
        return nil
    }
    
    public class func thumbNail(contentsOf url: URL, size max: Int) -> NSImage? {
        
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        
        let options = [
            kCGImageSourceShouldAllowFloat as String: true as NSNumber,
            kCGImageSourceCreateThumbnailWithTransform as String: false as NSNumber,
            kCGImageSourceCreateThumbnailFromImageAlways as String: true as NSNumber,
            kCGImageSourceThumbnailMaxPixelSize as String: max as NSNumber
            ] as CFDictionary
        
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else { return nil }
        
        return NSImage(cgImage: thumbnail, size: NSSize(width: max, height: max))
    }
}
