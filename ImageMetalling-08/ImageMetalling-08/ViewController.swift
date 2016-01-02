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


class ViewController: NSViewController {

    let context = IMPContext()
    var imageView:IMPImageView!
    
    var pannelScrollView = NSScrollView()
    var histogramView:IMPHistogramView!
    var paletteView:IMPPaletteListView!
    
    var filter:IMPTestFilter!
    var histograCube:IMPHistogramCubeAnalyzer!
    var paletteSolver = IMPPaletteSolver()
    
    var paletteTypeChooser:NSSegmentedControl!
    
    override func viewDidLoad() {

        super.viewDidLoad()

        configurePannel()
        
        filter = IMPTestFilter(context: context)
        
        histograCube = IMPHistogramCubeAnalyzer(context: context)
        histograCube.addSolver(paletteSolver)
        
        imageView = IMPImageView(context: context, frame: view.bounds)
        imageView.filter = filter
        imageView.backgroundColor = IMPColor(color: IMPPrefs.colors.background)

        
        filter.addDestinationObserver { (destination) -> Void in
            self.histogramView.source = destination
            self.histograCube.source = destination
        }
        
        histograCube.downScaleFactor = 0.5
        
        histograCube.addUpdateObserver { (histogram) -> Void in
            self.asyncChanges({ () -> Void in
                self.paletteView.colorList = self.paletteSolver.colors
            })
        }
        
        
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(imageView.superview!).offset(10)
            make.bottom.equalTo(imageView.superview!).offset(10)
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
        
        paletteView = IMPPaletteListView(frame: view.bounds)
        paletteView.wantsLayer = true
        paletteView.layer?.backgroundColor = IMPColor.clearColor().CGColor

        sview.addSubview(paletteView)

        paletteView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(histogramView.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(0)
            make.right.equalTo(sview).offset(0)
            make.height.equalTo(320)
        }
        allHeights+=320
     
        configurePaletteTypeChooser()
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
        allHeights+=50
        
        paletteSizeLabel = NSTextField(frame: view.bounds)
        paletteSizeLabel.drawsBackground = false
        paletteSizeLabel.bezeled = false
        paletteSizeLabel.editable = false
        paletteSizeLabel.alignment = .Center
        paletteSizeLabel.textColor = IMPColor.lightGrayColor()
        paletteSizeLabel.stringValue = "Palette size: \(paletteSolver.maxColors)"
        sview.addSubview(paletteSizeLabel)
        paletteSizeLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(paletteTypeChooser.snp_centerY).offset(0)
            make.left.equalTo(paletteTypeChooser.snp_right).offset(10)
            make.width.equalTo(90)
        }
        
        let stepper = NSStepper(frame: view.bounds)
        stepper.integerValue = paletteSolver.maxColors
        stepper.maxValue = 16
        stepper.minValue = 4
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

