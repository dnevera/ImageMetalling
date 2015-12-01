//
//  IMPHistogramRangeSolver.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 01.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit


///
/// Один из словеров ищет диапазон светов/теней для интересных нам условий клиппинга.
///
class IMPHistogramRangeSolver: IMPHistogramSolver {
    
    struct clippingType {
        var shadows:Float = 0.1/100.0
        var highlights:Float = 0.1/100.0
    }
    
    var clipping = clippingType()
    var min = DPVector4(v: (0, 0, 0, 0))
    var max = DPVector4(v: (1, 1, 1, 1))
    
    func analizerDidUpdate(analizer: IMPHistogramAnalyzer, histogram: IMPHistogram, imageSize: CGSize) {
        min.v = (
            histogram.low(channel: 0, clipping: clipping.shadows),
            histogram.low(channel: 1, clipping: clipping.shadows),
            histogram.low(channel: 2, clipping: clipping.shadows),
            histogram.low(channel: 3, clipping: clipping.shadows)
        )

        max.v = (
            histogram.high(channel: 0, clipping: clipping.highlights),
            histogram.high(channel: 1, clipping: clipping.highlights),
            histogram.high(channel: 2, clipping: clipping.highlights),
            histogram.high(channel: 3, clipping: clipping.highlights)
        )
   }
}