//
//  IMPHistogramAnalizer.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 28.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit
import Accelerate

///
/// Анализатор гистограммы базирующийся на фрейморке Apple Accelerate.
/// А именно vImage_xxx 
///
class IMPHistogramVImageAnalyzer: IMPHistogramAnalyzer {
    
    required init(context aContext: DPContext!) {
        super.init(context: aContext)
        kernel_impHistogram = DPFunction(functionName: "kernel_impHistogramVImageRGBY", context: self.context)
    }

    required init!(function: String, context aContext: DPContext!) {
        fatalError("init(function:context:) has not been implemented")
    }
 
    //
    // Функция подготовки текстуры к анализу в vImageHistogramCalculation_ARGB8888.
    // Иногда нам нужна нестандартная гистограмма, например для специфического анализа 
    // перцептуальных характеристик производимых в цветовом пространстве отличном от RGB.
    // Более того, мы хотим сразуже расчитывать канал яркости, и вместо Alpha-канала будем записывать 
    // в текстуру занчение канала яркости. 
    //
    private var kernel_impHistogram:DPFunction!
    
    //
    // Буфер обмена картинки и DSP
    //
    private var imageBuffer:MTLBuffer?
    
    private var analizeTexture:DPTextureRef?
    
    private var scaleFilter:DPPassFilter?

    override func apply() {

        let width  = Int(floor(Float(self.source.texture.width) * self.downScaleFactor))
        let height = Int(floor(Float(self.source.texture.height) * self.downScaleFactor))
        
        let threadgroupCounts = MTLSizeMake(Int(self.functionThreads), Int(self.functionThreads), 1)
        
        //
        // Вычисляем количество групп вычислительных ядер
        //
        let threadgroups = MTLSizeMake(
            (width  + threadgroupCounts.width ) / threadgroupCounts.width ,
            (height + threadgroupCounts.height) / threadgroupCounts.height,
            1)


        let commandBuffer = self.context.beginCommand()
        
        //
        // Первый большой МИНУС такого подхода: мы вынуждены выделять память под дополнительную текстуру 
        // с подоготовленными для анализа данными.
        //
        // Справедливости ради - это было бы не нужно для простой обработки гистограммы, но мы хотим не просто 
        // получать гистограмму в RGB-прсотранстве, а в произвольном пространстве необходимом для нашего анализа.
        //
        if analizeTexture?.width != self.source.texture.width || analizeTexture?.height != self.source.texture.height {
            let textureDescription = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
                self.source.texture.pixelFormat,
                width: width,
                height:height, mipmapped: false)
            analizeTexture = self.context.device.newTextureWithDescriptor(textureDescription)
        }
        
        let commandEncoder = commandBuffer.computeCommandEncoder()
        
        commandEncoder.setComputePipelineState(kernel_impHistogram.pipeline);
        commandEncoder.setTexture(self.source.texture, atIndex:0)
        commandEncoder.setTexture(analizeTexture, atIndex:1)
        commandEncoder.setBuffer(regionUniformBuffer,    offset:0, atIndex:0)
        commandEncoder.setBuffer(scaleUniformBuffer,     offset:0, atIndex:1)

        
        //
        // Запускаем вычисления
        //
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts);
        commandEncoder.endEncoding()

        //
        // Второй МИНУС такого подхода: выделяем еще один кусок памяти, причем памяти разделяемой CPU/GPU
        // сюда будем коипровать прилетевшую тектсуру
        //
        let imageBufferSize = width*height*4
        if imageBuffer?.length != imageBufferSize {
            imageBuffer = self.context.device.newBufferWithLength( imageBufferSize, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        }
        
        //
        // Запускаем копирование текстуры в память доступную для процессинга гистограммы в движке Accelerate
        //
        let blitEncoder = commandBuffer.blitCommandEncoder()
        
        //
        // Быстрая команда копирования текстуры в разделяемую память.
        // Тут мы кроме памяти ощутимо ничего не теряем. 
        // Копирование в контектсе памяти устройства имеет еще один существенных недостаток,
        // для наших целей: память картинки должна приведена к ращмерности кратной 64 байтам,
        // т.е. произвольный даунсемплинг в таком варианте невозможен
        //
        blitEncoder.copyFromTexture(analizeTexture!,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: MTLSize(width: width, height: height, depth: 1),
            toBuffer: imageBuffer!,
            destinationOffset: 0,
            destinationBytesPerRow: width*4,
            destinationBytesPerImage: 0)
        blitEncoder.endEncoding()
        
        //
        // Выполняем контекст
        //
        self.context.commitCommand()
        
        //
        // Подготавливаемся к вычислению гистограммы на движеке акселерации
        //
        var vImage = vImage_Buffer(
            data: (imageBuffer?.contents())!,
            height: vImagePixelCount(analizeTexture!.height),
            width: vImagePixelCount(analizeTexture!.width),
            rowBytes: analizeTexture!.width*4)

        let red   = [vImagePixelCount](count: Int(kIMP_HistogramSize), repeatedValue: 0)
        let green = [vImagePixelCount](count: Int(kIMP_HistogramSize), repeatedValue: 0)
        let blue  = [vImagePixelCount](count: Int(kIMP_HistogramSize), repeatedValue: 0)
        let alpha = [vImagePixelCount](count: Int(kIMP_HistogramSize), repeatedValue: 0)
        
        let redPtr   = UnsafeMutablePointer<vImagePixelCount>(red)
        let greenPtr = UnsafeMutablePointer<vImagePixelCount>(green)
        let bluePtr  = UnsafeMutablePointer<vImagePixelCount> (blue)
        let alphaPtr = UnsafeMutablePointer<vImagePixelCount>(alpha)
        
        let rgba = [redPtr, greenPtr, bluePtr, alphaPtr]

        //
        // Быстро (быстрее чем на GPU) вычисляем гистограмму
        //
        let hist = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>>(rgba)
        vImageHistogramCalculation_ARGB8888(&vImage, hist, 0)
        
        // обновляем структуру гистограммы с которой уже будем работать
        histogram.updateWithRed(red, green: green, blue: blue, alpha: alpha)
    }

 }
