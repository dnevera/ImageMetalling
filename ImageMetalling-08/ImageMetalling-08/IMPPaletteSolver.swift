//
//  IMPPaletteSolver.swift
//  ImageMetalling-08
//
//  Created by denis svinarchuk on 02.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Foundation
import IMProcessing

public enum IMPPaletteType{
    case palette
    case dominants
}

public class IMPPaletteSolver: IMPHistogramCubeSolver {
    
    public var maxColors = Int(16)
    public var colors = [IMPColor]()
    public var type = IMPPaletteType.palette
    
    public func analizerDidUpdate(analizer: IMPHistogramCubeAnalyzer, histogram: IMPHistogramCube, imageSize: CGSize) {
        var p = [float3]()
        if type == .palette{
            p = histogram.cube.palette(count: maxColors)
        }
        else if type == .dominants {
            p = histogram.cube.dominantColors(count: maxColors)
        }
        colors.removeAll()
        for c in p {
            colors.append(IMPColor(color: float4(rgb: c, a: 1)))
        }
    }
}