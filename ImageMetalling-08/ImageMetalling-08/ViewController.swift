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
    let context = IMPContext()
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
        
        //
        // Вся остальная часть относится к визуальному представления данных
        //
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(imageView.superview!).offset(10)
            make.bottom.equalTo(imageView.superview!).offset(-10)
            make.left.equalTo(imageView.superview!).offset(10)
            make.right.equalTo(pannelScrollView.snp_left).offset(-10)
        }
        
        
        // Do any additional setup after loading the view.
        
        IMPDocument.sharedInstance.addDocumentObserver { (file, type) -> Void in
            if type == .Image {
                if let image = IMPImage(contentsOfFile: file){
                    self.imageView.source = IMPImageProvider(context: self.imageView.context, image: image)
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
                }
            }
        }
    }
    
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
        super.viewDidAppear()
        asyncChanges { () -> Void in
            self.imageView.sizeFit()
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
        pannelScrollView.documentView = imageView
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
        
        histogramView = IMPHistogramView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
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
        
        let contrastLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(contrastLabel)
        contrastLabel.stringValue = "Contrast"
        contrastLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(paletteTypeChooser.snp_bottom).offset(20)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(20)
        }
        allHeights+=20
        
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
        allHeights+=20
        
        let awbLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(awbLabel)
        awbLabel.stringValue = "White Balance"
        awbLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(contrastSlider.snp_bottom).offset(20)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(20)
        }
        allHeights+=20
        
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
        allHeights+=20
    }
    
    func changeContrast(sender:NSSlider){
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.filter.contrastFilter.adjustment.blending.opacity = value
        }
    }

    func changeAWB(sender:NSSlider){
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.filter.awbFilter.adjustment.blending.opacity = value
        }
    }
    
    private func configurePaletteTypeChooser(){
        
        paletteTypeChooser = NSSegmentedControl(frame: view.bounds)
        sview.addSubview(paletteTypeChooser)
        
        paletteTypeChooser.segmentCount = 2
        paletteTypeChooser.trackingMode = .SelectOne
        paletteTypeChooser.setLabel("Palette", forSegment: 0)
        paletteTypeChooser.setLabel("Dominants", forSegment: 1)
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
                self.paletteSolver.type = .palette
            case 1:
                self.paletteSolver.type = .dominants
            default: break
            }
            self.histograCube.apply()
        }
    }
        
    
    override func viewDidLayout() {
        let h = view.bounds.height < allHeights ? allHeights+40 : view.bounds.height
        sview.snp_remakeConstraints { (make) -> Void in
            make.top.equalTo(pannelScrollView).offset(0)
            make.left.equalTo(pannelScrollView).offset(0)
            make.right.equalTo(pannelScrollView).offset(0)
            make.height.equalTo(h)
        }
        paletteView.reloadData()
    }
}

