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
class IMPHistogram {
    
    ///
    /// Фиксированная размерность гистограмы. Всегда будем подразумевать 256.
    ///
    let size = vDSP_Length(kIMP_HistogramSize)
    
    ///
    /// Поканальная таблица счетов. Используем представление в числах с плавающей точкой.
    /// Нужно это для упрощения выполнения дополнительных акселерированных вычислений на DSP,
    /// поскольку все операции на DSP выполняются либо во float либо в double.
    ///
    var channels:[[Float]];
    
    ///
    /// Конструктор пустой гистограммы
    ///
    init(){
        channels = [[Float]](count: Int(kIMP_HistogramChannels), repeatedValue: [Float](count: Int(kIMP_HistogramSize), repeatedValue: 0))
    }
    
    ///
    /// Конструктор копии.
    ///
    init(channels:[[Float]]){
        self.channels = channels
    }
    
    ///
    /// Метод обновления данных котейнера гистограммы.
    ///
    /// - parameter dataIn: обновить значение интенсивностей по сырым данным. Сарые данные должны быть преставлены в формате IMPHistogramBuffer.
    ///
    func updateWithData(dataIn: UnsafeMutablePointer<Void>){
        let address = UnsafePointer<UInt32>(dataIn)
        self.clearHistogram()
        for c in 0..<channels.count{
            self.updateChannel(&channels[c], address: address, index: c)
        }
    }
 
    func updateWithData(dataIn: UnsafeMutablePointer<Void>, dataCount: Int){
        self.clearHistogram()
        for i in 0..<dataCount{
            let dataIn = UnsafePointer<IMPHistogramBuffer>(dataIn)+i
            let address = UnsafePointer<UInt32>(dataIn)
            for c in 0..<channels.count{
                var data:[Float] = [Float](count: Int(self.size), repeatedValue: 0)
                self.updateChannel(&data, address: address, index: c)
                self.addFromData(&data, toChannel: &channels[c])
            }
        }
    }
    
    func updateWithRed(red:[vImagePixelCount], green:[vImagePixelCount], blue:[vImagePixelCount], alpha:[vImagePixelCount]){
        self.clearHistogram()
        self.updateChannel(&channels[0], address: UnsafePointer<vImagePixelCount>.init(red),   index: 0)
        self.updateChannel(&channels[1], address: UnsafePointer<vImagePixelCount>.init(blue),  index: 0)
        self.updateChannel(&channels[2], address: UnsafePointer<vImagePixelCount>.init(green), index: 0)
        self.updateChannel(&channels[3], address: UnsafePointer<vImagePixelCount>.init(alpha), index: 0)
    }
    
    func updateWithConinuesData(dataIn: UnsafeMutablePointer<UInt32>){
        self.clearHistogram()
        let address = UnsafePointer<UInt32>(dataIn)
        for c in 0..<channels.count{
            self.updateContinuesData(&channels[c], address: address, index: c)
        }
    }

    
    //
    // Утилиты работы с векторными данными на DSP
    //
    // ..........................................
    
    //
    // Реальная размерность беззнакового целого. Может отличаться в зависимости от среды исполнения.
    //
    private let dim = sizeof(UInt32)/sizeof(UInt);
    
    //
    // Обновить данные контейнера гистограммы и сконвертировать из UInt во Float
    //
    private func updateChannel(inout channel:[Float], address:UnsafePointer<UInt32>, index:Int){
        let p = address+Int(self.size)*Int(index)
        let dim = self.dim<1 ? 1 : self.dim;
        //
        // ковертим из единственно возможного в текущем MSL (atomic_)[uint] во [float]
        //
        vDSP_vfltu32(p, dim, &channel, 1, self.size);
    }

    private func updateChannel(inout channel:[Float], address:UnsafePointer<vImagePixelCount>, index:Int){
        let p = UnsafePointer<UInt32>(address+Int(self.size)*Int(index))
        let dim = sizeof(vImagePixelCount)/sizeof(UInt32);
        //
        // ковертим из единственно возможного в текущем MSL (atomic_)[uint] во [float]
        //
        vDSP_vfltu32(p, dim, &channel, 1, self.size);
    }

    private func updateContinuesData(inout channel:[Float], address:UnsafePointer<UInt32>, index:Int){
        let p = address+Int(kIMP_HistogramChannels)
        vDSP_vfltu32(p, 1, &channel, 1, self.size);
    }

    private func addFromData(inout data:[Float], inout toChannel:[Float]){
        vDSP_vadd(&toChannel, 1, &data, 1, &toChannel, 1, self.size)
    }

    private func clearChannel(inout channel:[Float]){
        var zero:Float = 0
        vDSP_vfill(&zero, &channel, 1, vDSP_Length(self.size))
    }
    
    private func clearHistogram(){
        for c in 0..<channels.count{
            self.clearChannel(&channels[c]);
        }
    }
    
}
