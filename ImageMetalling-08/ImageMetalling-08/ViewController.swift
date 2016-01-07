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
    
    var pannelScrollView = NSScrollView()
    
    //
    // Окно вывода гистограммы изображения
    //
    var histogramView:IMPHistogramView!
    
    //
    // NSTableView - представления списка цветов из палитры
    //
    var paletteView:IMPPaletteListView!
    
    //
    // Основной фильтр
    //
    var filter:IMPTestFilter!
    
    //
    // Фильтр CLUT из фалов формата Adobe Cube
    //
    var lutFilter:IMPLutFilter?
    
    //
    // Анализатор кубической гистограммы изображения в RGB пространстве
    //
    var histograCube:IMPHistogramCubeAnalyzer!
    
    //
    // Наш солвер для поиска цветов
    //
    var paletteSolver = IMPPaletteSolver()
    
    var paletteTypeChooser:NSSegmentedControl!
    
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
        // Инициализируем кучу нужных нам объектов
        //
        
        filter = IMPTestFilter(context: context)
        
        histograCube = IMPHistogramCubeAnalyzer(context: context)
        histograCube.addSolver(paletteSolver)
        
        imageView = IMPImageView(context: context, frame: view.bounds)
        imageView.filter = filter
        imageView.backgroundColor = IMPColor(color: IMPPrefs.colors.background)
        
        //
        // Добавляем еще один хендлер к наблюдению за исходной картинкой
        // (еще один был доавлен в основном фильтре IMPTestFilter)
        //
        filter.addSourceObserver { (source) -> Void in
            //
            // для минимизации расчетов анализатор будет сжимать картинку до 1000px по широкой стороне
            //
            if let size = source.texture?.size {
                let scale = 1000/max(size.width,size.height)
                self.histograCube.downScaleFactor = scale.float
            }
        }
                
        //
        // Добавляем наблюдателя к фильтру для обработки результатов
        // фильтрования
        //
        filter.addDestinationObserver { (destination) -> Void in
            
            // передаем картинку показывателю кистограммы
            self.histogramView.source = destination
            
            // передаем результат в анализатор кубической гистограммы
            self.histograCube.source = destination
        }
        
        //
        // Результаты обновления расчета анализатора выводим в окне списка цветов
        //
        histograCube.addUpdateObserver { (histogram) -> Void in
            self.asyncChanges({ () -> Void in
                self.paletteView.colorList = self.paletteSolver.colors
            })
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
                    self.imageView.source = try IMPImageProvider(context: self.context, file: file)
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
        
        histogramView = IMPHistogramView(context: context)
        histogramView.backgroundColor = IMPColor.clearColor()
        
        sview.addSubview(histogramView)
        
        
        histogramView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(sview).offset(0)
            make.left.equalTo(sview).offset(0)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(200)
        }
        allHeights+=200
        
        let label  = IMPLabel(frame: view.bounds)
        sview.addSubview(label)
        label.stringValue = "Palette"
        label.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(histogramView.snp_bottom).offset(20)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(20)
        }
        allHeights+=20
        
        paletteView = IMPPaletteListView(frame: view.bounds)
        paletteView.wantsLayer = true
        paletteView.layer?.backgroundColor = IMPColor.clearColor().CGColor
        
        sview.addSubview(paletteView)
        
        paletteView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(label.snp_bottom).offset(5)
            make.left.equalTo(sview).offset(0)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(320)
        }
        allHeights+=320
        
        configurePaletteTypeChooser()
        
        configureFilterSettings()
    }
    
    private func configureFilterSettings(){
        
        let clippingLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(clippingLabel)
        clippingLabel.stringValue = "Colors clipping"
        clippingLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(paletteTypeChooser.snp_bottom).offset(20)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(20)
        }
        allHeights+=40
        
        let clippingSlider = NSSlider(frame: view.bounds)
        clippingSlider.minValue = 0
        clippingSlider.maxValue = 100
        clippingSlider.integerValue = 50
        clippingSlider.target = self
        clippingSlider.action = "changeClippingColors:"
        clippingSlider.continuous = true
        sview.addSubview(clippingSlider)
        clippingSlider.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(clippingLabel.snp_bottom).offset(5)
            make.left.equalTo(sview).offset(0)
            make.right.equalTo(sview).offset(0)
        }
        allHeights+=40
        
        let contrastLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(contrastLabel)
        contrastLabel.stringValue = "Contrast"
        contrastLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(clippingSlider.snp_bottom).offset(20)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(20)
        }
        allHeights+=40
        
        let contrastSlider = NSSlider(frame: view.bounds)
        contrastSlider.minValue = 0
        contrastSlider.maxValue = 100
        contrastSlider.integerValue = 100
        contrastSlider.target = self
        contrastSlider.action = "changeContrast:"
        contrastSlider.continuous = true
        sview.addSubview(contrastSlider)
        contrastSlider.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(contrastLabel.snp_bottom).offset(5)
            make.left.equalTo(sview).offset(0)
            make.right.equalTo(sview).offset(0)
        }
        allHeights+=40
        
        let awbLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(awbLabel)
        awbLabel.stringValue = "White Balance"
        awbLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(contrastSlider.snp_bottom).offset(20)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(20)
        }
        allHeights+=40
        
        let awbSlider = NSSlider(frame: view.bounds)
        awbSlider.minValue = 0
        awbSlider.maxValue = 100
        awbSlider.integerValue = 100
        awbSlider.action = "changeAWB:"
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
        clutSlider.action = "changeClut:"
        clutSlider.continuous = true
        sview.addSubview(clutSlider)
        clutSlider.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(clutLabel.snp_bottom).offset(5)
            make.left.equalTo(sview).offset(0)
            make.right.equalTo(sview).offset(0)
        }
        allHeights+=40
    }
    
    func changeContrast(sender:NSSlider){
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.filter.contrastFilter.adjustment.blending.opacity = value
        }
    }
    
    func changeClippingColors(sender:NSSlider){
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.histograCube.clipping.shadows = IMPHistogramCubeAnalyzer.defaultClipping.shadows  * 2 * value
            self.histograCube.clipping.highlights = IMPHistogramCubeAnalyzer.defaultClipping.highlights * 2 * value
        }
    }
    
    func changeAWB(sender:NSSlider){
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.filter.awbFilter.adjustment.blending.opacity = value
        }
    }
    
    func changeClut(sender:NSSlider){
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.lutFilter?.adjustment.blending.opacity = value
        }
    }
    
    private func configurePaletteTypeChooser(){
        
        paletteTypeChooser = NSSegmentedControl(frame: view.bounds)
        sview.addSubview(paletteTypeChooser)
        
        paletteTypeChooser.segmentCount = 2
        paletteTypeChooser.trackingMode = .SelectOne
        paletteTypeChooser.setLabel("Dominants", forSegment: 0)
        paletteTypeChooser.setLabel("Palette", forSegment: 1)
        paletteTypeChooser.selectedSegment = 0
        paletteTypeChooser.target = self
        paletteTypeChooser.action = "changePaletteType:"
        
        paletteTypeChooser.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(paletteView.snp_bottom).offset(10)
            make.left.equalTo(paletteView).offset(0)
        }
        
        paletteSizeLabel = IMPLabel(frame: view.bounds)
        paletteSizeLabel.stringValue = "Palette size: \(paletteSolver.maxColors)"
        sview.addSubview(paletteSizeLabel)
        paletteSizeLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(paletteTypeChooser.snp_centerY).offset(0)
            make.left.equalTo(paletteTypeChooser.snp_right).offset(10)
            make.width.equalTo(90)
        }
        
        let stepper = NSStepper(frame: view.bounds)
        stepper.integerValue = paletteSolver.maxColors
        stepper.maxValue = 8
        stepper.minValue = 3
        stepper.increment = 1
        stepper.target = self
        stepper.action = "changePaletteSize:"
        sview.addSubview(stepper)
        stepper.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(paletteSizeLabel.snp_centerY).offset(0)
            make.left.equalTo(paletteSizeLabel.snp_right).offset(10)
        }
        allHeights+=50
    }
    
    var paletteSizeLabel:NSTextField!
    func changePaletteSize(sender:NSStepper){
        asyncChanges { () -> Void in
            self.paletteSizeLabel?.stringValue = "\(sender.intValue)"
            self.paletteSolver.maxColors = sender.integerValue
            self.histograCube.apply()
        }
    }
    
    func changePaletteType(sender:NSSegmentedControl){
        asyncChanges { () -> Void in
            switch sender.selectedSegment {
            case 0:
                self.paletteSolver.type = .dominants
            case 1:
                self.paletteSolver.type = .palette
            default: break
            }
            self.histograCube.apply()
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
        paletteView.reloadData()
    }
}

