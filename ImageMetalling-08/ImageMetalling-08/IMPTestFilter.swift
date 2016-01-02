//
//  IMPTestFilter.swift
//  ImageMetalling-08
//
//  Created by denis svinarchuk on 02.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import IMProcessing

public class IMPTestFilter:IMPFilter {
    
    var contrastFilter:IMPContrastFilter!
    var awbFilter:IMPAutoWBFilter!
    
    var sourceAnalyzer:IMPHistogramAnalyzer!
    let rangeSolver = IMPHistogramRangeSolver()

    public required init(context: IMPContext) {
        super.init(context: context)
        
        contrastFilter = IMPContrastFilter(context: context)
        awbFilter = IMPAutoWBFilter(context: context)
        
        addFilter(contrastFilter)
        addFilter(awbFilter)
        
        sourceAnalyzer = IMPHistogramAnalyzer(context: self.context)
        sourceAnalyzer.addSolver(rangeSolver)
        
        addSourceObserver { (source) -> Void in
            self.sourceAnalyzer.source = source
        }

        sourceAnalyzer.addUpdateObserver({ (histogram) -> Void in
            self.contrastFilter.adjustment.minimum = self.rangeSolver.minimum
            self.contrastFilter.adjustment.maximum = self.rangeSolver.maximum
        })

    }
}