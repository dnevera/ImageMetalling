//
//  ColorObserver.swift
//  ImageMetalling-14
//
//  Created by denis svinarchuk on 19.05.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import IMProcessing

///
/// Фильтр обзервера. Обзервер читает усреденнный цвет области тектстуры.
/// Области задаются центром и размером квадрата. Областей может быть много. 
/// Очень много. Например 1024. Это может быть, скажем, сетка гигантского колорчекера.
///
public class ColorObserver:IMPFilter {
    
    // Размер области    
    public var regionSize:Float = 8 {
        didSet{            
            if oldValue != regionSize {
                dirty = true
                // запускаем пересчет кернела
                process()
            }
        }
    }
    
    
    /// Установка областей чтения семплов 
    public var centers:[float2] = [float2]() {
        didSet{
            if centers.count > 0 {
                
                // создать MTL-буфер из которого будем читать центры областей в шейдере
                centersBuffer = context.device.makeBuffer(length: MemoryLayout<float2>.size * centers.count, options: [])!
                
                // создаем MTL-буфер в который будем писать значения цветов в шейдере  
                colorsBuffer = context.device.makeBuffer(length: MemoryLayout<float3>.size * centers.count, options: .storageModeShared)!
                
                // пишем в буфер центры
                memcpy(centersBuffer.contents(), centers, centersBuffer.length)
                
                // выделяем память массив цветов, в который потом скопируем то что прилетело 
                // в буфер в шейдере
                _colors = [float3](repeating:float3(0), count:centers.count)
                
                // определим размерность грида вычислений GPU  
                patchColorsKernel.preferedDimension =  MTLSize(width: centers.count, height: 1, depth: 1)
                
                // сбросим фильтр
                dirty = true     
                
                // запустим вычисления на шейдерах
                process()
            }
        }
    }
    
    /// Цвета прочитаных областей 
    public var colors:[float3] { return _colors }
        
    /// Настройка фильтра
    public override func configure(complete: IMPFilter.CompleteHandler?) {
        
        // Имя расширения индекса (используется в отладке)
        extendName(suffix: "Checker Color Observer")
        
        //
        // Хендлер, который добавляется в общий стек замыканий исполняемых при пересчете фильтра.
        // Например при добавление фиьтра в цепочку: filter.add(filter: anotherFilter) { ... что-то тут вычисляем ... }
        // Здесь просто перекрываем замыкание базового класса текущим.
        //        
        self.complete = complete
        
        // не забываем вызвать базовый конфигуратор
        super.configure()
        
        // Размерность грида вычислений по мулочанию == 1
        patchColorsKernel.preferedDimension =  MTLSize(width: 1, height: 1, depth: 1)
        
        // Добавляем в фильтр ядро чтения семплов
        add(function: self.patchColorsKernel){ (source) in

            // добавляем замыкание выполняющее процессинга

            if self.centers.count > 0 {
                // копирем в цвета данные из буфера GPU в массив цветов 
                memcpy(&self._colors, self.colorsBuffer.contents(), self.colorsBuffer.length)
            }
            if let s = self.source {
                // к замыкание добавляем пользовательское (еесли нужно конечно)
                self.complete?(s)
            }
        }
    }
    
    /// Создаем кернел чтения
    private lazy var patchColorsKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_regionColors")
        
        // определяем параметры, которые передаем в кернел чтения текстуры  
        f.optionsHandler = { (function,command,source,destination) in
            if self.centers.count > 0 {
                // центры - читаем
                command.setBuffer(self.centersBuffer,  offset: 0, index: 0)
                // цвета - пишем
                command.setBuffer(self.colorsBuffer,   offset: 0, index: 1)
                // размер области
                command.setBytes(&self.regionSize, length:MemoryLayout.size(ofValue: self.regionSize), index:2)                
            }
        }
        return f
    }()
    
    //
    // Вспомогательные переменные класса до кучи...
    //
    private var _colors:[float3] = [float3]()
    private var centersBuffer:MTLBuffer!
    private var colorsBuffer:MTLBuffer!     
    private var complete: IMPFilter.CompleteHandler?
}
