//
//  IMPTestFilter.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 19.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

class IMPTestFilter:IMPFilter {
    
    var analayzer:IMPHistogramAnalyzer!
    let dominantSolver = IMPHistogramDominantColorSolver()
    let rangeSolver = IMPHistogramRangeSolver()
    
    required init(context: IMPContext, histogramView:IMPView, histogramCDFView:IMPView) {
        
        super.init(context: context)
        
        self.addFunction(IMPFunction(context: self.context, name: IMPSTD_PASS_KERNEL))
        analayzer = IMPHistogramAnalyzer(context: self.context)
        
        analayzer.histogram = IMPHistogram(channels: 4)
        
        analayzer.downScaleFactor = 1
        analayzer.region = IMPCropRegion(top: 0.0, right: 0.0, left: 0.0, bottom: 0.0)
        
        analayzer.solvers.append(dominantSolver)
        analayzer.solvers.append(rangeSolver)
        
        analayzer.analyzerDidUpdate = { (histogram) in
            
            print(" *** range    = \(self.rangeSolver.min, self.rangeSolver.max)")
            print(" *** dominant = \(self.dominantSolver.color*255.0), \(self.dominantSolver.color)")
            
        }
        
        self.addSourceObserver { (source) -> Void in
            self.analayzer.source = source
        }
        
        self.addDestinationObserver { (destination) -> Void in
            histogramView.source = destination
            histogramCDFView.source = destination
        }
    }
    
    required init(context: IMPContext) {
        fatalError("init(context:) has not been implemented")
    }
    
    var redraw: (()->Void)?
}
