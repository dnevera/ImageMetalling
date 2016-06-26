//
//  IMTLAutoContrastFilter.swift
//  ImageMetalling-14
//
//  Created by denis svinarchuk on 24.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Foundation
import IMProcessing
import Accelerate

public class IMPBezierCurvesFilter:IMPFilter,IMPAdjustmentProtocol{
    
    public class Splines: IMPTextureProvider,IMPContextProvider {
        
        public var context:IMPContext!
        
        public static let scale:Float    = 1
        public static let minValue = 0
        public static let maxValue = 1
        public static let defaultControls = [float2(minValue.float,minValue.float),float2(maxValue.float,maxValue.float)]
        public static let defaultRange    = Float.range(start: 0, step: 1/255, end: 1)
        public static let defaultCurve    = defaultRange.cubicBezierSpline(c1: Splines.defaultControls[0], c2: Splines.defaultControls[1]) as [Float]
        
        var _redCurve:[Float]   = Splines.defaultCurve
        var _greenCurve:[Float] = Splines.defaultCurve
        var _blueCurve:[Float]  = Splines.defaultCurve
        
        public var channelCurves:[[Float]]{
            get{
                return [_redCurve,_greenCurve,_blueCurve]
            }
        }
        public var redCurve:[Float]{
            get{
                return _redCurve
            }
        }
        public var greenCurve:[Float]{
            get{
                return _greenCurve
            }
        }
        public var blueCurve:[Float]{
            get{
                return _blueCurve
            }
        }
        
        var doNotUpdate = false
        public var redControls   = Splines.defaultControls {
            didSet{
                _redCurve = Splines.defaultRange.cubicBezierSpline(c1: redControls[0], c2: redControls[1]) as [Float]
                if !doNotUpdate {
                    updateTexture()
                }
            }
        }
        public var greenControls = Splines.defaultControls{
            didSet{
                _greenCurve = Splines.defaultRange.cubicBezierSpline(c1: greenControls[0], c2: greenControls[1]) as [Float]
                if !doNotUpdate {
                    updateTexture()
                }
            }
        }
        public var blueControls  = Splines.defaultControls{
            didSet{
                _blueCurve = Splines.defaultRange.cubicBezierSpline(c1: blueControls[0], c2: blueControls[1]) as [Float]
                if !doNotUpdate {
                    updateTexture()
                }
            }
        }
        public var compositeControls = Splines.defaultControls{
            didSet{
                doNotUpdate = true
                redControls   = compositeControls
                greenControls = compositeControls
                blueControls  = compositeControls
                doNotUpdate = false
                updateTexture()
            }
        }
        
        public var texture:MTLTexture?
        public var filter:IMPFilter?
        
        public required init(context:IMPContext){
            self.context = context
            updateTexture()
        }
        
        func updateTexture(){
            
            if texture == nil {
                texture = context.device.texture1DArray(channelCurves)
            }
            else {
                texture?.update(channelCurves)
            }
            
            if filter != nil {
                filter?.dirty = true
            }
        }
    }
    
    
    public static let defaultAdjustment = IMPAdjustment(
        blending: IMPBlending(mode: IMPBlendingMode.LUMNINOSITY, opacity: 1))
    
    public var adjustment:IMPAdjustment!{
        didSet{
            self.updateBuffer(&adjustmentBuffer, context:context, adjustment:&adjustment, size:sizeofValue(adjustment))
            self.dirty = true
        }
    }
    
    public var adjustmentBuffer:MTLBuffer?
    public var kernel:IMPFunction!
    
    public var splines:Splines!
    
    public required init(context: IMPContext) {
        super.init(context: context)
        kernel = IMPFunction(context: self.context, name: "kernel_adjustCurve")
        addFunction(kernel)
        splines = Splines(context: context)
        splines.filter = self
        defer{
            adjustment = IMPCurvesFilter.defaultAdjustment
        }
    }
    
    public override func configure(function: IMPFunction, command: MTLComputeCommandEncoder) {
        if kernel == function {
            command.setTexture(splines.texture, atIndex: 2)
            command.setBuffer(adjustmentBuffer, offset: 0, atIndex: 0)
        }
    }
}


public class IMTLAutoContrastFilter: IMPFilter {

    var rangeSolver = IMPHistogramRangeSolver() {
        didSet{
            dirty = true
        }
    }

    public lazy var curvesFilter:IMPBezierCurvesFilter = {
        return IMPBezierCurvesFilter(context:self.context)
    }()
    
    lazy var analyzer:IMPHistogramAnalyzer = {
        let a = IMPHistogramAnalyzer(context: self.context)
        a.addSolver(self.rangeSolver)
        a.addUpdateObserver({ (histogram) in
            
            let lowlimit:Float = 0.1
            let highlimit:Float = 0.9
            let f = 2 * self.degree
            var m = self.rangeSolver.minimum.a * f
            var M = 1 - (1-self.rangeSolver.maximum.a) * f
            
            m = m < 0 ? 0 : m > highlimit ? highlimit : m
            M = M < lowlimit ? lowlimit : M > 1 ? 1 : M

            var r = self.rangeSolver.minimum.r * f
            var R = 1 - (1-self.rangeSolver.maximum.r) * f

            var g = self.rangeSolver.minimum.g * f
            var G = 1 - (1-self.rangeSolver.maximum.g) * f

            var b = self.rangeSolver.minimum.b * f
            var B = 1 - (1-self.rangeSolver.maximum.b) * f

            r = r < 0 ? 0 : r > highlimit ? highlimit : r
            R = R < lowlimit ? lowlimit : R > 1 ? 1 : R

            g = g < 0 ? 0 : g > highlimit ? highlimit : g
            G = G < lowlimit ? lowlimit : G > 1 ? 1 : G

            b = b < 0 ? 0 : b > highlimit ? highlimit : b
            B = B < lowlimit ? lowlimit : B > 1 ? 1 : B


            self.curvesFilter.splines.redControls = [float2(r,0), float2(R,1)]
            self.curvesFilter.splines.greenControls = [float2(g,0), float2(G,1)]
            self.curvesFilter.splines.blueControls = [float2(b,0), float2(B,1)]
        })
        return a
    }()
    
    
    public var degree:Float = 1 {
        didSet{
            dirty = true
        }
    }
    
    public var shadows:Float {
        get{
            return rangeSolver.clipping.shadows
        }
        set {
            rangeSolver.clipping.shadows = newValue
            dirty = true
        }
    }
    
    public var highlights:Float {
        get{
            return rangeSolver.clipping.highlights
        }
        set {
            rangeSolver.clipping.highlights = newValue
            dirty = true
        }
    }
    
    required public init(context: IMPContext) {
        super.init(context: context)
        rangeSolver.clipping.shadows = 3.5/100.0
        rangeSolver.clipping.highlights = 0.5/100.0
        addSourceObserver { (source) in
            self.analyzer.source = source
        }
        addFilter(curvesFilter)
    }
}