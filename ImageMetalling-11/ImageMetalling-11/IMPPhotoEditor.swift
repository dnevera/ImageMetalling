//
//  IMPPhotoEditor.swift
//  ImageMetalling-11
//
//  Created by denis svinarchuk on 02.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import IMProcessing

public class IMPPhotoEditor: IMPFilter, UIDynamicItem{
    
    public required init(context: IMPContext) {
        super.init(context: context)
        addFilter(photo)
        addFilter(cropFilter)
    }
    
    lazy var photo:IMPTransformFilter = {
        return IMPTransformFilter(context: self.context)
    }()
    
    
    lazy var cropFilter:IMPCropFilter = {
        return IMPCropFilter(context:self.context)
    }()
    
    
    var currentScaleFactor:Float {
        return IMPPhotoPlate(aspect: aspect).scaleFactorFor(model: model)
    }
    
    var currentCropRegion:IMPRegion {
        let offset  = (1 - currentScaleFactor * scale ) / 2
        let aspect  = crop.width/crop.height
        let offsetx = offset * aspect
        let offsety = offset
        return IMPRegion(left: offsetx+crop.left, right: offsetx+crop.right, top: offsety+crop.top, bottom: offsety+crop.bottom)
    }

    public var crop = IMPRegion() {
        didSet{
            region = currentCropRegion
        }
    }
    
    var region: IMPRegion {
        set {
            cropFilter.region = newValue
            dirty = true
        }
        get {
            return cropFilter.region
        }
    }
    
    public var backgroundColor:IMPColor {
        get {
            return photo.backgroundColor
        }
        set {
            photo.backgroundColor = newValue
        }
    }
    
    public var aspect:Float {
            return photo.aspect
    }
    
    public var model:IMPMatrixModel {
        return photo.model
    }
        
    public var translation:float2 {
        set{
            photo.translation = newValue
        }
        get {
            return photo.translation
        }
    }

    public var angle:float3 {
        set {
            photo.angle = newValue
            region = currentCropRegion
        }
        get{
            return photo.angle
        }
    }

    public var scale:Float {
        set {
            photo.scale(factor: newValue)
        }
        get{
            return photo.scale.x
        }
    }
    
    public var viewPort:CGRect? = nil

    //
    // Conform to UIDynamicItem
    //
    public var center:CGPoint {
        set{
            if let size = viewPort?.size {
                translation = float2(newValue.x.float,newValue.y.float) / (float2(size.width.float,size.height.float)/2)
            }
        }
        get {
            if let size = viewPort?.size {
                return CGPoint(x: translation.x.cgfloat*size.width/2, y: translation.y.cgfloat*size.height/2)
            }
            return CGPoint()
        }
    }
    
    
    public var bounds:CGRect {
        get {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
    }
    
    public var transform = CGAffineTransform()
    
    public var outOfBounds:float2 {
        get {
            
            let aspect   = self.aspect
            let model    = self.model
            
            //
            // Model of Cropped Quad
            //
            let cropQuad = IMPQuad(region:cropFilter.region, aspect: aspect)
            
            //
            // Model of transformed Quad
            // Transformation matrix of the model can be the same which transformation filter has or it can be computed independently
            //
            let transformedQuad = IMPPhotoPlate(aspect: aspect).quad(model: model)
            
            //
            // Offset for transformed quad which should contain inscribed croped quad
            //
            // NOTE:
            // 1. quads should be rectangle
            // 2. scale of transformed quad should be great then or equal scaleFactorFor for the transformed model:
            //    IMPPhotoPlate(aspect: transformFilter.aspect).scaleFactorFor(model: model)
            //
            return transformedQuad.translation(quad: cropQuad)
        }
    }
    
    public var anchor:CGPoint?  {
        get {
            guard let size = viewPort?.size else { return nil }
            
            var offset = -outOfBounds
            
            if abs(offset.x) > 0 || abs(offset.y) > 0 {
                
                offset = (self.translation+offset) * float2(size.width.float,size.height.float)/2
                
                return CGPoint(x: offset.x.cgfloat, y: offset.y.cgfloat)
            }
            
            return nil
        }
    }
}
