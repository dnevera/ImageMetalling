//
//  ViewController.swift
//  ImageMetalling-04
//
//  Created by denis svinarchuk on 12.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit

//
// Просто конструируем фильтр на основе kernel-функции
//
class IMPHSVFilter:DPFilter {
    
    init(context aContext: DPContext!, function:String) {
        super.init(context: aContext)
        self.addFunction(DPFunction(functionName: function, context: aContext))
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
    func filterTest(filter: DPFilter, provider:DPImageProvider) -> Float {
        
        //
        // Источник
        //
        filter.source = provider
        
        //
        // Первая метка
        //
        let t1 = NSDate.timeIntervalSinceReferenceDate()
        
        //
        // Пусть будет 10 раз
        //
        let times = 10
        
        for _ in 0...times{
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
        
        return Float(t2-t1)/Float(times)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //
        // Загружаем картинку
        //
        let provider = DPUIImageProvider.newWithImage(UIImage(named: "test.jpg"), context: context)
        
        //
        // Сначала прогоняем тест с реализацией в лоб
        //
        var filter = IMPHSVFilter(context: context, function: "kernel_original_adjustHSV")
        
        let t1 = self.filterTest(filter, provider: provider)
        
        //
        // Картинка была загружена большая, что бы iOS не отстрелил нам приложение 
        // чистим результаты деятельности фильра. Тоже самое можно было сделать через 
        // autoreleasepool, но мы любим контролировать память самостоятельно
        //
        filter.flush()
        
        //
        // Затем c оптимиpированной версией
        //
        filter = IMPHSVFilter(context: context, function: "kernel_fast_adjustHSV")
        
        let t2 = self.filterTest(filter, provider: provider)
        
        filter.flush()
        
        //
        // Результат
        //
        NSLog(" *** Время(%@:%@) оригинальной функции = %.2f, оптимизированной = %.2f, выигрыш = %.2f%%",
            UIDevice .currentDevice().model, filter.context.device.name!, t1, t2, (t1-t2)/(t1+t2) * 100.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

