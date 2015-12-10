//
//  IMPHistogramAnalizer.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 28.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit

///
/// Анализатор гистограммы на основе раздельного расчета частинчых гистограмм и сборке полной на DSP.
///
class IMPHistogramDSPReduceAnalyzer: IMPHistogramAnalyzer {
    
    ///
    /// Конструктор анализатора с произвольным счетчиком, который
    /// задаем kernel-функцией. Главное условие совместимость с типом IMPHistogramBuffer
    /// как контейнером данных гистограммы.
    ///
    ///
    required init(function: String, context aContext: DPContext!) {
        super.init(function: function, context: aContext)
        //
        // создаем память в устройстве под контейнер счета частями
        //
        histogramPartialUniformBuffer = histogramPartialUniformBuffer ?? self.context.device.newBufferWithLength(sizeof(IMPHistogramPartialBuffers), options: MTLResourceOptions.CPUCacheModeDefaultCache)
    }
    
    ///
    /// По умолчанию гистограмма инициализируется счетчиком интенсивностей в RGB-пространстве,
    /// с дополнительным вычислением канала яркости.
    ///
     convenience required init!(context aContext: DPContext!) {
        self.init(function: "kernel_impPartialRGBYHistogram", context:aContext)
    }
    
    //
    // Буфер обмена контейнера счета с GPU
    //
    private var histogramPartialUniformBuffer:MTLBuffer?
    
    //
    // Прикладываем вычисления к тектсуре
    //
    override func apply() {
        
        super.apply(
            MTLSizeMake(Int(kIMP_HistogramSize), Int(1), 1),
            buffer: histogramPartialUniformBuffer!)
        
        // Обновляем структуру гистограммы с которой уже будем работать
        histogram.updateWithData(histogramPartialUniformBuffer!.contents(), dataCount: Int(kIMP_HistogramSize))
        
    }
}
