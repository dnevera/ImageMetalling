//
//  IMPView.swift
//  ImageMetalling-00
//
//  Created by denis svinarchuk on 27.10.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import GLKit

/**
 * Представление результатов обработки картинки в GCD.
 */
class IMPSaturationView: UIView {

    /**
     * Степень насыщенности картинки. Этим папаремтром будем управлять в контроллере.
     * Этот параметр делаем публичным.
     */
    var saturation:Float!{
        didSet(oldValue){
            //
            // Добавляем обзервер изменения, что-бы ловить изменения 
            //
            saturationUniform = saturationUniform ??
                //
                // если буфер еще не создан создаем (i love swift!:)
                //
                self.device.newBufferWithLength(sizeof(Float),
                options: MTLResourceOptions.CPUCacheModeDefaultCache)
            
            //
            // записвывем в буфер для передачи в GPU в момент исполнения металической команды
            //
            memcpy(saturationUniform.contents(), &saturation, sizeof(Float))
        }
    }
    
    //
    // Универсальный буфер данных. Металический слой использует этот тип для обмена данными между памятью CPU
    // и кодом программы GPU. Создать буфер можно один раз и затем просо изменять его содержимое. 
    // Содержимое может иметь произвольную структуру и имеет ограничение только по размеру.
    //
    // Все дальнейшие объявления перемнных класса делаем приватными - внешним объектам они ни к чему.
    //
    private var saturationUniform:MTLBuffer!=nil
    
    //
    // Текущее устройство GPU. Для работы с металическим устройством создаем новое представление.
    //
    private let device:MTLDevice! = MTLCreateSystemDefaultDevice()

    //
    // Очередь команд в которую мы будем записывать команды которые должен будет исполнить металический слой.
    //
    private var commandQueue:MTLCommandQueue!=nil;
    
    //
    // Можно создать слой Core Animation, в котором можно отрендерить содержимое текстуры представленой в Metal,
    // а можно через MetalKit сразу рисовать в специальном view. MTKView появилась только в iOS 9.0, поэтому если
    // по каким-то причинам хочется сохранить совместимость с 8.x, то лучше использовать CAMetalLayer. 
    // MetalKit немного экономит для нас время - дает сосредоточится на функционале, вместо того что бы писать
    // много лишнего кода.
    //
    private var metalView:MTKView!=nil;
    
    //
    // Переменная котейнер доя храения текстуры с которой будем работать. В текстуру мы загрузим картинку 
    // непосредственно из файла. Очевидно, что картинка в реальном проекте может быть загружена из 
    // произвольного источника. К примеру, таким источником может быть потокй фреймов из камеры устройства.
    //
    private var imageTexture:MTLTexture!=nil
    
    //
    // Специальный объект который будет представлять ссылку на нашу функцию,
    // но уже в виде машинного кода для исполнения его в очереди команд GPU.
    // Алгоритм фильтра оформим в виде кода шейдера на Metal Shading Language.
    // Функция которую будем применять к изображению назовем kernel_adjustSaturation
    // и разместим в файле проекта: IMPSaturationFilter.metal.
    //
    private var pipeline:MTLComputePipelineState!=nil;
    
    //
    // Настраиваем распараллеливание. Например, мы решили, что нам достаточно запустить по 8 тредов в каждом направлении
    // для запуска одной инструкции в стиле SIMD - т.е. распараллеливание одной инструкции по множеству потоков данных.
    // В случае с картинками - это количество пикселей, к которым мы применим фильтр одновременно.
    // Пусть будет 8x8 потоков в группе, т.е. 64., хотя по правильному количество потоков должно быть кратно размерности картинки.
    // Но на самом деле можно немного схитрить и считать, что количество групп тредов будет немного больше чем нужно.
    //
    private let threadGroupCount = MTLSizeMake(8, 8, 1)
    
    //
    // В этой переменной будем вычислять сколько групп потоков нам нужно создать для обсчета всей сетки данных картинки.
    // Группы дретов - центральная часть вычислений металического API. Суть заключается в том, что поток вычислений разбивается
    // на фиксированное количество одновременных вычислений в каждом блоке. Т.е. если это картинка, то картинка бъется сетку 
    // из на множества групп, в каждой группе всегда будет запущено одновременно заданное количество потоков для применения фильра
    // (в нашем случае 8x8),
    // а вот как и когда будет запущен этот блок одновременных вычислений принимает решение диспетчер вычислений - и все будет 
    // зависить от конкретной железки GPU и размерности данных. Если количество узлов GPU для одновременного вычичления всех групп будет
    // достаточно - будет запущены одновременные вычисления по всем группам, если нет - то группы будут выбираться из пула по очереди.
    //
    private var threadGroups:MTLSize?
    
    //
    // Загрузка картинки.
    //
    func loadImage(file: String){
        autoreleasepool {
            //
            // Создаем лоадер текстуры из MetalKit
            //
            let textureLoader = MTKTextureLoader(device: self.device!)
            
            //
            // Подцепим картинку прямо из проекта.
            //
            if let image = UIImage(named: file){
                //
                // Положм картинку в текстуру. Теперь мы можем применять различные преобразования к нашей кртинке
                // используя всю мощь GPU.
                //
                imageTexture = try! textureLoader.newTextureWithCGImage(image.CGImage!, options: nil)
                
                //
                // Количество групп параллельных потоков зависит от размера картинки.
                // По сути мы должны сказать сколько раз мы должны запустить вычисления разных кусков кратинки.
                //
                threadGroups = MTLSizeMake(
                    (imageTexture.width+threadGroupCount.width)/threadGroupCount.width,
                    (imageTexture.height+threadGroupCount.height)/threadGroupCount.height, 1)
            }
        }        
    }
    
    //
    // Ну, тут понятно...
    //
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        // 
        // Сначала подготовим анимационны слой в который будем рисовать результаты работы 
        // нашего фильтра.
        //
        metalView = MTKView(frame: self.bounds, device: self.device)
        metalView.autoResizeDrawable = true
        metalView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth];
        
        //
        // Координатная система Metal: ...The origin of the window coordinates is in the upper-left corner...
        // https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Render-Ctx/Render-Ctx.html
        //
        // Поэтому что бы отобразить загруженную текстуру и не возится с вращением картинки пока сделаем так:
        // просто приведем координаты к bottom-left варианту, т.е. попросту зеркально отобразим
        //
        metalView.layer.transform = CATransform3DMakeRotation(CGFloat(M_PI),1.0,0.0,0.0);
        self.addSubview(metalView);
        
        //
        // Нам нужно сказать рисовалке о реальной размерности экрана в котором будет картинка рисоваться.
        //
        let scaleFactor:CGFloat! = metalView.contentScaleFactor
        metalView.drawableSize = CGSizeMake(self.bounds.width*scaleFactor, self.bounds.height*scaleFactor)

        
        //
        // Пусть по умолчанию картинка будет не десатурированной.
        //
        saturation = 1.0
        
        //
        // Инициализируем очередь комманд один раз и в последующем будем ее использовать для исполнения контекста 
        // программы нашего фильтра десатурации.
        //
        commandQueue = device.newCommandQueue()
        
        //
        // Библиотека шейдеров. В библиотеку компилируются все файлы с раширением .metal добавленыые в проект.
        //
        let library:MTLLibrary!  = self.device.newDefaultLibrary()
        
        //
        // Функция которую мы будем использовать в качестве функции фильтра из библиотеки шейдеров.
        //
        let function:MTLFunction! = library.newFunctionWithName("kernel_adjustSaturation")
        
        //
        // Теперь создаем основной объект который будет ссылаться на исполняемый код нашего фильра.
        //
        pipeline = try! self.device.newComputePipelineStateWithFunction(function)
    }
    
    //
    // Теперь самое главное: собственно применение фильтра к картинке и отрисовка результатов на экране.
    //
    func refresh(){
        
        if let actualImageTexture = imageTexture{
            
            //
            // Вытягиваем из очереди одноразовый буфер команд.
            //
            let commandBuffer = commandQueue.commandBuffer()
            
            //
            // Подготавливаем кодер для интерпретации команд очереди.
            //
            let encoder = commandBuffer.computeCommandEncoder()
            
            //
            // Устанавливаем ссылку на код фильтра
            //
            encoder.setComputePipelineState(pipeline)
            
            //
            // Устанавливаем ссылку на память с данными текстуры (картинки)
            //
            encoder.setTexture(actualImageTexture, atIndex: 0)
            
            //
            // Устанавливаем ссылку на память результрующей текстуры - т.е. куда рисуем 
            // В нашем случае это слой Core Animation подготовленный для рисования текстур из Metal
            // (ну или MTKview, что тоже самое)
            //
            encoder.setTexture(metalView.currentDrawable!.texture, atIndex: 1)
            
            //
            // Передаем ссылку на буфер с данными для параметризации функции фильтра.
            //
            encoder.setBuffer(self.saturationUniform, offset: 0, atIndex: 0)
            
            //
            // Говорим металическому диспетчеру как переллелить вычисления.
            //
            encoder.dispatchThreadgroups(threadGroups!, threadsPerThreadgroup: threadGroupCount)
            
            //
            // Упаковываем команды в код.
            //
            encoder.endEncoding()
            
            //
            // Говорим куда рисовать данные.
            //
            commandBuffer.presentDrawable(metalView.currentDrawable!)
            
            //
            // Говорим металическому слой запускать исполняемый код. Все.
            //
            commandBuffer.commit()
        }
    }
}
