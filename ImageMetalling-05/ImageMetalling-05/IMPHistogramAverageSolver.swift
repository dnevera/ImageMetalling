//
//  IMPHistogramAverageSolver.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 01.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit

class IMPHistogramAverageSolver: IMPHistogramSolver {
    var color=DPVector4()
    func analizerDidUpdate(analizer: IMPHistogramAnalyzer, histogram: IMPHistogram, imageSize: CGSize) {
        color.v = (
            histogram.mean(channel: 0),
            histogram.mean(channel: 1),
            histogram.mean(channel: 2),
            histogram.mean(channel: 3)
        )
    }
}
