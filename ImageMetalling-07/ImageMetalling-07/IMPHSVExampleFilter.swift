//
//  IMPHSVFilter.swift
//  IMProcessing
//
//  Created by denis svinarchuk on 22.12.15.
//  Copyright © 2015 Dehancer.photo. All rights reserved.
//

import Foundation
import Metal
import simd
import IMProcessing

///
/// Просто определяем настройки нашего HSV процессинга
///
public enum IMProcessingExample{
    
     public struct hsv {
        ///
        /// Карта перекрытий ближайших цветов из цветового круга HSV пространства
        ///
        public static let hueRamps:[float4] = [kIMP_Reds, kIMP_Yellows, kIMP_Greens, kIMP_Cyans, kIMP_Blues, kIMP_Magentas]

        ///
        /// Ширина перекрытия ближайших цветов. Задает насколько далеко могут отстоять цвета в пространстве HSV
        ///
        public static var hueOverlapFactor:Float  = 1.4

        ///
        /// Интервал цветового круга
        ///
        private static let hueRange = Range<Int>(0..<360)
    }
}

internal extension Float32{

    ///
    /// Вычисляем веса перекрытия ближайших цветов как функцию нормального распределения
    /// с µ в центре секторы и ß равной ширине сектора
    ///
    ///
    ///  - parameter ramp:    параметры сектора и перекрытия с ближайшими
    ///  - parameter overlap: ширина финального перекрытия
    ///
    ///  - returns: вес перекрытия цветов в конкретной точке сектора
    ///
    func overlapWeight(ramp ramp:float4, overlap:Float = IMProcessing.hsv.hueOverlapFactor) -> Float32 {

        //
        // сигму задаем по ширине сектора
        //
        var sigma = (ramp.z-ramp.y)
        
        //
        // максимум чистого цвета
        //
        var mu    = (ramp.w+ramp.x)/2.0

        if ramp.y>ramp.z {
            
            //
            // Сектор содержит нулевую точку круга
            //
            
            sigma = (IMProcessingExample.hsv.hueRange.endIndex.float-ramp.y+ramp.z)
            
            if (self >= 0.float) && (self <= IMProcessingExample.hsv.hueRange.endIndex.float/2.0) {
                mu    = (IMProcessingExample.hsv.hueRange.endIndex.float-ramp.y-ramp.z) / 2.0
            }else{
                mu    = (ramp.y+ramp.z)
            }
        }

        //
        // Вес как функция нормального распределения Гаусса
        //
        return self.gaussianPoint(fi: 1, mu: mu, sigma: sigma * overlap)
    }
}

internal extension SequenceType where Generator.Element == Float32 {

    ///  Расчет полной кривой весов для конкретного сектора
    ///
    ///  - parameter ramp:    сектор
    ///  - parameter overlap: ширина перекрытия
    ///
    ///  - returns: возвращает дискретное нормальное распределение весов
    ///
    func overlapWeightsDistributionExample(ramp ramp:float4, overlap:Float = IMProcessing.hsv.hueOverlapFactor) -> [Float32]{
        var a = [Float32]()
        for i in self{
            a.append(i.overlapWeight(ramp: ramp, overlap: overlap))
        }
        return a
    }

    func overlapWeightsDistribution(ramp ramp:float4, overlap:Float = IMProcessing.hsv.hueOverlapFactor) -> NSData {
        let f:[Float32] = overlapWeightsDistributionExample(ramp: ramp, overlap: overlap) as [Float32]
        return NSData(bytes: f, length: f.count)
    }

}

// MARK: - Определяем сервисное расширение структуры управления HSV
public extension IMPHSVAdjustment{
    
    public var reds:    IMPHSVLevel{ get { return levels.0 } set{ levels.0 = newValue }}
    public var yellows: IMPHSVLevel{ get { return levels.1 } set{ levels.1 = newValue }}
    public var greens:  IMPHSVLevel{ get { return levels.2 } set{ levels.2 = newValue }}
    public var cyans:   IMPHSVLevel{ get { return levels.3 } set{ levels.3 = newValue }}
    public var blues:   IMPHSVLevel{ get { return levels.4 } set{ levels.4 = newValue }}
    public var magentas:IMPHSVLevel{ get { return levels.5 } set{ levels.5 = newValue }}
    
    public subscript(index:Int) -> IMPHSVLevel {
        switch(index){
        case 0:
            return levels.0
        case 1:
            return levels.1
        case 2:
            return levels.2
        case 3:
            return levels.3
        case 4:
            return levels.4
        case 5:
            return levels.5
        default:
            return master
        }
    }
    
    public mutating func hue(index index:Int, value newValue:Float){
        switch(index){
        case 0:
            levels.0.hue = newValue
        case 1:
            levels.1.hue = newValue
        case 2:
            levels.2.hue = newValue
        case 3:
            levels.3.hue = newValue
        case 4:
            levels.4.hue  = newValue
        case 5:
            levels.5.hue  = newValue
        default:
            master.hue  = newValue
        }
    }
    
    public mutating func saturation(index index:Int, value newValue:Float){
        switch(index){
        case 0:
            levels.0.saturation = newValue
        case 1:
            levels.1.saturation = newValue
        case 2:
            levels.2.saturation = newValue
        case 3:
            levels.3.saturation = newValue
        case 4:
            levels.4.saturation  = newValue
        case 5:
            levels.5.saturation  = newValue
        default:
            master.saturation  = newValue
        }
    }
    
    public mutating func value(index index:Int, value newValue:Float){
        switch(index){
        case 0:
            levels.0.value = newValue
        case 1:
            levels.1.value = newValue
        case 2:
            levels.2.value = newValue
        case 3:
            levels.3.value = newValue
        case 4:
            levels.4.value  = newValue
        case 5:
            levels.5.value  = newValue
        default:
            master.value  = newValue
        }
    }
}

///
/// Фильтр цветовой коррекции изображения в HSV пространстве.
///
public class IMPHSVExampleFilter:IMPFilter,IMPAdjustmentProtocol{

    ///  Уровень оптимизации расчетов
    ///
    ///  - HIGH:   большая скорость, но меньшая точность за счет интерполяции 
    ///            преобразования в LUT
    ///  - NORMAL: высокая точность расчетов, но меньшая скорость. Все преобразования 
    ///            применяются ко всему изображению
    public enum optimizationLevel{
        case HIGH
        case NORMAL
    }
    
    ///
    /// Значения сдвигов по умолчанию
    ///
    public static let defaultAdjustment = IMPHSVAdjustment(
        master:   IMPHSVLevel(hue: 0.0, saturation: 0, value: 0),
        levels:  (
            IMPHSVLevel(hue: 0.0, saturation: 0, value: 0),
            IMPHSVLevel(hue: 0.0, saturation: 0, value: 0),
            IMPHSVLevel(hue: 0.0, saturation: 0, value: 0),
            IMPHSVLevel(hue: 0.0, saturation: 0, value: 0),
            IMPHSVLevel(hue: 0.0, saturation: 0, value: 0),
            IMPHSVLevel(hue: 0.0, saturation: 0, value: 0)),
        blending: IMPBlending(mode: IMPBlendingMode.NORMAL, opacity: 1)
    )
    
    ///
    /// Текущие значения корректирующих сдвигов
    ///
    public var adjustment:IMPHSVAdjustment!{
        didSet{
            
            if self.optimization == .HIGH {
                //
                // в режиме предварительного расчета LUT используем буфер для передачи в ядро 
                // предварительно подготовленный LUT преобразования
                //
                adjustmentLut.blending = adjustment.blending
                self.updateBuffer(&adjustmentLutBuffer, context:context, adjustment:&adjustmentLut, size:sizeof(IMPAdjustment))
            }
            
            //
            // обнволяем буфер обмена с ядром заполненой структурой корректировок
            //
            updateBuffer(&adjustmentBuffer, context:context, adjustment:&adjustment, size:sizeof(IMPHSVAdjustment))
            
            if self.optimization == .HIGH {
                //
                // В режиме оптимизации исполняем ядро вычисления корректирующего LUT
                //
                applyHsv3DLut()
            }
            
            dirty = true
        }
    }
    
    ///
    /// Ширина перекрытия весов соседних цветов корректирующего фильтра цвето-коррекции
    ///
    public var overlap:Float = IMProcessing.hsv.hueOverlapFactor {
        didSet{
            //
            // перерасчитываем кривую весов перекрытий
            //
            hueWeights = IMPHSVFilter.defaultHueWeights(self.context, overlap: overlap)
            if self.optimization == .HIGH {
                //
                // исполняем ядро расчета LUT-коррекции
                //
                applyHsv3DLut()
            }
            dirty = true
        }
    }
    
    ///  Сконструировать HSV фильтра.
    ///
    ///  - .HIGH используется для уменьшения вычислений в в ядрах.
    ///     Вместо расчета по каждому пикселу создается интерполирующий 64x64x64 LUT. Такой подход
    ///     может привести к появлению артефактов на изображении, но снижение количества вычислений
    ///     может быть использовано в вариантах использования фильтра в режиме live-view телефонов,
    ///     или превью изображений, когда понижение точности расчета не существенно влияет на результат.
    ///
    ///  - .Normal используется как основной режим с повышенной точностью расчетов
    ///
    ///  - parameter context:      контекст устройства
    ///  - parameter optimization: режим потимизации
    ///
    public required init(context: IMPContext, optimization:optimizationLevel) {
        
        super.init(context: context)
        
        self.optimization = optimization
        
        if self.optimization == .HIGH {
            //
            // ядро отображения 3D LUT
            //
            kernel = IMPFunction(context: self.context, name: "kernel_adjustLutD3D")
            
            //
            // ядро подготовки HSV 3D LUT
            //
            kernel_hsv3DLut = IMPFunction(context: self.context, name: "kernel_adjustHSV3DLutExample")
            
            //
            // глубина расчета HSV 3D LUT
            //
            hsv3DlutTexture = hsv3DLut(64)
        }
        else{
            kernel = IMPFunction(context: self.context, name: "kernel_adjustHSVExample")
        }
        
        //
        // Добавляем к фильтру функцию
        //
        addFunction(kernel)
        
        //
        // веса перекрытия по умолчанию
        //
        hueWeights = IMPHSVFilter.defaultHueWeights(self.context, overlap: IMProcessing.hsv.hueOverlapFactor)
        
        defer{
            //
            // Умолчательные коррекции
            //
            adjustment = IMPHSVFilter.defaultAdjustment
        }
    }

    //
    // По умолчанию создаем фильтра с "нормальным" режимом оптимизации
    //
    public convenience required init(context: IMPContext) {
        self.init(context: context, optimization:.NORMAL)
    }
    
    
    ///  Перегружаем функицю конфигурации передачи параметров в ядра
    ///
    ///  - parameter function: текущее ядро
    ///  - parameter command:  текущий коммандный энкодер
    public override func configure(function: IMPFunction, command: MTLComputeCommandEncoder) {
        if self.optimization == .HIGH {
            command.setTexture(hsv3DlutTexture, atIndex: 2)
            command.setBuffer(adjustmentLutBuffer, offset: 0, atIndex: 0)
        }
        else{
            command.setTexture(hueWeights, atIndex: 2)
            command.setBuffer(adjustmentBuffer, offset: 0, atIndex: 0)
        }
    }
    
    
    ///  Создать массив 1D-тектур с кривыми весов перекртия
    ///
    ///  - parameter context: контектс устройства
    ///
    ///  - returns: дискретное распределение весов перекрытия, каждый элемент массива 
    ///   содержит значение веса с точностью до 1º. Ядро Metal использует линейную интерполяцию 
    ///   для вычисления ближайших значений.
    ///
    public static func defaultHueWeights(context:IMPContext, overlap:Float) -> MTLTexture {
        
        //
        // Ширину берем равной периметру круга в градусах.
        //
        let width  = IMProcessingExample.hsv.hueRange.endIndex
        
        let textureDescriptor = MTLTextureDescriptor()
        
        // одномерный массив
        textureDescriptor.textureType = .Type1DArray;
        textureDescriptor.width       = width;
        textureDescriptor.height      = 1;
        textureDescriptor.depth       = 1;
        textureDescriptor.pixelFormat = .R32Float;
        
        //
        // количество текстур определяем как количество секторов
        //
        textureDescriptor.arrayLength = IMProcessing.hsv.hueRamps.count;
        textureDescriptor.mipmapLevelCount = 1;
        
        
        let region = MTLRegionMake2D(0, 0, width, 1);
        
        let hueWeights = context.device.newTextureWithDescriptor(textureDescriptor)
        
        let hues = Float.range(0..<width)
        //
        // заполняем каждую 1D текстуру массива
        //
        for i in 0..<IMProcessing.hsv.hueRamps.count{
            let ramp = IMProcessing.hsv.hueRamps[i]
            var data = hues.overlapWeightsDistribution(ramp: ramp, overlap: overlap) as [Float32]
            hueWeights.replaceRegion(region, mipmapLevel:0, slice:i, withBytes:&data, bytesPerRow:sizeof(Float32) * width, bytesPerImage:0)
        }
        
        return hueWeights;
    }
    
    
    internal static let level:IMPHSVLevel = IMPHSVLevel(hue: 0.0, saturation: 0, value: 0)
    public var adjustmentBuffer:MTLBuffer?
    public var kernel:IMPFunction!
    internal var hueWeights:MTLTexture!
    
    private  var adjustmentLut = IMPAdjustment(blending: IMPBlending(mode: IMPBlendingMode.NORMAL, opacity: 1))
    internal var adjustmentLutBuffer:MTLBuffer?
    
    private var optimization:optimizationLevel!
    
    private var kernel_hsv3DLut:IMPFunction!
    
    //
    // Вычисления LUT по настройкам HSV коррекции.
    //
    private func applyHsv3DLut(){
        
        self.context.execute({ (commandBuffer) -> Void in
            
            let width  = self.hsv3DlutTexture!.width
            let height = self.hsv3DlutTexture!.height
            let depth  = self.hsv3DlutTexture!.depth
            
            //
            // Запускаем ядра в гриде заданной размерности
            //
            let threadgroupCounts = MTLSizeMake(self.kernel_hsv3DLut.groupSize.width, self.kernel_hsv3DLut.groupSize.height,  self.kernel_hsv3DLut.groupSize.height);
            
            let threadgroups = MTLSizeMake(
                (width  + threadgroupCounts.width ) / threadgroupCounts.width ,
                (height + threadgroupCounts.height) / threadgroupCounts.height,
                (depth + threadgroupCounts.height) / threadgroupCounts.depth);
            
            let commandEncoder = commandBuffer.computeCommandEncoder()
            
            commandEncoder.setComputePipelineState(self.kernel_hsv3DLut.pipeline!)
            
            commandEncoder.setTexture(self.hsv3DlutTexture, atIndex:0)
            commandEncoder.setTexture(self.hueWeights, atIndex:1)
            commandEncoder.setBuffer(self.adjustmentBuffer, offset: 0, atIndex: 0)
            
            commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadgroupCounts)
            commandEncoder.endEncoding()
        })
    }
    
    //
    // инициализация 3D LUT тектсуры
    //
    private var hsv3DlutTexture:MTLTexture?
    private func hsv3DLut(dimention:Int) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor()
        
        textureDescriptor.textureType = .Type3D
        textureDescriptor.width  = dimention
        textureDescriptor.height = dimention
        textureDescriptor.depth  = dimention
        
        textureDescriptor.pixelFormat =  .RGBA8Unorm
        
        textureDescriptor.arrayLength = 1;
        textureDescriptor.mipmapLevelCount = 1;
        
        let texture = context.device.newTextureWithDescriptor(textureDescriptor)
        
        return texture
    }
}
    