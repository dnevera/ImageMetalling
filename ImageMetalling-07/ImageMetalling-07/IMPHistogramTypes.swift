//
//  IMPHistogramTypes.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Foundation
import simd

// MARK: - Определения констант и стурутур гистограммы
extension IMP{
    
    struct histogramPreferences {
        static let size:Int     = Int(kIMP_HistogramSize)
        static let channels:Int = Int(kIMP_HistogramChannels)
        static let groups:Int   = Int(kIMP_HistogramGroups)
    }
    
    struct histogramBuffer{
        var channels:[[uint]] = [[uint]](count: histogramPreferences.channels, repeatedValue: [uint](count: histogramPreferences.size, repeatedValue: 0))
    }
    
}
