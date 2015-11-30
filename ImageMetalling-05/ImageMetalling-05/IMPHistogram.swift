//
//  IMPHistogram.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 30.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Accelerate

///
/// Представление гистограммы для произвольного цветового пространства 
/// с максимальным количеством каналов от одного до 4х.
///
struct IMPHistogram {
    
    ///
    /// Фиксированная размерность гистограмы
    ///
    let size = vDSP_Length(kIMP_HistogramSize)
    
    ///
    /// Количество всех счетов независимо от канала
    ///
    var count:Int = 0
    
    ///
    /// Поканальная таблица счетов. Используем представление в числах с плавающей точкой. 
    /// Нужно это для упрощения дополнительный акселерированных вычислений на DSP, поскольку все операции выполняются
    /// либо во float либо в double.
    ///
    var channels:[[Float]] = [[Float]](count: Int(kIMP_HistogramChannels), repeatedValue: [Float](count: Int(kIMP_HistogramSize), repeatedValue: 0))
    
    //
    // Реальная размерность беззнакового целого. Может отличаться в зависимости от среды исполнения.
    //
    private let dim = sizeof(UInt32)/sizeof(UInt);
    
    //
    // Заголовок блока памяти контейнера содержит только клоичество счетов
    //
    private let headerSize = sizeofValue(IMPHistogramBuffer().count)
    
    private func updateChannel(inout channel:[Float], address:UnsafePointer<UInt32>, index:Int){
        let p = address+headerSize+Int(self.size)*Int(index)
        let dim = self.dim<1 ? 1 : self.dim;
        //
        // ковертим из единственно возможного в текущем MSL (atomic_)[uint] во [float]
        //
        vDSP_vfltu32(p, dim, &channel, 1, self.size);
    }
    
    ///
    /// Метод одновления данных котейнера гистограммы.
    ///
    mutating func updateWithData(dataIn: UnsafeMutablePointer<Void>){
        
        let address = UnsafePointer<UInt32>(dataIn)
        
        memcpy(&count, address, headerSize);
        
        for c in 0..<channels.count{
            self.updateChannel(&channels[c], address: address, index: 0)
        }
    }
    
    private func updateSum(inout A A:[Float], inout B:[Float], size:Int, scale:Float){
        
        var one:Float = 1
        let rsize = vDSP_Length(size)
        
        vDSP_vrsum(&A, 1, &one, &A, 1, rsize)
        
        if scale > 0 {
            var denom:Float = 0;
            vDSP_maxv (&A, 1, &denom, rsize);
            
            denom *= scale
            
            vDSP_vsdiv(&A, 1, &denom, &A, 1, rsize);
        }
    }

    ///
    /// Текущий CDF (комулятивная функция распределения) гистограммы
    ///
    func cdf(scale:Float) ->IMPHistogram{
        var _cdf = IMPHistogram(count: count, channels:channels);
        
        for c in 0..<_cdf.channels.count{
            updateSum(A: &_cdf.channels[c], B: &_cdf.channels[c], size: _cdf.channels[c].count, scale:scale)
        }
        
        return _cdf;
    }
}
