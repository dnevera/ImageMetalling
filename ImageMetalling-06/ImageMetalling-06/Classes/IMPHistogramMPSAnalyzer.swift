//
//  IMPHistogramAnalizer.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 28.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit
import MetalPerformanceShaders

///
/// Анализатор гистограммы базирующийся на фрейморке Apple: Metal Performance Shaders.
/// Не поддерживается 5s!
///
class IMPHistogramMPSAnalyzer: IMPHistogramAnalyzer {
    
    override var isHardwareSupported:Bool{
        get{
            return MPSSupportsMTLDevice(self.context.device)
        }
    }
    
    required init(context aContext: DPContext!) {
        super.init(context: aContext)
                
        //
        // Конструируем гистограмму MPS
        //
        var imageHistogramInfo = MPSImageHistogramInfo(
            numberOfHistogramEntries: Int(kIMP_HistogramSize),
            histogramForAlpha: true,
            minPixelValue: vector_float4(x: 0, y: 0, z: 0, w: 0),
            maxPixelValue: vector_float4(x: 1, y: 1, z: 1, w: 1))
        mpsHistogram = MPSImageHistogram(device: self.context.device, histogramInfo: &imageHistogramInfo)
        
        scaleFilter = DPPassFilter(context: self.context)
        
        // создаем память в устройстве под контейнер счета
        histogramMPSUniformBuffer = self.context.device.newBufferWithLength(imageHistogramInfo.numberOfHistogramEntries * sizeof(UInt32) * 4, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
    }

    required init!(function: String, context aContext: DPContext!) {
        fatalError("init(function:context:) has not been implemented")
    }
    
    //
    // Буфер обмена контейнера счета с GPU
    //
    internal var histogramMPSUniformBuffer:MTLBuffer!
    
    //
    // Быстрый эпловский подсчет гистограммы
    //
    private var mpsHistogram:MPSImageHistogram?
    
    //
    // Даунсэмплер, для mps не используем кернел-функций поэтому будем даунсемплить через фильтр
    //
    private var scaleFilter:DPPassFilter?
    
    private var sampledTexure:DPTextureRef?
    
    override func apply() {
        
        let commandBuffer = self.context.beginCommand()
        
        let blitEncoder = commandBuffer.blitCommandEncoder()
        blitEncoder.fillBuffer(histogramMPSUniformBuffer, range: NSMakeRange(0, sizeof(IMPHistogramBuffer)), value: 0)
        blitEncoder.endEncoding()
        
        if downScaleFactor == 1.0 {
            sampledTexure = self.source.texture
        }
        else {
            scaleFilter?.transform.resampleFactor = CGFloat(self.downScaleFactor)
            scaleFilter?.source=self.source
            sampledTexure = scaleFilter?.destination.texture
        }
                
        mpsHistogram?.encodeToCommandBuffer(commandBuffer, sourceTexture: sampledTexure!, histogram: histogramMPSUniformBuffer, histogramOffset: 0)
        mpsHistogram?.clipRectSource = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: self.source.texture.width, height: self.source.texture.height, depth: 1))
        
        self.context.commitCommand()
        
        // обновляем структуру гистограммы с которой уже будем работать
        histogram.updateWithConinuesData(UnsafeMutablePointer<UInt32>(histogramMPSUniformBuffer!.contents()))
    }
}
