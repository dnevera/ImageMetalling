//
//  IMPHistogramRangeSolver.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 01.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import simd

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
    var min = float4()
    ///
    /// Максимальная интенсивность в пространстве RGB(Y)
    ///
    var max = float4()
    
    func analizerDidUpdate(analizer: IMPHistogramAnalyzer, histogram: IMPHistogram, imageSize: CGSize) {
        for i in 0..<histogram.channels.count{
            min[i] = histogram.low(channel: i, clipping: clipping.shadows)
            max[i] = histogram.high(channel: i, clipping: clipping.highlights)
        }
   }
}