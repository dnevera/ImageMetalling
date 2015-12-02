//
//  IMPHistogramAnalizer.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 28.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit

///
/// Протокол солверов статистики гистограммы. Солверами будем решать конкретные задачи обработки данных прилетевших в контейнер.
///
protocol IMPHistogramSolver{
    func analizerDidUpdate(analizer: IMPHistogramAnalyzer, histogram: IMPHistogram, imageSize: CGSize);
}

///
/// Анализатор гистограммы четырех канальной гистограммы. 
/// Сам анализатор представляем как некий общий класс работающий с произвольным типом гистограмм.
/// Конкретную обрадотку статистики оставляем за набором решающий классов поддерживающих протокол IMPHistogramSolver.
///
class IMPHistogramAnalyzer: DPFilter {
    
    ///
    /// Тут храним наши вычисленные распределения поканальных интенсивностей.
    ///
    var histogram = IMPHistogram()
    
    ///
    /// Солверы участвующие в анализе гистограммы
    ///
    var solvers:[IMPHistogramSolver] = [IMPHistogramSolver]()
    
    var solversDidUpdate: (() -> Void)?
    
    ///
    /// Конструктор анализатора с произвольным счетчиком, который
    /// задаем kernel-функцией. Главное условие совместимость с типом IMPHistogramBuffer
    /// как контейнером данных гистограмы.
    ///
    ///
    init(function: String, context aContext: DPContext!) {
        super.init(context: aContext)
        
        // инициализируем счетчик
        kernel_impHistogramCounter = DPFunction.newFunction(function, context: self.context)
        
        // создаем память в устройстве под контейнер счета
        histogramUniformBuffer = self.context.device.newBufferWithLength(sizeof(IMPHistogramBuffer), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        // добавляем счетчик как метод фильтра
        self.addFunction(kernel_impHistogramCounter);
    }
    
    ///
    /// По умолчанию гистограмма инийиализируется счетчиком интенсивностей в RGB-пространстве,
    /// с дополнительным вычислением канала яркости.
    ///
    required convenience init!(context aContext: DPContext!) {
        self.init(function: "kernel_impHistogramRGBYCounter", context:aContext)
    }
    

    //
    // Буфер обмена контейнера счета с GPU
    //
    private var histogramUniformBuffer:MTLBuffer!
    
    //
    // kernel-функция счета
    //
    private var kernel_impHistogramCounter:DPFunction!    
    
    ///
    /// При каждом обращении к GPU для расчета гистограмы нам нужно обресетить данные посчитанные на предыдущем этапе
    /// если объект анализатора постоянно определен.
    ///
    override func configureBlitUniform(commandEncoder: MTLBlitCommandEncoder!) {
        commandEncoder.fillBuffer(histogramUniformBuffer, range: NSMakeRange(0, sizeof(IMPHistogramBuffer)), value: 0)
    }
    
    ///
    /// Устанавливаем указатель на контейнер счета в буфере команд.
    ///
    override func configureFunction(function: DPFunction!, uniform commandEncoder: MTLComputeCommandEncoder!) {
        commandEncoder.setBuffer(histogramUniformBuffer, offset:0, atIndex:0);
    }
    
    ///
    /// Перегружаем свойство источника: при каждом обновлении нам нужно выполнить подсчет новой статистики.
    ///
    override var source:DPImageProvider!{
        didSet{
            super.source = source
            if source.texture != nil {
                // выполняем фильтр
                self.apply()
            }
        }
    }
    
    override func apply() {
        super.apply()
        // обновляем структуру гистограммы с которой уже будем работать
        histogram.updateWithData(histogramUniformBuffer.contents())
        for s in solvers {
            let size = CGSizeMake(CGFloat(self.source.texture.width), CGFloat(self.source.texture.height))
            s.analizerDidUpdate(self, histogram: self.histogram, imageSize: size)
        }
        if let finishSolver = self.solversDidUpdate {
            finishSolver()
        }
    }
}
