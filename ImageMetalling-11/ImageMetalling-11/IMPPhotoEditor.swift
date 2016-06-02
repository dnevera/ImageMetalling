//
//  IMPPhotoEditor.swift
//  ImageMetalling-11
//
//  Created by denis svinarchuk on 02.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import IMProcessing

public class IMPPhotoEditor: IMPTransformFilter, UIDynamicItem{
    
    //
    // Conversions between absolute view port of View and model presentation
    //
    public var cropBounds:IMPRegion? = nil
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
            
            guard let crop=self.cropBounds else { return float2(0) }
            
            let aspect   = self.aspect
            let model    = self.model
            
            //
            // Model of Cropped Quad
            //
            let cropQuad = IMPQuad(region:crop, aspect: aspect)
            
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
    
    public var anchor:CGPoint? {
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
