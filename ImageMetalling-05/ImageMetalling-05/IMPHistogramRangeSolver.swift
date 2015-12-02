//
//  IMPHistogramRangeSolver.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 01.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit


///
/// Солвер вычисляет диапазон интенсивностей для интересных нам условий клиппинга.
///
class IMPHistogramRangeSolver: IMPHistogramSolver {
    
    struct clippingType {
        ///
        /// Клипинг теней (все тени, которые будут перекрыты растяжением), по умолчанию 0.1%
        ///
        var shadows:Float = 0.1/100.0
        ///
        /// Клипинг светов, по умолчанию 0.1%
        ///
        var highlights:Float = 0.1/100.0
    }
    
    var clipping = clippingType()
    
    ///
    /// Минимальная интенсивность в пространстве RGB(Y)
    ///
    var min = DPVector4(v: (0, 0, 0, 0))
    ///
    /// Максимальная интенсивность в пространстве RGB(Y)
    ///
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