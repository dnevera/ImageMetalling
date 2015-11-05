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
            
            filter.source = DPUIImageProvider.newWithImage(UIImage(named: "template1x1.jpg"), context: filter.context)
            
            for n in lutNameAt{
                let iconView = filterIcons[n]! as UIImageView
                filter.name = n
                iconView.image = UIImage(imageProvider: filter.destination)
            }
        }
        
        //
        // Что бы не сильно раздражали скачки при старте
        // никакого смысле не несет
        //
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
        //
        // При старте стартуем камеру
        //
        camera.start()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //
        // При стопе стопаем камеру
        //
        camera.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
        
        //
        // Это просто пример, да...
        //
        filterIcons = [
            lutNameAt[0]:filter1Icon,
            lutNameAt[1]:filter2Icon,
            lutNameAt[2]:filter3Icon
        ]
        
        currentLutName = lutNameAt[0]
        
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
        
        liveView = UIView(frame: CGRectMake( 0, 60,
            self.view.bounds.size.width,
            self.view.bounds.size.width
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
        
        //
        // Делаем картинку квадратной отрезая слева и справа
        //    - помним, что нормальная ориентация камеры на левом боку
        //
        let factor:Float = (1-3/4)/2
        let transform  = DPTransform()
        transform.cropRegion = DPCropRegion(top: 0, right: factor, left: factor, bottom: 0)
        
        filterLive.transform = transform
        
        //
        // Связываем его с live-vew фильтром камеры
        //
        camera.liveViewFilter = filterLive
        
        //
        // Чтобы побыстрее жать жипег используем хардварную компрессию встроенную в iOS
        //
        camera.hardwareCompression = true;
        
        //
        // Чтобы еще чуть ускориться
        //
        camera.compressionQuality  = 0.9;
        
        //
        // Теперь настраиваем контекст захвата картинки
        // Он по идее может быть и контекстом live-view камеры, но нам ее не хочется тормозить
        // на момент работы фильтра по полному разрешению прилетевшего файла
        //
        let capturingFilter = IMPMetalaGramFilter(context: DPContext.newContext(), initialLUTName: currentLutName)
        
        //
        // Не забываем отрезать
        //
        capturingFilter.transform = transform
        
        //
        // Ловим снепшот и тут же фильтруем с записью в Camera Roll так будет дольше,
        // но зато сразе и без всяких внутренних галерей. (пример в общем, то)
        //
        camera.capturingCompleteBlock = { (finished, file, meta) in
            
            if finished {
                //
                // если камера успела захватить изображение
                //
                
                //
                // устанавливаем текущий lut
                //
                capturingFilter.name = self.currentLutName
                
                //
                // и прозрачность которую запомнили в live-view фильтре
                //
                capturingFilter.opacity = self.filterLive.opacity
                
                //
                // получаем из меты ориентацию картинки
                //
                let orientation:UIImageOrientation! = UIImageOrientation(rawValue: (meta[kDP_imageOrientationKey] as! NSNumber).integerValue)
                
                //
                // Читаем из источника jpeg
                //
                capturingFilter.source = DPImageFileProvider.newWithImageFile(file, context: capturingFilter.context, maxSize: 0, orientation: orientation)
                
                //
                // Записываем результат в Camera Roll
                //
                UIImageWriteToSavedPhotosAlbum(UIImage(imageProvider: capturingFilter.destination), nil, nil, nil)
            }
            
        }
    }
    
    
    //
    // Хендлер выбиралки фильтров
    //
    func tapHandler(gesture:UITapGestureRecognizer){
        
        for (name, c) in self.filterIcons{
            if gesture.view == c {
                currentLutName = name
                filterLive.name = currentLutName
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
    
    
    //
    // Управление камерой и фильтром
    //
    
    @IBAction func toggleCamera(sender: UIButton) {
        camera.toggleCameraPosition()
    }
    
    @IBAction func takePhoto(sender: UIButton) {
        let tmp    = NSURL.fileURLWithPath(NSTemporaryDirectory(), isDirectory: true)
        let fileid = NSProcessInfo.processInfo().globallyUniqueString
        let file = tmp.URLByAppendingPathComponent(fileid).URLByAppendingPathExtension("jpg").path
        camera.capturePhotoToFile(file)
    }
    

    //
    // Управлять будем только прозрачностью фильтра
    
    func changeSliderValue(sender: UISlider) {
        //
        // всегда от 0 до 1
        //
        self.filterLive.opacity=sender.value
    }
    
    var settingsView:UISlider!
    var settIngsViewHidden = true;
    @IBOutlet weak var settingsButton: UIButton!

    //
    // Немного схалтурим и просто нарисуем слайдер как единственный контрол настроек
    //
    @IBAction func settingsHandler(sender: UIButton) {
        
        
        let w = (settingsButton.frame.size.width+settingsButton.frame.origin.x+15)
        
        if settingsView==nil {
            settingsView = UISlider(frame:
                CGRectMake(w,
                    settingsButton.frame.origin.y,
                    self.view.frame.size.width-w*2,
                    settingsButton.frame.size.height)
            )
            settingsView.alpha = 0.0
            settingsView.value = 1.0
            settingsView.backgroundColor = UIColor.clearColor()
            settingsView.tintColor = UIColor.redColor()
            
            settingsView.addTarget(self, action: "changeSliderValue:", forControlEvents: UIControlEvents.ValueChanged)
            
            self.view.addSubview(settingsView)
        }
        
        
        let duration = UIApplication.sharedApplication().statusBarOrientationAnimationDuration
        
        if settIngsViewHidden {
            UIView.animateWithDuration(duration, animations: {
                self.settingsView.alpha = 0.5
            })
        }
        else{
            UIView.animateWithDuration(duration, animations: {
                self.settingsView.alpha = 0
            })
        }
        
        settIngsViewHidden = !settIngsViewHidden;
    }
}

