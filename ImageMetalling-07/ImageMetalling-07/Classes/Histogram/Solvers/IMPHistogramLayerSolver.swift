//
//  IMPHistogramLayerSolver.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 18.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

class IMPHistogramLayerSolver: IMPFilter, IMPHistogramSolver {
    
    enum IMPHistogramType{
        case PDF
        case CDF
    }
    
    var layer = IMPHistogramLayer(
        components: (
            float4(x: 1, y: 0, z: 0, w: 0.5),
            float4(x: 0, y: 1, z: 0, w: 0.5),
            float4(x: 0, y: 0, z: 1, w: 0.5),
            float4(x: 1, y: 1, z: 1, w: 0.3)),
        backgroundColor: float4(x:0.1,y:0.1,z:0.1,w:1),
        backgroundSource: false
        ){
        didSet{
            memcpy(layerUniformBiffer.contents(), &layer, layerUniformBiffer.length)
            self.dirty = true;
        }
    }
    
    var histogramType:(type:IMPHistogramType,power:Float) = (type:.PDF,power:1){
        didSet{
            self.dirty = true;
        }
    }
    
    required init(context: IMPContext) {
        super.init(context: context)
        kernel = IMPFunction(context: self.context, name: "kernel_histogramLayer")
        self.addFunction(kernel)
        channelsUniformBuffer = self.context.device.newBufferWithLength(sizeof(UInt), options: .CPUCacheModeDefaultCache)
        histogramUniformBuffer = self.context.device.newBufferWithLength(sizeof(IMPHistogramFloatBuffer), options: .CPUCacheModeDefaultCache)
        layerUniformBiffer = self.context.device.newBufferWithLength(sizeof(IMPHistogramLayer), options: .CPUCacheModeDefaultCache)
        memcpy(layerUniformBiffer.contents(), &layer, sizeof(IMPHistogramLayer))
    }
    
    func analizerDidUpdate(analizer: IMPHistogramAnalyzer, histogram: IMPHistogram, imageSize: CGSize) {
        
        var pdf:IMPHistogram;
        
        switch(histogramType.type){
        case .PDF:
            pdf = histogram.pdf()
        case .CDF:
            pdf = histogram.cdf(1, power: histogramType.power)
        }
        
        for c in 0..<pdf.channels.count{
            let address =  UnsafeMutablePointer<Float>(histogramUniformBuffer.contents())+c*pdf.size
            memset(address, 0, sizeof(Float)*pdf.size)
            memcpy(address, pdf.channels[c], sizeof(Float)*pdf.size)
        }
        
        var channels = pdf.channels.count
        memcpy(channelsUniformBuffer.contents(), &channels, sizeof(UInt))
        
        self.dirty = true;
    }
    
    override func configure(function: IMPFunction, command: MTLComputeCommandEncoder) {
        if (kernel == function){
            command.setBuffer(histogramUniformBuffer, offset: 0, atIndex: 0)
            command.setBuffer(channelsUniformBuffer,  offset: 0, atIndex: 1)
            command.setBuffer(layerUniformBiffer,     offset: 0, atIndex: 2)
        }
    }
    
    private var kernel:IMPFunction!
    private var layerUniformBiffer:MTLBuffer!
    private var histogramUniformBuffer:MTLBuffer!
    private var channelsUniformBuffer:MTLBuffer!
}
