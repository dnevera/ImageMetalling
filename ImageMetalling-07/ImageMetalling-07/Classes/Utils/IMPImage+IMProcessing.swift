//
//  IMPImage+Metal.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import Metal


extension IMPImage{
    var CGImage:CGImageRef?{
        get {
            var imageRect:CGRect = CGRectMake(0, 0, self.size.width, self.size.height)
            return self.CGImageForProposedRect(&imageRect, context: nil, hints: nil)
        }
    }
}

extension CGSize{
    init(width: Float, height: Float){
        self.width = CGFloat(width)
        self.height = CGFloat(height)
    }
}

extension IMPImage{
    
    func newTexture(context:IMPContext, maxSize:Float = 0) -> MTLTexture? {
        
        let imageRef  = self.CGImage
        let imageSize = self.size
        
        var imageAdjustedSize = IMPContext.sizeAdjustTo(size: imageSize)
        
        //
        // downscale acording to GPU hardware limit size
        //
        var width  = Float(floor(imageAdjustedSize.width))
        var height = Float(floor(imageAdjustedSize.height))
        
        var scale = Float(1.0)
        
        if (maxSize > 0 && (maxSize < width || maxSize < height)) {
            scale = fmin(maxSize/width,maxSize/height)
            width  *= scale
            height *= scale
            imageAdjustedSize = CGSize(width: width, height: height)
        }
        
        let image = IMPImage(CGImage: self.CGImage!, size:imageAdjustedSize);
        
        width  = Float(floor(image.size.width));
        height = Float(floor(image.size.height));
        
        let resultWidth  = Int(width);
        let resultHeight = Int(height);
        
        
        let rawData  = calloc(resultHeight * resultWidth * 4, sizeof(uint8));
        let bytesPerPixel = 4;
        let bytesPerRow   = bytesPerPixel * resultWidth;
        let bitsPerComponent = 8;
        
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Big.rawValue)

        let bitmapContext = CGBitmapContextCreate(rawData, resultWidth, resultHeight,
            bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo.rawValue);
                
        CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGFloat(resultWidth), CGFloat(resultHeight)), imageRef);
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm,
            width:resultWidth,
            height:resultHeight,
            mipmapped:false);
        
        let texture = context.device?.newTextureWithDescriptor(textureDescriptor)
        
        if let t = texture {
            t.replaceRegion(MTLRegionMake2D(0, 0, resultWidth, resultHeight), mipmapLevel:0, withBytes:rawData, bytesPerRow:bytesPerRow)
        }
        
        free(rawData);
        
        return texture
    }
}