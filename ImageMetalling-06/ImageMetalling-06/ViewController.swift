//
//  ViewController.swift
//  ImageMetalling-06
//
//  Created by denis svinarchuk on 03.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit
import MetalPerformanceShaders

class IMPTestFilter:DPFilter{
    
    var analyzer:IMPHistogramAnalyzer?
    
    init!(context aContext: DPContext!, analyzer:IMPHistogramAnalyzer?) {
        
        super.init(context: aContext)
        
        if (analyzer != nil) {
            self.analyzer = analyzer
            self.analyzer?.downScaleFactor = 1
            
            self.willStartProcessing = { (source) in
                analyzer!.source = source
            }
        }
    }

    required init!(context aContext: DPContext!) {
        fatalError("init(context:) has not been implemented")
    }
    
}

class ViewController: UIViewController {

    let context = DPContext.newContext()
    
    //
    // Замеряем время исполнения функции фильтра по одной и тойже картинке много раз
    //
    func filterTest(filter: IMPTestFilter, provider:DPImageProvider) -> (all: Float, time: Float) {
        
        //
        // Источник
        //
        filter.source = provider
        
        var tac:NSTimeInterval = 0
        var tacl = NSDate.timeIntervalSinceReferenceDate()
        
        filter.analyzer?.analyzerDidUpdate = {
            tac += NSDate.timeIntervalSinceReferenceDate() - tacl
            tacl = NSDate.timeIntervalSinceReferenceDate()
        }
        
        //
        // Первая метка
        //
        let t1 = NSDate.timeIntervalSinceReferenceDate()
        
        //
        // Пусть будет N раз
        //
        let times = 10
        
        for _ in 0..<times{
            //
            // Заставляем фильтр не филонить
            //
            filter.dirty = true
            //
            // А запускать функцию каждый раз
            //
            filter.apply()
        }
        
        //
        // Метка в конце
        //
        let t2 = NSDate.timeIntervalSinceReferenceDate()
        
        return (Float(t2-t1)/Float(times), Float(tac)/Float(times))
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let analyzerAT:IMPHistogramAnalyzer?     = IMPHistogramATAnalyzer.newWithContext(self.context)
        let analyzerMPS:IMPHistogramAnalyzer?    = IMPHistogramMPSAnalyzer.newWithContext(self.context)
        let analyzerDSP:IMPHistogramAnalyzer?    = IMPHistogramDSPReduceAnalyzer.newWithContext(self.context)
        let analyzerVImage:IMPHistogramAnalyzer? = IMPHistogramVImageAnalyzer.newWithContext(self.context)

        let analizers = [
            (analizer: analyzerDSP,   title: "через сборку на DSP ", name: "DSP"),
            (analizer: analyzerMPS,   title: "через MPS           ", name: "MPS"),
            (analizer: analyzerVImage,title: "через vImage        ", name: "VImage"),
            (analizer: analyzerAT,    title: "через atomic types  ", name: "AT"),
        ]
        
        //
        // Загружаем картинку
        //
        let provider = DPUIImageProvider.newWithImage(UIImage(named: "test.jpg"), context: context)
        
        let size = Float(provider.texture.width * provider.texture.height * 4)
        let mb   = powf(1024, 2)

        var messages = [String]()
        
        for a in analizers{
            if a.analizer?.isHardwareSupported == false{
                messages.append(String(format:" *** %@ не поддерживается...",a.name))
                continue
            }
            
            if let filter = IMPTestFilter(context: context, analyzer: a.analizer){
                let t = self.filterTest(filter, provider: provider)
                let rate = size/(t.time == 0 ? 0 : t.time)/mb
                print(" \(a.name) = \(filter.analyzer!.histogram.channels[0]);")
                let s = String(format:" *** скорость расчета гистограммы %@: %.2fMb/s вермя счета = %.4fs общее время фильтра = %.4f", a.title, rate, t.time, t.all)
                messages.append(s)
                filter.flush()
            }
            print("\n----\n")
            sleep(1)
        }
        
        NSLog(" *** Модель: %@:%@", UIDevice .currentDevice().model, provider.context.device.name!)
        for m in messages{
            NSLog("%@",m)
        }
    }
    
}

