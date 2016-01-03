//
//  IMPPaletteSolver.swift
//  ImageMetalling-08
//
//  Created by denis svinarchuk on 02.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Foundation
import IMProcessing

///  Типы распределения цветовых акцентов изображения
///
///  - palette:   палитра квантирования цветов изображения.
///               расчитывается по сжеме median-cut преобрзования:
///               http://www.leptonica.com/papers/mediancut.pdf
///  - dominants: расчет доминантных цветов изображения через поиск локальных максимумов 
///               функции плотности распределения цветов: 
///               https://github.com/pixelogik/ColorCube
///
public enum IMPPaletteType{
    case palette
    case dominants
}

/// Солвер анализатора кубической гистограммы цветов IMPHistogramCubeAnalyzer
public class IMPPaletteSolver: IMPHistogramCubeSolver {
    
    /// Максимальное количество цветов палитры для анализа
    public var maxColors = Int(8)
    
    /// Список найденых цветов
    public var colors = [IMPColor]()
    
    /// Тип палитры
    public var type = IMPPaletteType.dominants
    
    ///  Хендлер обработчика солвера
    ///
    ///  - parameter analizer:  ссылка на анализатор
    ///  - parameter histogram: кубическая гистограмма изображния
    ///  - parameter imageSize: размер изображения
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