//
//  ViewController.swift
//  ImageMetalling-03
//
//  Created by denis svinarchuk on 04.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit

///
/// Металаграмический фильтр. Созадем не с нуля, а используем готовый
/// набор классов еще более больше скрывающий слой работающий с GPU:
/// https://bitbucket.org/degrader/degradr-core-3
///
/// DPCore3 framework - по сути специализированный модульный конструктор
/// для создания собственных прикладых image-фильров.
///
/// Тут воспользуемся готовыми классами: читалкой файла формата .cube, в котором
/// хранят зарание подготовленные CLUT - Color LookUp Table.
/// .cube - это открытая спецификация Adobe, поддерживается кучей генераторов CLUT
///
///
class IMPMetalaGramFilter: DPFilter {
    
    //
    // Кэшируем CLUTs в справочник
    // По имени можно получить класс типа DPImageProvider.
    //
    // Все фильтры наследуемые от DPFilter из DPCore3 framework имеют два свойства:
    //  - .source - исходное изображение
    //  - .destination - изображение после преобразования
    //  Оба свойства являются ссылками на объекты класса DPImageProvider.
    //
    // Image provider-ы - абстрактное представление произвольного изображения и его исходных данных
    // этого изображения. Фреймворк содержит начальный набор провайдеров к jpeg-файлам,  UIImage/CGImage,
    // NSData, frame-буферу видео-изображения.
    // Нам для работы c lookup таблицами нунеж CLUT-провайдер, который, по сути, 
    // явлеется таким же изображением (текстурой), и позиция цвета в виде координаты является отображение
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
    }
    
    required init!(context aContext: DPContext!) {
        //
        // Не даем создать фильтр без инициализации таблицей
        //
        fatalError("init(context:) does not create initial filter without LUT")
    }
    
}

class ViewController: UIViewController {

    //
    // Управлять будем только прозрачностью фильтра
    // т.е. его степенью воздействия.
    //
    @IBOutlet weak var opacitySlider: UISlider!

    @IBAction func changeSliderValue(sender: UISlider) {
        let filter:IMPMetalaGramFilter = camera.liveViewFilter as! IMPMetalaGramFilter
        //
        // всегда от 0 до 1
        //
        filter.opacity=sender.value
    }

    //
    // В примере не будем городить огород, просто накидаем
    // 3 иконки для выбора 3х фильтров.
    //
    @IBOutlet weak var filter1Icon: UIImageView!
    @IBOutlet weak var filter2Icon: UIImageView!
    @IBOutlet weak var filter3Icon: UIImageView!
    
    //
    // Названия файлов color lookup table - файлов.
    //
    private var lutNameAt = ["filter1","filter2","filter3"]
    
    //
    // Текущая таблица
    //
    private var currentLutName:String!
    
    //
    // Иконки фильров на экране для выбора
    //
    private var filterIcons = [String:UIImageView]()

    //
    // Для работы с потоком видео создадим неблокирующий контекст.
    //
    private let contextLive   = DPContext.newLazyContext()

    //
    // В комплекте с фильтрами из DPCore3 идет класс для управления камерой
    // Менеджер камеры так же дает возможность не писать лишнего кода для связывания
    // окна отображения с потоком видео или фото.
    //
    private var camera:DPCameraManager!

    //
    // Окно-контейнер для публикации видео потока, которое связываем мееджером камеры
    //
    private var liveView: UIView!
    
    //
    // Ссылка на фильтр. Фильтр также свежем с менеджером камеры
    //
    private var filterLive:IMPMetalaGramFilter!
    

    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated);
    
        //
        // Тут просто инициализируем иконки выбора фильтров 
        // при нажатии на которые будет выбираться определенный LUT и устанавливаться в качестве 
        // источника для фильтра.
        //
        // Для корректной отрисовки выбираем блокирующий контекст (по умолчанию).
        //
        if let filter:IMPMetalaGramFilter! = IMPMetalaGramFilter(context: DPContext.newContext(), initialLUTName: currentLutName) {
            
            filter.source = DPUIImageProvider.newWithImage(UIImage(named: "template.jpg"), context: filter.context)
            
            for n in lutNameAt{
                let iconView = filterIcons[n]! as UIImageView
                filter.name = n
                iconView.image = UIImage(imageProvider: filter.destination)
            }
        }
        
        UIView.animateWithDuration(UIApplication.sharedApplication().statusBarOrientationAnimationDuration,
            animations: {
                for (name, c) in self.filterIcons{
                    if name == self.currentLutName {
                        c.alpha = 1.0
                    }
                    else {
                        c.alpha = 0.5
                    }
                }
            }
        )
    }
    

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        camera.start()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        camera.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //
        // Это пример, да...
        //
        filterIcons = [
            lutNameAt[0]:filter1Icon,
            lutNameAt[1]:filter2Icon,
            lutNameAt[2]:filter3Icon
        ]
        
        currentLutName = lutNameAt[0]
        
        //
        // По умолчанию действие выбранного фильтра будет полностью
        //
        opacitySlider.value=1
        
        //
        //  Просто настраиваем наш импровизированный чузер фильтров
        //
        for (_, c) in filterIcons{
            c.contentMode = .ScaleAspectFit
            c.alpha = 0.0
            c.userInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: "tapHandler:")
            c.addGestureRecognizer(tapGesture)
        }
        
        liveView = UIView(frame: CGRectMake( 0, 50,
            self.view.bounds.size.width,
            self.view.bounds.size.width
            //self.view.bounds.size.height*3/4
            ))
        liveView.backgroundColor = UIColor.clearColor()
        self.view.insertSubview(liveView, atIndex: 0)
        
        let pressGesture = UILongPressGestureRecognizer(target: self, action: "disableFilterHandler:")
        pressGesture.minimumPressDuration = 0.2
        liveView.addGestureRecognizer(pressGesture)
        
        //
        // Создаем менеджер камеры, связываем с контейнером для отображения видео
        //
        camera = DPCameraManager(outputContainerPreview: self.liveView)
        
        //
        // Инициализируем наш фильтра
        //
        filterLive = IMPMetalaGramFilter(context: contextLive, initialLUTName: currentLutName)
        
        let factor:Float = (1-3/4)/2
        let transform  = DPTransform()
        transform.cropRegion = DPCropRegion(top: 0, right: factor, left: factor, bottom: 0)
        
        filterLive.transform = transform

        //
        // Связываем его с live-vew фильтром камеры
        //
        camera.liveViewFilter = filterLive
    }
    
    
    //
    // Хендлер выбиралки фильтров
    //
    func tapHandler(gesture:UITapGestureRecognizer){

        for (name, c) in self.filterIcons{
            if gesture.view == c {
                filterLive.name = name
                c.alpha = 1.0
            }
            else{
                c.alpha = 0.5
            }
        }
    }
    
    //
    // Отмена действия фильтра
    //
    func disableFilterHandler(gesture:UILongPressGestureRecognizer){
        if gesture.state == .Began {
            camera.filterEnabled = false
        }
        else if gesture.state == .Ended {
            camera.filterEnabled = true
        }
    }
}

