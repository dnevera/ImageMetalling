//
//  ViewController.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 14.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import simd
import IMProcessing

enum IMPPrefs{
    struct colors {
        static let background = float4(x:0.1,y:0.1,z:0.1,w:1.0)
    }
}

class ViewController: NSViewController {
    
    @IBOutlet weak var dominantColorLabel: NSTextField!
    @IBOutlet weak var minRangeLabel: NSTextField!
    @IBOutlet weak var maxRangeLabel: NSTextField!
    @IBOutlet weak var textValueLabel: NSTextField!
    @IBOutlet weak var histogramCDFContainerView: NSView!
    @IBOutlet weak var histogramContainerView: NSView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    let context = IMPContext()
    
    var mainFilter:IMPTestFilter!
    
    var imageView: IMPView!
    
    var histogramView: IMPHistogramView!
    var histogramCDFView: IMPHistogramView!
    
    private func asyncChanges(block:()->Void) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            //
            // немного того, но... :)
            //
            dispatch_after(2, dispatch_get_main_queue()) { () -> Void in
                block()
            }
        })
    }
    
    var currentCollors = 1000
    @IBOutlet weak var circlePopUpButton: NSPopUpButtonCell!
    @IBAction func chooseColors(sender: NSMenuItem) {
        asyncChanges { () -> Void in
            self.circlePopUpButton.setTitle(sender.title)
            self.currentCollors = sender.tag
            self.updateSliders(self.currentCollors)
        }
    }
    
    
    
    @IBOutlet weak var hueSlider: NSSlider!
    @IBOutlet weak var saturationSlider: NSSlider!
    @IBOutlet weak var valueSlider: NSSlider!
    @IBOutlet weak var overlapSlider: NSSlider!
    
    func updateSliders(colorsIndex:Int){
        
        let l = mainFilter.hsvFilter.adjustment[colorsIndex]
        
        hueSlider.floatValue = (l.hue/2 + 0.5) * 100
        saturationSlider.floatValue = (l.saturation/2+0.5) * 100
        valueSlider.floatValue = (l.value/2+0.5) * 100
        overlapSlider.floatValue = mainFilter.hsvFilter.overlap * 100
    }
    
    @IBAction func resetHsv(sender: NSButton) {
        mainFilter.hsvFilter.adjustment = IMPHSVFilter.defaultAdjustment
        for i in 0...6 {
            updateSliders(i)
        }
    }
    
    @IBAction func changeValue1(sender: NSSlider) {
        let value = sender.floatValue/100
        asyncChanges { () -> Void in
            self.mainFilter.hsvFilter.overlap = value
        }
    }
    
    @IBAction func changeValue2(sender: NSSlider) {
        let value = (sender.floatValue/100 - 0.5 ) * 2
        asyncChanges { () -> Void in
            self.mainFilter.hsvFilter.adjustment.hue(index:self.currentCollors, value:value)
        }
    }
    
    @IBAction func changeValue3(sender: NSSlider) {
        let value = (sender.floatValue/100 - 0.5 ) * 2
        asyncChanges { () -> Void in
            self.mainFilter.hsvFilter.adjustment.saturation(index:self.currentCollors, value:value)
        }
    }
    
    @IBAction func changeValue4(sender: NSSlider) {
        let value = (sender.floatValue/100 - 0.5 ) * 2
        asyncChanges { () -> Void in
            self.mainFilter.hsvFilter.adjustment.value(index:self.currentCollors, value:value)
        }
    }

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        circlePopUpButton.setTitle("Master")

        histogramContainerView.wantsLayer = true
        histogramContainerView.layer?.backgroundColor = IMPColor.redColor().CGColor
        
        histogramView = IMPHistogramView(frame: histogramContainerView.bounds)
        histogramView.histogram.solver.layer.backgroundColor = IMPPrefs.colors.background
        
        histogramCDFView = IMPHistogramView(frame: histogramContainerView.bounds)
        histogramCDFView.histogram.solver.layer.backgroundColor = IMPPrefs.colors.background
        histogramCDFView.histogram.solver.histogramType = (type:.CDF,power:1)
        
        histogramContainerView.addSubview(histogramView)
        histogramCDFContainerView.addSubview(histogramCDFView)
        
        imageView = IMPView(frame: scrollView.bounds)
        
        mainFilter = IMPTestFilter(context: self.context)
        imageView.filter = mainFilter
        
        IMPDocument.sharedInstance.filter = mainFilter
        
        mainFilter.addDestinationObserver { (destination) -> Void in
            self.asyncChanges { () -> Void in
                self.histogramView.source = destination
                self.histogramCDFView.source = destination
            }
        }

        
        scrollView.drawsBackground = false
        scrollView.documentView = imageView
        scrollView.allowsMagnification = true
        scrollView.acceptsTouchEvents = true
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "magnifyChanged:",
            name: NSScrollViewWillStartLiveMagnifyNotification,
            object: nil)
        
        IMPDocument.sharedInstance.addDocumentObserver { (file, type) -> Void in
            if type == .Image {
                if let image = IMPImage(contentsOfFile: file){
                    self.imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                    self.imageView.source = IMPImageProvider(context: self.imageView.context, image: image)
                    self.asyncChanges({ () -> Void in
                        self.zoomOne()                        
                    })
                }
            }
        }
        
        IMPMenuHandler.sharedInstance.addMenuObserver { (item) -> Void in
            if let tag = IMPMenuTag(rawValue: item.tag) {
                switch tag {
                case .zoomOne:
                    self.zoomOne()
                case .zoom100:
                    self.zoom100()
                default: break
                }
            }
        }
    }
    
    @objc func magnifyChanged(event:NSNotification){
        is100 = false
    }
    
    var is100 = false
    
    private func zoomOne(){
        is100 = false
        asyncChanges { () -> Void in
            self.scrollView.magnifyToFitRect(self.scrollView.bounds)
        }
    }
    
    private func zoom100(){
        is100 = true
        asyncChanges { () -> Void in
            self.scrollView.magnifyToFitRect(self.imageView.bounds)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.zoom100()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        if is100 {
            self.zoom100()
        }
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

