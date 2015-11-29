//
//  IMPHistogramAnalizer.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 28.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit
import Accelerate

struct IMPHistogram {
    
    let size = vDSP_Length(kIMP_HistogramSize)

    var count:Int = 0
    var r:[Float] = [Float](count: Int(kIMP_HistogramSize), repeatedValue: 0)
    var g:[Float] = [Float](count: Int(kIMP_HistogramSize), repeatedValue: 0)
    var b:[Float] = [Float](count: Int(kIMP_HistogramSize), repeatedValue: 0)
    var y:[Float] = [Float](count: Int(kIMP_HistogramSize), repeatedValue: 0)
    
    private let dim = sizeof(UInt32)/sizeof(UInt);
    private let startIndex = sizeofValue(IMPHistogramBuffer().count)

    private func updateChannel(inout channel:[Float], address:UnsafePointer<UInt32>, index:Int){
        let p = address+startIndex+Int(self.size)*Int(index)
        let dim = self.dim<1 ? 1 : self.dim;
        vDSP_vfltu32(p, dim, &channel, 1, self.size);
    }
    
    mutating func updateWithData(dataIn: UnsafeMutablePointer<Void>){
        
        let address = UnsafePointer<UInt32>(dataIn)

        memcpy(&count, address, startIndex);
        
        self.updateChannel(&r, address: address, index: 0)
        self.updateChannel(&g, address: address, index: 0)
        self.updateChannel(&b, address: address, index: 0)
        self.updateChannel(&y, address: address, index: 0)
        
        print(" y  = \(y)")
    }
}

///
/// Анализатор гистограммы RGB(Y)
///
class IMPHistogramAnalizer: DPFilter {
    
    //
    // Тут храним наши вычисленные распределения поканальных интенсивностей.
    //
    var histogram = IMPHistogram()
    
    //
    // Буфер обмена контейнера счета с GPU
    //
    private var histogramUniformBuffer:MTLBuffer!
    
    //
    // kernel-функция счета
    //
    private var kernel_impHistogramCounter:DPFunction!
    
    
    required init!(context aContext: DPContext!) {
        super.init(context: aContext)
        
        // инициализируем счетчик
        kernel_impHistogramCounter = DPFunction.newFunction("kernel_impHistogramCounter", context: self.context)
        
        // создаем память в устройстве под контейнер счета
        histogramUniformBuffer = self.context.device.newBufferWithLength(sizeof(IMPHistogramBuffer), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        // добавляем счетчик как метод фильтра
        self.addFunction(kernel_impHistogramCounter);
    }
    
    override func configureBlitUniform(commandEncoder: MTLBlitCommandEncoder!) {
        commandEncoder.fillBuffer(histogramUniformBuffer, range: NSMakeRange(0, sizeof(IMPHistogramBuffer)), value: 0)
    }
    
    override func configureFunction(function: DPFunction!, uniform commandEncoder: MTLComputeCommandEncoder!) {
        commandEncoder.setBuffer(histogramUniformBuffer, offset:0, atIndex:0);
    }
    
    override var source:DPImageProvider!{
        didSet{
            super.source = source
            if source.texture != nil {
                self.apply()
                self.processHistogramm()
            }
        }
    }
    
    func processHistogramm(){
        histogram.updateWithData(histogramUniformBuffer.contents())
    }
    
}
