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
    
    //
    // Количество групп обсчета. Кратно <максимальное количество ядер>/размерность гистограммы.
    // Предполагаем, что количество ядер >= 256 - минимальной размерности гистограммы.
    // Расчет гистограммы просиходит в 3 фазы:
    // 1. GPU:kernel:расчет частичных гистограмм в локальной памяти, количество одновременных ядер == размерноси гистограммы
    // 2. GPU:kernel:сборка частичных гистограмм в глобальную блочную память группы
    // 3. CPU/DSP:сборка групп гистограм в финальную из частичных блочных
    //
    private var threadgroups = MTLSizeMake(1,1,1)
    
    ///
    /// Конструктор анализатора с произвольным счетчиком, который
    /// задаем kernel-функцией. Главное условие совместимость с типом IMPHistogramBuffer
    /// как контейнером данных гистограммы.
    ///
    ///
    init(context: IMPContext, function: String) {
        super.init(context: context)

        // инициализируем счетчик
        kernel_impHistogramCounter = IMPFunction(context: self.context, name:function)
        
        let groups = kernel_impHistogramCounter.pipeline!.maxTotalThreadsPerThreadgroup/histogram.size

        threadgroups = MTLSizeMake(groups,1,1)
            histogramUniformBuffer = self.context.device.newBufferWithLength(sizeof(IMPHistogramBuffer) * Int(groups), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        // добавляем счетчик как метод фильтра
        self.addFunction(kernel_impHistogramCounter);
        
        defer{
            region = IMPCropRegion(top: 0, right: 0, left: 0, bottom: 0)
            downScaleFactor = 1.0
        }
    }
    
    convenience required init(context: IMPContext) {
        self.init(context:context, function: "kernel_impHistogramPartial")
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
            commandEncoder.dispatchThreadgroups(self.threadgroups, threadsPerThreadgroup:threadgroupCounts);
            commandEncoder.endEncoding()
        }
    }
    
    override func apply() {
        
        if let texture = source?.texture{
            
            apply(
                texture,
                threadgroupCounts: MTLSizeMake(histogram.size, 1, 1),
                buffer: histogramUniformBuffer)

            histogram.updateWithData(histogramUniformBuffer.contents(), dataCount: threadgroups.width)

            for s in solvers {
                let size = CGSizeMake(CGFloat(texture.width), CGFloat(texture.height))
                s.analizerDidUpdate(self, histogram: self.histogram, imageSize: size)
            }
            
            if let p = self.analyzerDidUpdate {
                p(histogram: histogram)
            }
            
        }
    }
}