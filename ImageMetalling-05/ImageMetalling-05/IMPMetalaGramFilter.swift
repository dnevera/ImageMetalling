//
//  IMPMetalaGramFilter.swift
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 28.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit

///
/// Металаграмический фильтр. Созадем не с нуля, а используем готовый
/// набор классов еще более больше скрывающий слой работающий с GPU:
/// https://bitbucket.org/degrader/degradr-core-3
///
/// DPCore3 framework - по сути специализированный модульный конструктор
/// для создания собственных прикладных image-фильтров.
///
/// Тут воспользуемся готовыми классами: читалкой файла формата .cube, в котором
/// хранят заранее подготовленные CLUT - Color LookUp Table.
/// .cube - это открытая спецификация Adobe, поддерживается кучей генераторов CLUT
///
///
class IMPMetalaGramFilter: DPFilter {
    
    //
    // Кэшируем CLUTs в справочник.
    // По ключу можно получить готовую текстуру объекта класса типа DPImageProvider.
    //
    // Все фильтры наследуемые от DPFilter из DPCore3 framework имеют два свойства:
    //  - .source - исходное изображение
    //  - .destination - изображение после преобразования
    //  Оба свойства являются ссылками на объекты класса DPImageProvider.
    //
    // Image provider-ы - абстрактное представление произвольного изображения и его сырых данных представленных
    // в текстуре записанной в область памяти GPU.
    // Фреймворк содержит начальный набор провайдеров к jpeg-файлам,  UIImage/CGImage,
    // NSData, frame-буферу видео-изображения.
    // Нам для работы c lookup таблицами нунеж CLUT-провайдер, который, по сути,
    // явлеется таким же изображением (текстурой), и позиция цвета в виде координаты является отображением
    // входного цвета в выходной
    //
    // DPCubeLUTFileProvider - поддерживает обе формы представления CLUT: 1D и 2D
    //
    // В качестве упражнения можно также написать провайдер CLUT из png-файлов.
    //
    private var lutTables = [String:DPCubeLUTFileProvider]()
    
    //
    // Фильтр мапинга картинки в новое цветовое пространства представленное CLUT-провайдере.
    //
    private var lutFilter:DPCLUTFilter!
    
    //
    // Просто сервисная функция для получения CLUT по имени файла. Файл добавляется в проект приложения.
    //
    private func getLUT(name:String) -> DPCubeLUTFileProvider? {
        
        do{
            if let lut = lutTables[name]{
                return lut
            }
            else {
                let lut = try DPCubeLUTFileProvider.newLUTNamed(name, context: context)
                lutTables[name] = lut
                return lut
            }
        }
        catch let error as NSError{
            //
            // Перед падением программы напишем что пошло не так,
            // скорее всего в проект не добавили файла или формат файла левый
            //
            NSLog("%@", error)
        }
        
        return nil
    }
    
    //
    // Управление выбором CLUT по имени.
    //
    var name:String!{
        didSet(oldValue){
            if oldValue != name {
                lutFilter.lutSource=getLUT(name)
                
                //
                // Скажем фильтру, что данные протухли.
                // Когда пишется свой собственный кастомный фильтр с помощью
                // DPCore3 необходимо выставлять флажок протухания (dirty)
                // при изменении параметров фильтра.
                //
                self.dirty = true
            }
        }
    }
    
    //
    // Управления степенью воздействия
    //
    var opacity:Float{
        get{
            return lutFilter.adjustment.blending.opacity
        }
        set(value){
            lutFilter.adjustment.blending.opacity=value
        }
    }
    
    init(context aContext: DPContext!, initialLUTName:String) {
        super.init(vertex: DP_VERTEX_DEF_FUNCTION, withFragment: DP_FRAGMENT_DEF_FUNCTION, context: aContext)
                
        //
        // если CLUT-файл добавлен в проект, формат файла соответствует спекам:
        //
        name = initialLUTName
        
        if let lut = getLUT(name){
            lutFilter = DPCLUTFilter(context: self.context, lut: lut, type: lut.type)
            //
            // добавляем в цепочку новый фильтр,
            // если нам нужна обработка нескольких фильтров можно подцепить несколько
            // например анализатор гистограммы:
            // DPHistogramAnalizer,  к которой в свою очередь DPHistogramZonesSolver для решения
            // задачи коррекции экспозиции, к примеру.
            //
            // Пока просто добавляем фильтра мапинга цветовых пространств через CLUT
            //
            self.addFilter(lutFilter)
        }
        
        let histogram = IMPHistogramAnalizer(context: self.context)
        
        self.willStartProcessing = { (DPImageProvider source) in
            histogram.source = source
        }
    }
    
    required init!(context aContext: DPContext!) {
        //
        // Не даем создать фильтр без инициализации таблицей
        //
        fatalError("init(context:) does not create initial filter without LUT")
    }
    
}

