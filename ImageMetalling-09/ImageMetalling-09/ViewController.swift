//
//  ViewController.swift
//  ImageMetalling-08
//
//  Created by denis svinarchuk on 01.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Cocoa
import IMProcessing
import SnapKit

class IMPLabel: NSTextField {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        drawsBackground = false
        bezeled = false
        editable = false
        alignment = .Center
        textColor = IMPColor.lightGrayColor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ViewController: NSViewController {
    
    //
    // Контекст процессинга
    //
    var context = IMPContext()
    //
    // Окно представления загруженной картинки
    //
    var imageView:IMPImageView!
    
    //
    // Окно вывода гистограммы изображения
    //
    var histogramView:IMPHistogramView!
    
    //
    // Основной фильтр
    //
    var filter:IMPAutoWBFilter!
    
    //
    // Фильтр CLUT из фалов формата Adobe Cube
    // Будем использовать для того, что бы проверить насколько влияет нормализация 
    // на последущую обработку, т.е. то ради того чего применяется нормализация цветовой гаммы
    //
    var lutFilter:IMPLutFilter?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if !IMPContext.supportsSystemDevice {
            
            self.asyncChanges({ () -> Void in
                let alert = NSAlert(error: NSError(domain: "com.imagemetalling.08", code: 0, userInfo: [
                    NSLocalizedFailureReasonErrorKey:"MTL initialization error",
                    NSLocalizedDescriptionKey:"The system does not support MTL..."
                    ]))
                alert.runModal()
            })
            return
        }
                
        configurePannel()
        
        //
        // Создаем фильтр автоматической коррекции баланса цветов
        //
        
        filter = IMPAutoWBFilter(context: context)
        
        //
        // Профилируем обработку через анализ распределения весов на цветовом круге.
        // Снижаем влияние автоматической коррекции в зависимости от сюжета и замысла нашего 
        // фильтра. Форма снижения или увеличения opacity, а по сути силы воздействия AWB,
        // может быть произвольной.
        //
        // В конкретном примере:
        // 1. мы снижаем долю насыщенности желого, если доминантный цвет изображения желто-красный.
        // 2. учитываем вес голубых и синих оттенков для снижения влияения на сюжетах с явно выраженным 
        //    участием сине-голубых цветов
        //
        //
        filter.colorsAnalyzeHandler = { (solver, opacityIn, wbFilter, hsvFilter) in
            
            //
            // Получаем доминантный цвет изображения
            //
            let dominanta = self.filter.dominantColor!
            
            //
            // Переходим в пространство HSV
            //
            let hsv = dominanta.rgb.tohsv()
            
            //
            // Получаем тон доминантного цвета
            //
            let hue = hsv.hue * 360

            //
            // Просто выводим для справки
            //
            self.dominantLabel.stringValue = String(format: "%4.0fº", hue)
            self.neutralsWLabel.stringValue = String(format: "%4.0f%", solver.neutralWeights.neutrals*100)
            
            //
            // Учитываем состав доминантного цвета
            //
            var reds_yellows_weights =
            //
            // количество красного с учетом перекрытия красных оттенков из
            // цветового круга HSV и степенью перекрытия с соседними цветами 1
            //
            hue.overlapWeight(ramp: IMProcessing.hsv.reds, overlap: 1) +
                //
                // к красным добавляем количество желтого
                //
                hue.overlapWeight(ramp: IMProcessing.hsv.yellows, overlap: 1)
            
            //
            // Веса оставшихся оттенков в доминантном цвете
            //
            let other_colors = solver.colorWeights.cyans +
                solver.colorWeights.greens +
                solver.colorWeights.blues +
                solver.colorWeights.magentas
            
            reds_yellows_weights -= other_colors
            if (reds_yellows_weights < 0.0 /* 10% */) {
                //
                // Если желто-красного немного вообще неучитываем в снижении
                //
                reds_yellows_weights = 0.0; // it is a yellow/red image
            }
            
            //
            // Снижаем насыщенность желтых оттенков в изображении
            //
            hsvFilter.adjustment.yellows.saturation = -0.1 * reds_yellows_weights

            self.yellowsWLabel.stringValue = String(format: "%4.0f%", reds_yellows_weights*100)

            
            //
            // Результирующая прозрачность слоя AWB
            //
            var opacity:Float = opacityIn
            
            //
            // Для сине-голубых оттенков изображения снижаем долю влияния AWB фильтра 
            // вычисляем общий вес (по сути площадь)
            //
            let cyan_blues = solver.colorWeights.cyans + solver.colorWeights.blues
            let rest       = 1 - cyan_blues
            
            self.bluesWLabel.stringValue = String(format: "%4.0f%", cyan_blues*100)

            //
            // Какая-то выдуманная функиця снижения прозрачности AWB от веса сине-голубых оттенков
            //
            opacity    *= rest < cyan_blues ? 1-sqrt(pow(cyan_blues,2) - pow(rest, 2)) : 1

            self.opacityLabel.stringValue = String(format: "%4.0f%", opacity*100)

            return opacity
        }

        
        imageView = IMPImageView(context: context, frame: view.bounds)
        imageView.filter = filter
        imageView.backgroundColor = IMPColor(color: IMPPrefs.colors.background)
        
        //
        // Добавляем наблюдателя к фильтру для обработки результатов
        // фильтрования
        //
        filter.addDestinationObserver { (destination) -> Void in
            // передаем картинку показывателю кистограммы
            self.histogramView.filter?.source = destination
            
        }
        
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(imageView.superview!).offset(10)
            make.bottom.equalTo(imageView.superview!).offset(0)
            make.left.equalTo(imageView.superview!).offset(10)
            make.right.equalTo(pannelScrollView.snp_left).offset(0)
        }
        
        IMPDocument.sharedInstance.addDocumentObserver { (file, type) -> Void in
            if type == .Image {
                do{
                    //
                    // Загружаем файл и связываем источником фильтра
                    //
                    self.imageView.filter?.source = try IMPJpegProvider(context: self.context, file: file)
                    self.asyncChanges({ () -> Void in
                        self.zoomFit()
                    })
                }
                catch let error as NSError {
                    self.asyncChanges({ () -> Void in
                        let alert = NSAlert(error: error)
                        alert.runModal()
                    })
                }
            }
            else if type == .LUT {
                do {
                    
                    //
                    // Инициализируем дескриптор CLUT
                    //
                    var description = IMPImageProvider.LutDescription()
                    //
                    // Загружаем CLUT
                    //
                    let lutProvider = try IMPImageProvider(context: self.context, cubeFile: file, description: &description)
                    
                    if let lut = self.lutFilter{
                        //
                        // Если CLUT-фильтр добавлен - обновляем его LUT-таблицу из файла с полученным дескриптором
                        //
                        lut.update(lutProvider, description:description)
                    }
                    else{
                        //
                        // Создаем новый фильтр LUT
                        //
                        self.lutFilter = IMPLutFilter(context: self.context, lut: lutProvider, description: description)
                    }
                    
                    //
                    // Добавляем LUT-фильтр, если этот фильтр уже был добавленб ничего не происходит
                    //
                    self.filter.addFilter(self.lutFilter!)
                }
                catch let error as NSError {
                    self.asyncChanges({ () -> Void in
                        let alert = NSAlert(error: error)
                        alert.runModal()
                    })
                }
            }
        }
        
        IMPMenuHandler.sharedInstance.addMenuObserver { (item) -> Void in
            if let tag = IMPMenuTag(rawValue: item.tag) {
                switch tag {
                case .zoomFit:
                    self.zoomFit()
                case .zoom100:
                    self.zoom100()
                case .resetLut:
                    if let l = self.lutFilter {
                        self.filter.removeFilter(l)
                    }
                    break
                }
            }
        }
    }
    
    //
    // Вся остальная часть относится к визуальному представления данных
    //
    
    private func zoomFit(){
        asyncChanges { () -> Void in
            self.imageView.sizeFit()
        }
    }
    
    private func zoom100(){
        asyncChanges { () -> Void in
            self.imageView.sizeOriginal()
        }
    }
    
    override func viewDidAppear() {
        if IMPContext.supportsSystemDevice {
            super.viewDidAppear()
            asyncChanges { () -> Void in
                self.imageView.sizeFit()
            }
        }
    }
    
    var q = dispatch_queue_create("ViewController", DISPATCH_QUEUE_CONCURRENT)
    
    private func asyncChanges(block:()->Void) {
        dispatch_async(q, { () -> Void in
            //
            // немного того, но... :)
            //
            dispatch_after(0, dispatch_get_main_queue()) { () -> Void in
                block()
            }
        })
    }
    
    var dominantLabel  = IMPLabel()
    var neutralsWLabel = IMPLabel()
    var yellowsWLabel  = IMPLabel()
    var bluesWLabel    = IMPLabel()
    var opacityLabel   = IMPLabel()
    
    private func configureWeightsPannel(view:NSView){
        
        let label1  = IMPLabel()
        sview.addSubview(label1)
        label1.stringValue = "Dominant color hue:"
        label1.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(10)
            make.height.equalTo(20)
        }

        sview.addSubview(dominantLabel)
        dominantLabel.stringValue = "0"
        dominantLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view.snp_bottom).offset(10)
            make.left.equalTo(label1.snp_right).offset(10)
            make.height.equalTo(20)
        }
        allHeights+=40

        let label2  = IMPLabel()
        sview.addSubview(label2)
        label2.stringValue = "Neutrals color weights:"
        label2.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(label1.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(10)
            make.height.equalTo(20)
        }
        
        sview.addSubview(neutralsWLabel)
        neutralsWLabel.stringValue = "0"
        neutralsWLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(dominantLabel.snp_bottom).offset(10)
            make.left.equalTo(label2.snp_right).offset(10)
            make.height.equalTo(20)
        }
        allHeights+=40

        let label3  = IMPLabel()
        sview.addSubview(label3)
        label3.stringValue = "Reds/Yellows weights in dominat:"
        label3.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(label2.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(10)
            make.height.equalTo(20)
        }
        
        sview.addSubview(yellowsWLabel)
        yellowsWLabel.stringValue = "0"
        yellowsWLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(neutralsWLabel.snp_bottom).offset(10)
            make.left.equalTo(label3.snp_right).offset(10)
            make.height.equalTo(20)
        }
        allHeights+=40

        
        let label4  = IMPLabel()
        sview.addSubview(label4)
        label4.stringValue = "Cyans/Blues weights:"
        label4.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(label3.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(10)
            make.height.equalTo(20)
        }
        
        sview.addSubview(bluesWLabel)
        bluesWLabel.stringValue = "0"
        bluesWLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(yellowsWLabel.snp_bottom).offset(10)
            make.left.equalTo(label4.snp_right).offset(10)
            make.height.equalTo(20)
        }
        allHeights+=40

        
        let label5  = IMPLabel()
        sview.addSubview(label5)
        label5.stringValue = "AWB opacity:"
        label5.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(label4.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(10)
            make.height.equalTo(20)
        }
        
        sview.addSubview(opacityLabel)
        opacityLabel.stringValue = "0"
        opacityLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bluesWLabel.snp_bottom).offset(10)
            make.left.equalTo(label5.snp_right).offset(10)
            make.height.equalTo(20)
        }
        allHeights+=40
    }
    
    var pannelScrollView = NSScrollView()
    var sview:NSView!
    var allHeights = CGFloat(0)
    
    private func configurePannel(){
        
        pannelScrollView.wantsLayer = true
        view.addSubview(pannelScrollView)
        
        pannelScrollView.drawsBackground = false
        pannelScrollView.allowsMagnification = false
        pannelScrollView.contentView.wantsLayer = true
        
        sview = NSView(frame: pannelScrollView.bounds)
        sview.wantsLayer = true
        sview.layer?.backgroundColor = IMPColor.clearColor().CGColor
        pannelScrollView.documentView = sview
        
        pannelScrollView.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(280)
            make.top.equalTo(pannelScrollView.superview!).offset(10)
            make.bottom.equalTo(pannelScrollView.superview!).offset(10)
            make.right.equalTo(pannelScrollView.superview!).offset(-10)
        }
        
        sview.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(pannelScrollView).inset(NSEdgeInsetsMake(10, 10, 10, 10))
        }
        
        histogramView = IMPHistogramView(context: context, frame: view.bounds)
        
        sview.addSubview(histogramView)
        
        
        histogramView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(sview).offset(0)
            make.left.equalTo(sview).offset(0)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(200)
        }
        allHeights+=200
        
        let last = configureFilterSettings()
        
        configureWeightsPannel(last)
    }
    
    private func configureFilterSettings() -> NSView {
        
        let awbLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(awbLabel)
        awbLabel.stringValue = "White Balance"
        awbLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(histogramView.snp_bottom).offset(20)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(20)
        }
        allHeights+=40
        
        let awbSlider = NSSlider(frame: view.bounds)
        awbSlider.minValue = 0
        awbSlider.maxValue = 100
        awbSlider.integerValue = 100
        awbSlider.action = #selector(ViewController.changeAWB(_:))
        awbSlider.continuous = true
        sview.addSubview(awbSlider)
        awbSlider.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(awbLabel.snp_bottom).offset(5)
            make.left.equalTo(sview).offset(0)
            make.right.equalTo(sview).offset(0)
        }
        allHeights+=40
        
        let clutLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(clutLabel)
        clutLabel.stringValue = "CLUT Impact"
        clutLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(awbSlider.snp_bottom).offset(20)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(20)
        }
        allHeights+=40
        
        let clutSlider = NSSlider(frame: view.bounds)
        clutSlider.minValue = 0
        clutSlider.maxValue = 100
        clutSlider.integerValue = 100
        clutSlider.action = #selector(ViewController.changeClut(_:))
        clutSlider.continuous = true
        sview.addSubview(clutSlider)
        clutSlider.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(clutLabel.snp_bottom).offset(5)
            make.left.equalTo(sview).offset(0)
            make.right.equalTo(sview).offset(0)
        }
        allHeights+=40
        
        return clutSlider
    }
    
    func changeAWB(sender:NSSlider){
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.filter.adjustment.blending.opacity = value
        }
    }
    
    func changeClut(sender:NSSlider){
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.lutFilter?.adjustment.blending.opacity = value
        }
    }
    
    override func viewDidLayout() {
        let h = view.bounds.height < allHeights ? allHeights : view.bounds.height
        sview.snp_remakeConstraints { (make) -> Void in
            make.top.equalTo(pannelScrollView).offset(0)
            make.left.equalTo(pannelScrollView).offset(0)
            make.right.equalTo(pannelScrollView).offset(0)
            make.height.equalTo(h)
        }
    }
}

