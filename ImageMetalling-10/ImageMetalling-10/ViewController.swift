//
//  ViewController.swift
//  ImageMetalling-10
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

//
// Расчет цветоконтрастной вариативности изображения по гистограмме
//
extension IMPHistogram {
    func variability()  -> Float {
        var e:Float = 0
        for i in 0..<channels.count {
            e += entropy(channel: IMPHistogram.ChannelNo(rawValue: i)!)
        }
        return e / channels.count.float / log2(size.float) * 100
    }
    
    //
    // Средная поканальная энтропия
    //
    func averageEntropy()  -> Float {
        var e:Float = 0
        for i in 0...2 {
            e += entropy(channel: IMPHistogram.ChannelNo(rawValue: i)!)
        }
        return e / 3
    }
}

//
// Анализатор вариативности
//
public class DHCVariabilityAnalyzer: IMPHistogramAnalyzer {
    public required init(context: IMPContext) {
        //
        // Основной расчет производим в kernel-функции Metal
        //
        super.init(context: context, function: "kernel_variabilityPartial")
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
    var filter:IMPFilter!

    var awb:IMPAutoWBFilter!
    
    //
    // Анализатор диапазона светов через гистограмму изображения
    //
    var sourceVariability:DHCVariabilityAnalyzer!
    
    //
    // Повышение контраста
    //
    var contrast:IMPContrastFilter!
    
    //
    // Изменение насыщенности
    //
    var saturation:IMPSaturationFilter!
    
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
        
        filter = IMPFilter(context: context)
        
        awb = IMPAutoWBFilter(context: context)
        
        filter.addFilter(awb)
        
        //
        // Добавляем Регулировку контраста
        //
        contrast = IMPContrastFilter(context: context)
        contrast.adjustment.blending.mode = LUMINOSITY
        filter.addFilter(contrast)
        
        //
        // Настраиваем автоматическую регулировку контраста через анализ гистограммы
        //
        let rangeSolver = IMPHistogramRangeSolver()
        //rangeSolver.clipping.shadows = 0
        //rangeSolver.clipping.highlights = 0
        
        //
        // Гистограмма исходного изображения с солвером диапазона яростей
        //
        sourceVariability = DHCVariabilityAnalyzer(context: context)
        
        //
        // Солвер диапазона добавляем к списку солверов гистограммы
        //
        sourceVariability.addSolver(rangeSolver)
        
        sourceVariability.addUpdateObserver { (histogram) -> Void in
            //
            // При каждом обновлении источника обновляем контрас сцены
            //
            self.contrast.adjustment.minimum = rangeSolver.minimum
            self.contrast.adjustment.maximum = rangeSolver.maximum
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.variabilitySourceLabel.stringValue = String(format: "%2.3f", histogram.variability())
                let er = histogram.entropy(channel: .X)
                let eg = histogram.entropy(channel: .Y)
                let eb = histogram.entropy(channel: .Z)
                let ew = histogram.entropy(channel: .W)
                self.entropySourceLabel.stringValue = String(format: "%2.3f, %2.3f, %2.3f, %2.3f", er, eg, eb, ew)
            })
        }
        
        //
        // Расчет гистограммы источника
        //
        filter.addSourceObserver { (source) -> Void in
            self.sourceVariability.source = source
        }
        
        //
        // Добавляем фильтр управляющий насыщенностью
        //
        saturation = IMPSaturationFilter(context: context)
        
        filter.addFilter(saturation)
        
        //
        // Добавляем гистограмму для анализа энтропии
        //
        let destinationVariability = DHCVariabilityAnalyzer(context: context)
        
        //
        // Вычисдение гистограммы результирующей текстуры
        //
        filter.addDestinationObserver { (destination) -> Void in
            destinationVariability.source = destination
        }
        
        //
        // Добавляем обновлялку значений энтропии в метке NSLabel
        //
        destinationVariability.addUpdateObserver({ (histogram) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.variabilityDestinationLabel.stringValue = String(format: "%2.3f", histogram.variability())
                let er = histogram.entropy(channel: .X)
                let eg = histogram.entropy(channel: .Y)
                let eb = histogram.entropy(channel: .Z)
                let ew = histogram.entropy(channel: .W)
                self.entropyDestinationLabel.stringValue = String(format: "%2.3f, %2.3f, %2.3f, %2.3f", er, eg, eb, ew)
            })
        })
        
        //
        // Окно отображения картинки
        //
        imageView = IMPImageView(context: context, frame: view.bounds)
        imageView.filter = filter
        imageView.backgroundColor = IMPColor(color: IMPPrefs.colors.background)
        
        //
        // Добавляем наблюдателя к фильтру для обработки результатов
        // фильтрования
        //
        filter.addDestinationObserver { (destination) -> Void in
            // передаем картинку показывателю гистограммы
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
        
        reset(nil)
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
    
    var variabilitySourceLabel      = IMPLabel()
    var variabilityDestinationLabel = IMPLabel()
    
    var entropySourceLabel       = IMPLabel()
    var entropyDestinationLabel  = IMPLabel()
    
    private func configureWeightsPannel(view:NSView){
        
        let font  = NSFont(name: "Courier", size: 12)
        let fontS = NSFont(name: "Courier", size: 10)
        let fontB = NSFont(name: "Courier", size: 20)
        
        variabilitySourceLabel.font = fontB
        variabilityDestinationLabel.font = fontB
        entropySourceLabel.font = fontS
        entropyDestinationLabel.font = fontS
        
        let label1  = IMPLabel()
        sview.addSubview(label1)
        label1.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(5)
            make.height.equalTo(20)
        }
        
        sview.addSubview(variabilitySourceLabel)
        variabilitySourceLabel.stringValue = "0"
        variabilitySourceLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view.snp_bottom).offset(10)
            make.left.equalTo(label1.snp_right).offset(2)
            make.height.equalTo(20)
        }
        allHeights+=40
        
        let label2  = IMPLabel()
        sview.addSubview(label2)
        label2.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(label1.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(5)
            make.height.equalTo(20)
        }
        
        sview.addSubview(variabilityDestinationLabel)
        variabilityDestinationLabel.stringValue = "0"
        variabilityDestinationLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(variabilitySourceLabel.snp_bottom).offset(10)
            make.left.equalTo(label2.snp_right).offset(2)
            make.height.equalTo(20)
        }
        allHeights+=40
        
        let label3  = IMPLabel()
        sview.addSubview(label3)
        label3.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(label2.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(5)
            make.height.equalTo(20)
        }
        
        sview.addSubview(entropySourceLabel)
        entropySourceLabel.stringValue = "0"
        entropySourceLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(variabilityDestinationLabel.snp_bottom).offset(10)
            make.left.equalTo(label3.snp_right).offset(2)
            make.height.equalTo(20)
        }
        allHeights+=40
        
        let label4  = IMPLabel()
        sview.addSubview(label4)
        label4.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(label3.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(5)
            make.height.equalTo(20)
        }
        
        sview.addSubview(entropyDestinationLabel)
        entropyDestinationLabel.stringValue = "0"
        entropyDestinationLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(entropySourceLabel.snp_bottom).offset(10)
            make.left.equalTo(label4.snp_right).offset(2)
            make.height.equalTo(20)
        }
        allHeights+=40
        
        label1.font = font
        label2.font = font
        label3.font = font
        label4.font = font
        
        label1.stringValue = "Source var./avrgEntr.:"
        label2.stringValue = " Dest. var./avrgEntr.:"
        label3.stringValue = "Source entropy:"
        label4.stringValue = " Dest. entropy:"
        
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
    
    var awbValueLabel = IMPLabel()
    var contrastValueLabel = IMPLabel()
    var saturationValueLabel = IMPLabel()
    
    private func configureFilterSettings() -> NSView {
        
        let awbLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(awbLabel)
        awbLabel.stringValue = "White Balance"
        awbLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(histogramView.snp_bottom).offset(20)
            make.left.equalTo(sview).offset(0)
            make.height.equalTo(20)
        }
        allHeights+=40

        awbValueLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(awbValueLabel)
        awbValueLabel.stringValue = "0"
        awbValueLabel.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(sview.snp_centerX).offset(0)
            make.centerY.equalTo(awbLabel.snp_centerY).offset(0)
            make.height.equalTo(20)
        }

        awbSlider = NSSlider(frame: view.bounds)
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
        
        
        let contrastLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(contrastLabel)
        contrastLabel.stringValue = "Contrast level"
        contrastLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(awbSlider.snp_bottom).offset(20)
            make.left.equalTo(sview).offset(0)
            make.height.equalTo(20)
        }
        allHeights+=40
        
        contrastValueLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(contrastValueLabel)
        contrastValueLabel.stringValue = "0"
        contrastValueLabel.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(sview.snp_centerX).offset(0)
            make.centerY.equalTo(contrastLabel.snp_centerY).offset(0)
            make.height.equalTo(20)
        }

        contrastSlider = NSSlider(frame: view.bounds)
        contrastSlider.minValue = 0
        contrastSlider.maxValue = 100
        contrastSlider.integerValue = 100
        contrastSlider.action = #selector(ViewController.contrastLevel(_:))
        contrastSlider.continuous = true
        sview.addSubview(contrastSlider)
        contrastSlider.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(contrastLabel.snp_bottom).offset(5)
            make.left.equalTo(sview).offset(0)
            make.right.equalTo(sview).offset(0)
        }
        allHeights+=40
        
        let saturationLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(saturationLabel)
        saturationLabel.stringValue = "Saturation level"
        saturationLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(contrastSlider.snp_bottom).offset(20)
            make.left.equalTo(sview).offset(0)
            make.height.equalTo(20)
        }
        allHeights+=40
        
        saturationValueLabel  = IMPLabel(frame: view.bounds)
        sview.addSubview(saturationValueLabel)
        saturationValueLabel.stringValue = "0"
        saturationValueLabel.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(sview.snp_centerX).offset(0)
            make.centerY.equalTo(saturationLabel.snp_centerY).offset(0)
            make.height.equalTo(20)
        }

        saturationLevelSlider = NSSlider(frame: view.bounds)
        saturationLevelSlider.minValue = 0
        saturationLevelSlider.maxValue = 100
        saturationLevelSlider.integerValue = 50
        saturationLevelSlider.action = #selector(ViewController.saturationLevel(_:))
        saturationLevelSlider.continuous = true
        sview.addSubview(saturationLevelSlider)
        saturationLevelSlider.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(saturationLabel.snp_bottom).offset(5)
            make.left.equalTo(sview).offset(0)
            make.right.equalTo(sview).offset(0)
        }
        allHeights+=40
        
        
        let reset = NSButton(frame: NSRect(x: 230, y: 0, width: 50, height: view.bounds.height))
        reset.title = "Reset"
        reset.target = self
        reset.action = #selector(ViewController.reset(_:))
        sview.addSubview(reset)
        
        reset.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(saturationLevelSlider.snp_bottom).offset(10)
            make.center.equalTo(sview).offset(0)
            make.width.equalTo(120)
            make.height.equalTo(20)
        }
        allHeights += 20
        
        let disable =  NSButton(frame: NSRect(x: 230, y: 0, width: 50, height: view.bounds.height))
        
        let attrTitle = NSMutableAttributedString(string: "Enable")
        attrTitle.addAttribute(NSForegroundColorAttributeName, value: IMPColor.whiteColor(), range: NSMakeRange(0, attrTitle.length))
        
        disable.attributedTitle = attrTitle
        disable.setButtonType(.SwitchButton)
        disable.target = self
        disable.action = #selector(ViewController.disable(_:))
        disable.state = 1
        sview.addSubview(disable)
        
        disable.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(reset.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(10)
            make.width.equalTo(120)
            make.height.equalTo(20)
        }
        allHeights += 20

        return disable
    }
    
    var awbSlider:NSSlider!
    var contrastSlider:NSSlider!
    var saturationLevelSlider:NSSlider!
    
    func changeAWB(sender:NSSlider){
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.awb.adjustment.blending.opacity = value
            self.awbValueLabel.stringValue = String(format: "%2.3f",value)
        }
    }
    
    func contrastLevel(sender:NSSlider){
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.contrast.adjustment.blending.opacity = value
            self.contrastValueLabel.stringValue = String(format: "%2.3f",value)
        }
    }
    
    func saturationLevel(sender:NSSlider){
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.saturation.adjustment.level = value
            self.saturationValueLabel.stringValue = String(format: "%2.3f",value)
        }
    }
    
    func reset(sender:NSButton?){
        self.awb.adjustment.blending.opacity = 0
        self.contrast.adjustment.blending.opacity = 0
        self.saturation.adjustment.level = 0.5
        
        awbSlider.intValue = 0
        contrastSlider.intValue = 0
        saturationLevelSlider.intValue = 50
        
        self.awbValueLabel.stringValue = String(format: "%2.3f",0.0)
        self.contrastValueLabel.stringValue = String(format: "%2.3f",0.0)
        self.saturationValueLabel.stringValue = String(format: "%2.3f",0.5)
    }
        
    func disable(sender:NSButton){
        if filter?.enabled == true {
            filter?.enabled = false
        }
        else {
            filter?.enabled = true
        }
        filter.apply() 
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

