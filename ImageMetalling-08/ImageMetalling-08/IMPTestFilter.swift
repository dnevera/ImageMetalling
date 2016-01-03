//
//  IMPTestFilter.swift
//  ImageMetalling-08
//
//  Created by denis svinarchuk on 02.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import IMProcessing

/// Фильтр изображения
public class IMPTestFilter:IMPFilter {
    
    /// Будем использовать фильтр управления контрастом через растяжение гистограммы
    var contrastFilter:IMPContrastFilter!
    
    /// Фильтр автоматического баланса белого
    var awbFilter:IMPAutoWBFilter!
    
    /// Анализатор линейной гистограммы изображения
    var sourceAnalyzer:IMPHistogramAnalyzer!
    
    /// Солвер анализатора гистограммы расчета границ светлот изображения
    let rangeSolver = IMPHistogramRangeSolver()

    public required init(context: IMPContext) {
        super.init(context: context)
        
        //  Инициализируем фильтры в контексте
        contrastFilter = IMPContrastFilter(context: context)
        awbFilter = IMPAutoWBFilter(context: context)
        
        // Добавляем фильтры в стек
        addFilter(contrastFilter)
        addFilter(awbFilter)
        
        // Инициализируем анализатор гистограммы
        sourceAnalyzer = IMPHistogramAnalyzer(context: self.context)
        
        // добавляем к анализатору солвер поиска границ светлот
        sourceAnalyzer.addSolver(rangeSolver)
        
        // Добавляем к фильтру наблюдающий хендлер к фильтру для
        // для передачи текущего фрейма изображения анализатору
        addSourceObserver { (source) -> Void in
            self.sourceAnalyzer.source = source
        }

        // Добавляем к анализатору наблюдающий хендлер обновления расчетов анализа
        sourceAnalyzer.addUpdateObserver({ (histogram) -> Void in
            // устанавливаем при каждом изменении изображения границы светлот в контрастном фильтре
            self.contrastFilter.adjustment.minimum = self.rangeSolver.minimum
            self.contrastFilter.adjustment.maximum = self.rangeSolver.maximum
        })

    }
}