//
//  IMPHistogramAnalyzer.swift
//  ImageMetalling-06
//
//  Created by denis svinarchuk on 07.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa


///
/// Протокол солверов статистики гистограммы. Солверами будем решать конкретные задачи обработки данных прилетевших в контейнер.
///
protocol IMPHistogramSolver{
    func analizerDidUpdate(analizer: IMPHistogramAnalyzer, histogram: IMPHistogram, imageSize: CGSize);
}

///
/// Базовый анализатор гистограммы четырех канальной гистограммы.
///
class IMPHistogramAnalyzer: IMPFilter {
    
    ///
    /// Тут храним наши вычисленные распределения поканальных интенсивностей.
    ///
    var histogram = IMPHistogram()
    
    ///
    /// На сколько уменьшаем картинку перед вычисления гистограммы.
    ///
    var downScaleFactor:Float!{
        didSet{
            scaleUniformBuffer = scaleUniformBuffer ?? self.context.device.newBufferWithLength(sizeof(Float), options: MTLResourceOptions.CPUCacheModeDefaultCache)
            memcpy(scaleUniformBuffer.contents(), &downScaleFactor, sizeof(IMPCropRegion))
        }
    }
    internal var scaleUniformBuffer:MTLBuffer!
    
    ///
    /// Солверы анализирующие гистограмму в текущем инстансе
    ///.
    var solvers:[IMPHistogramSolver] = [IMPHistogramSolver]()
    
    ///
    /// Регион внутри которого вычисляем гистограмму.
    ///
    var region:IMPCropRegion!{
        didSet{
            regionUniformBuffer = regionUniformBuffer ?? self.context.device.newBufferWithLength(sizeof(IMPCropRegion), options: MTLResourceOptions.CPUCacheModeDefaultCache)
            memcpy(regionUniformBuffer.contents(), &region, sizeof(IMPCropRegion))
        }
    }
    internal var regionUniformBuffer:MTLBuffer!
    
    //
    // kernel-функция счета
    //
    private var kernel_impHistogramCounter:IMPFunction!
    
    //
    // Буфер обмена контейнера счета с GPU
    //
    private var histogramUniformBuffer:MTLBuffer!
    
    ///
    /// Конструктор анализатора с произвольным счетчиком, который
    /// задаем kernel-функцией. Главное условие совместимость с типом IMPHistogramBuffer
    /// как контейнером данных гистограммы.
    ///
    ///
    init(context: IMPContext, function: String) {
        super.init(context: context)
        
        if IMPHistogramAnalyzer.atomicTypesSupport {
            let sz  = sizeof(IMPHistogramBuffer)
            histogramUniformBuffer = self.context.device.newBufferWithLength(sz, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        }
        else{
            histogramUniformBuffer = self.context.device.newBufferWithLength(sizeof(IMPHistogramBuffer) * Int(kIMP_HistogramSize), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        }
        
        // инициализируем счетчик
        kernel_impHistogramCounter = IMPFunction(context: self.context, name:function)
        
        // добавляем счетчик как метод фильтра
        self.addFunction(kernel_impHistogramCounter);
        
        defer{
            region = IMPCropRegion(top: 0, right: 0, left: 0, bottom: 0)
            downScaleFactor = 1.0
        }
    }
    
    convenience required init(context: IMPContext) {
        let kernel_name:String
        if IMPHistogramAnalyzer.atomicTypesSupport {
            kernel_name = "kernel_impHistogramRGBYCounter"
        }
        else{
            kernel_name = "kernel_impPartialRGBYHistogram"
        }
        self.init(context:context, function: kernel_name)
    }
    
    ///
    /// Замыкание выполняющаеся после завершения расчета значений солвера.
    /// Замыкание можно определить для обновления значений пользовательской цепочки фильтров.
    ///
    var analyzerDidUpdate: ((histogram:IMPHistogram) -> Void)?
    
    ///
    /// Перегружаем свойство источника: при каждом обновлении нам нужно выполнить подсчет новой статистики.
    ///
    override var source:IMPImageProvider?{
        didSet{
            
            super.source = source
            
            if source?.texture != nil {
                // выполняем фильтр
                self.apply()
            }
        }
    }
    
    override var destination:IMPImageProvider?{
        get{
            return source
        }
    }
    
    internal func apply(texture:MTLTexture, threadgroupCounts: MTLSize, buffer:MTLBuffer!) {
        
        let width  = Int(floor(Float(texture.width) * self.downScaleFactor))
        let height = Int(floor(Float(texture.height) * self.downScaleFactor))
        
        //
        // Вычисляем количество групп вычислительных ядер
        //
        let threadgroups = MTLSizeMake(
            (width  + threadgroupCounts.width ) / threadgroupCounts.width ,
            (height + threadgroupCounts.height) / threadgroupCounts.height,
            1)
        
        self.context.execute { (commandBuffer) -> Void in
            //
            // Обнуляем входной буфер
            //
            let blitEncoder = commandBuffer.blitCommandEncoder()
            blitEncoder.fillBuffer(buffer, range: NSMakeRange(0, buffer.length), value: 0)
            blitEncoder.endEncoding()
            
            let commandEncoder = commandBuffer.computeCommandEncoder()
            
            //
            // Создаем вычислительный пайп
            //
            commandEncoder.setComputePipelineState(self.kernel_impHistogramCounter.pipeline!);
            commandEncoder.setTexture(texture, atIndex:0)
            commandEncoder.setBuffer(buffer, offset:0, atIndex:0)
            commandEncoder.setBuffer(self.regionUniformBuffer,    offset:0, atIndex:1)
            commandEncoder.setBuffer(self.scaleUniformBuffer,     offset:0, atIndex:2)
            
            //
            // Запускаем вычисления
            //
            commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
            commandEncoder.endEncoding()
        }
        
    }
    
    override func apply() {
        
        if let texture = source?.texture{
            
            if IMPHistogramAnalyzer.atomicTypesSupport {
                apply(
                    texture,
                    threadgroupCounts: MTLSizeMake(kernel_impHistogramCounter.groupSize.width, kernel_impHistogramCounter.groupSize.height, 1),
                    buffer: histogramUniformBuffer)
                
                //
                // обновляем структуру гистограммы с которой уже будем работать
                //
                histogram.updateWithData(histogramUniformBuffer.contents())
            }
            else {
                
                apply(
                    texture,
                    threadgroupCounts: MTLSizeMake(Int(kIMP_HistogramSize), Int(1), 1),
                    buffer: histogramUniformBuffer)

                histogram.updateWithData(histogramUniformBuffer.contents(), dataCount: Int(kIMP_HistogramSize))
            }
            
            for s in solvers {
                let size = CGSizeMake(CGFloat(texture.width), CGFloat(texture.height))
                s.analizerDidUpdate(self, histogram: self.histogram, imageSize: size)
            }
            
            if let p = self.analyzerDidUpdate {
                p(histogram: histogram)
            }
            
        }
    }
    
    static var atomicTypesSupport:Bool{
        get{
            return true
        }
    }
}