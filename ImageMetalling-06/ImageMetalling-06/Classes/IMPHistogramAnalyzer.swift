//
//  IMPHistogramAnalyzer.swift
//  ImageMetalling-06
//
//  Created by denis svinarchuk on 07.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit
import MetalPerformanceShaders

///
/// Базовый анализатор гистограммы четырех канальной гистограммы.
///
class IMPHistogramAnalyzer: DPFilter {
    
    var isHardwareSupported:Bool{
        get{
            return true
        }
    }
    
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
            memcpy(scaleUniformBuffer.contents(), &downScaleFactor, sizeof(DPCropRegion))
        }
    }
    internal var scaleUniformBuffer:MTLBuffer!

    ///
    /// Регион внутри которого вычисляем гистограмму.
    ///
    var region:DPCropRegion!{
        didSet{
            regionUniformBuffer = regionUniformBuffer ?? self.context.device.newBufferWithLength(sizeof(DPCropRegion), options: MTLResourceOptions.CPUCacheModeDefaultCache)
            memcpy(regionUniformBuffer.contents(), &region, sizeof(DPCropRegion))
        }
    }
    internal var regionUniformBuffer:MTLBuffer!

    //
    // kernel-функция счета
    //
    private var kernel_impHistogramCounter:DPFunction!

    ///
    /// Конструктор анализатора с произвольным счетчиком, который
    /// задаем kernel-функцией. Главное условие совместимость с типом IMPHistogramBuffer
    /// как контейнером данных гистограммы.
    ///
    ///
    required init!(function: String, context aContext: DPContext!) {
        super.init(context: aContext)
        
        // инициализируем счетчик
        kernel_impHistogramCounter = DPFunction.newFunction(function, context: self.context)
        
        // добавляем счетчик как метод фильтра
        self.addFunction(kernel_impHistogramCounter);

        defer{
            region = DPCropRegion(top: 0, right: 0, left: 0, bottom: 0)
            downScaleFactor = 1.0
        }
    }

    required init!(context aContext: DPContext!) {
        super.init(context: aContext)
        defer{
            region = DPCropRegion(top: 0, right: 0, left: 0, bottom: 0)
            downScaleFactor = 1.0
        }
    }

    ///
    /// Замыкание выполняющаеся после завершения расчета значений солвера.
    /// Замыкание можно определить для обновления значений пользовательской цепочки фильтров.
    ///
    var analyzerDidUpdate: (() -> Void)?
    
    ///
    /// Перегружаем свойство источника: при каждом обновлении нам нужно выполнить подсчет новой статистики.
    ///
    override var source:DPImageProvider!{
        didSet{
            super.source = source
            if source.texture != nil {
                // выполняем фильтр
                self.apply()
                
                if let analyzerDidUpdate = self.analyzerDidUpdate {
                    analyzerDidUpdate()
                }
            }
        }
    }
    
    ///
    /// Выходная текстура должна совпадать с входной
    ///
    override var texture:DPTextureRef?{
        get{
            if (self.dirty){
                self.apply()
            }
            return self.source.texture
        }
        set{
            super.texture = texture
        }
    }
    
    func apply(threadgroupCounts: MTLSize, buffer:MTLBuffer) {
        
        let width  = Int(floor(Float(self.source.texture.width) * self.downScaleFactor))
        let height = Int(floor(Float(self.source.texture.height) * self.downScaleFactor))
        
        //
        // Вычисляем количество групп вычислительных ядер
        //
        let threadgroups = MTLSizeMake(
            (width  + threadgroupCounts.width ) / threadgroupCounts.width ,
            (height + threadgroupCounts.height) / threadgroupCounts.height,
            1)
        
        let commandBuffer = self.context.commandQueue.commandBuffer()
        
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
        commandEncoder.setComputePipelineState(kernel_impHistogramCounter.pipeline);
        commandEncoder.setTexture(self.source.texture, atIndex:0)
        commandEncoder.setBuffer(buffer, offset:0, atIndex:0)
        commandEncoder.setBuffer(regionUniformBuffer,    offset:0, atIndex:1)
        commandEncoder.setBuffer(scaleUniformBuffer,     offset:0, atIndex:2)
        
        //
        // Запускаем вычисления
        //
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}