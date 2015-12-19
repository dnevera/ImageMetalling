//
//  IMPHistogramView.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 19.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

class IMPHistogramView: IMPView {
    
    class histogramLayerFilter: IMPFilter {
        
        var analayzer:IMPHistogramAnalyzer!{
            didSet{
                self.dirty = true
            }
        }
        
        var solver:IMPHistogramLayerSolver!{
            didSet{
                self.dirty = true
            }
        }
        
        internal required init(context: IMPContext) {
            
            super.init(context: context)
                        
            solver = IMPHistogramLayerSolver(context: self.context)
            
            self.addFilter(solver)
            
            analayzer = IMPHistogramAnalyzer(context: self.context)
            analayzer.solvers.append(solver)
            
            self.addSourceObserver{ (source:IMPImageProvider) -> Void in
                self.analayzer.source = source
            }
        }
        
        private var view:IMPHistogramView?
        
        required convenience init(context: IMPContext, view:IMPHistogramView) {
            self.init(context: context)
            self.view = view
        }
        
        override func apply() {
            if let v = view{
                var size = MTLSize(cgsize: v.bounds.size)*(v.scaleFactor,v.scaleFactor,1)
                size.depth = 1
                solver.destinationSize = size
            }
            super.apply()
        }
    }
    
    private var _filter:histogramLayerFilter!
    override internal var filter:IMPFilter?{
        set(newFiler){}
        get{ return _filter }
    }
    
    var histogram:histogramLayerFilter{
        get{
            return _filter
        }
    }
    
    override init(context contextIn: IMPContext, frame: NSRect) {
        super.init(context: contextIn, frame: frame)
        _filter = histogramLayerFilter(context: self.context, view: self)
        _filter.addDirtyObserver { () -> Void in
            self.layerNeedUpdate = true
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _filter = histogramLayerFilter(context: self.context, view: self)
        _filter.addDirtyObserver { () -> Void in
            self.layerNeedUpdate = true
        }
    }
}
