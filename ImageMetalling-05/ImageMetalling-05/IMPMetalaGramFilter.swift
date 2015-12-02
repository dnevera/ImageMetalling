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
/// В этой версии программы усложним немного обработку и добавим препроцессинг 
/// исходной картинки: выарвнеем баланс белого и усилим контраст.
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
    // Воспользуемся фильтром автоматического выравнивания баланса белого.
    // Сдвиг настраивается установкой среднего цвета картинки.
    //
    private var awbFilter:DPAWBFilter!
    
    //
    // Нормализуем контраст через растягивание гистограммы.
    //
    private var contrastFilter:DPContrastFilter!
    
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
    
    ///
    /// Управление выбором CLUT по имени. Файл с CLUT должен быть добавлен в проект.
    ///
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
    
    ///
    /// Управления степенью воздействия.
    ///
    var opacity:Float{
        get{
            return lutFilter.adjustment.blending.opacity
        }
        set(value){
            lutFilter.adjustment.blending.opacity = value
            contrastFilter.adjustment.blending.opacity = value
            awbFilter.adjustment.blending.opacity = value
        }
    }
    
    ///
    /// Инициализироваться с умолчательным CLUT.
    ///
    /// - parameter aContext:       текущий контекст устройств на котором выполняется фильтрация
    /// - parameter initialLUTName: имя файла CLUT
    ///
    init(context aContext: DPContext!, initialLUTName:String) {
        super.init(vertex: DP_VERTEX_DEF_FUNCTION, withFragment: DP_FRAGMENT_DEF_FUNCTION, context: aContext)
        
        //
        // Создадим анализатор гистограммы.
        //
        let analizer = IMPHistogramAnalyzer(context: self.context)
        
        //
        // И два солвера.
        //
        
        // Один вычсиляет доминантный цвет изображения
        let average  = IMPHistogramAverageSolver()
        // Второй диапазон интенсивностей
        let range    = IMPHistogramRangeSolver()
        
        // добавляем в анализатор солверы
        analizer.solvers.append(average)
        analizer.solvers.append(range)
        
        //
        // Перед исполнением фильтров закидываем в анализатор исходную картинку
        //
        self.willStartProcessing = { (DPImageProvider source) in
            analizer.source = source
        }

        awbFilter = DPAWBFilter.newWithContext(self.context)
        contrastFilter = DPContrastFilter.newWithContext(self.context)
        
        //
        // Начинаем собирать стек фильтров
        //
        
        // Приводим картинку к более нейтральному типу
        self.addFilter(awbFilter)
        
        // повышаем контраст
        self.addFilter(contrastFilter)
        
        analizer.solversDidUpdate = {
            //
            // на каждое изменение расчетных значений в солверах
            // обновляем свойства фильтров
            //
            self.awbFilter.adjustment.averageColor = average.color
            
            var adj = self.contrastFilter.adjustment
            adj.minimum = range.min;
            adj.maximum = range.max;
            
            self.contrastFilter.adjustment = adj;
        }
        
        //
        // если CLUT-файл добавлен в проект, формат файла соответствует спекам:
        //
        name = initialLUTName
        
        if let lut = getLUT(name){
            lutFilter = DPCLUTFilter(context: self.context, lut: lut, type: lut.type)
            //
            // Добавляем фильтр мапинга цветовых пространств через CLUT
            //
            self.addFilter(lutFilter)
        
        }
    }
    
    ///
    /// Фильтр нельзя создать без умолчательной таблицы.
    ///
    /// - parameter aContext: текущий контекст устройства
    ///
    required init!(context aContext: DPContext!) {
        //
        // Не даем создать фильтр без инициализации таблицей
        //
        fatalError("init(context:) does not create initial filter without LUT")
    }
    
}

