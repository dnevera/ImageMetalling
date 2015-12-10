//
//  IMPHistogramAnalizer.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 28.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit


///
/// Анализатор гистограммы с обновлением общей структуры через атомарные операции вычислительного ядра.
///
class IMPHistogramATAnalyzer: IMPHistogramAnalyzer {
    
    required init(function: String, context aContext: DPContext!) {
        super.init(function: function, context: aContext)
        
        //
        // создаем память в устройстве под контейнер счета
        //
        histogramUniformBuffer = self.context.device.newBufferWithLength(sizeof(IMPHistogramBuffer), options: MTLResourceOptions.CPUCacheModeDefaultCache)
    }
    
    required convenience init!(context aContext: DPContext!) {
        self.init(function: "kernel_impHistogramRGBYCounter", context:aContext)
    }

    //
    // Буфер обмена контейнера счета с GPU
    //
    private var histogramUniformBuffer:MTLBuffer!
    
    override func apply() {
        super.apply(
            MTLSizeMake(Int(self.functionThreads), Int(self.functionThreads), 1),
            buffer: histogramUniformBuffer!)
        
        //
        // обновляем структуру гистограммы с которой уже будем работать
        //
        histogram.updateWithData(histogramUniformBuffer.contents())        
    }
}
