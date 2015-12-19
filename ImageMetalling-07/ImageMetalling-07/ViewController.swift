//
//  ViewController.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 14.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import simd

enum IMPPrefs{
    struct colors {
        static let background = float4(x:0.1,y:0.1,z:0.1,w:1.0)
    }
}

class ViewController: NSViewController {
    
    @IBOutlet weak var valueSlider1: NSSlider!
    @IBOutlet weak var textValueLabel: NSTextField!
    @IBOutlet weak var histogramCDFContainerView: NSView!
    @IBOutlet weak var histogramContainerView: NSView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    var imageView: IMPView!
    var histogramView: IMPHistogramView!
    var histogramCDFView: IMPHistogramView!
    
    
    @IBAction func changeValue1(sender: NSSlider) {
        let value = sender.floatValue/100
        histogramCDFView.histogram.solver.histogramType = (type:.CDF,power:value)
        textValueLabel.stringValue = String(format: "%2.5f", value);
    }
    
    
    @IBAction func changeValue2(sender: NSSlider) {
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        histogramContainerView.wantsLayer = true
        histogramContainerView.layer?.backgroundColor = IMPColor.redColor().CGColor
        
        histogramView = IMPHistogramView(frame: histogramContainerView.bounds)
        histogramView.histogram.solver.layer.backgroundColor = IMPPrefs.colors.background
        
        histogramCDFView = IMPHistogramView(frame: histogramContainerView.bounds)
        histogramCDFView.histogram.solver.layer.backgroundColor = IMPPrefs.colors.background
        histogramCDFView.histogram.solver.histogramType = (type:.CDF,power:self.valueSlider1.floatValue/100)
        
        histogramContainerView.addSubview(histogramView)
        histogramCDFContainerView.addSubview(histogramCDFView)
        
        imageView = IMPView(frame: scrollView.bounds)
        
        imageView.filter = IMPTestFilter(context: IMPContext(), histogramView: histogramView, histogramCDFView: histogramCDFView)
        
        scrollView.drawsBackground = false
        scrollView.documentView = imageView
        scrollView.allowsMagnification = true
        scrollView.acceptsTouchEvents = true
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "magnifyChanged:",
            name: NSScrollViewWillStartLiveMagnifyNotification,
            object: nil)
        
        IMPDocument.sharedInstance.addDocumentObserver { (file) -> Void in
            if let image = IMPImage(contentsOfFile: file){
                self.imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                self.imageView.source = IMPImageProvider(context: self.imageView.context, image: image)
                dispatch_after(2, dispatch_get_main_queue()) { () -> Void in
                    self.zoomOne()
                }
            }
        }
        
        IMPMenuHandler.sharedInstance.addMenuObserver { (item) -> Void in
            switch(item.tag){
            case 3004:
                self.zoomOne()
            case 3005:
                self.zoom100()
            default: break
            }
        }
    }
    
    @objc func magnifyChanged(event:NSNotification){
        is100 = false
    }
    
    var is100 = false
    
    private func zoomOne(){
        self.scrollView.magnifyToFitRect(self.scrollView.bounds)
        is100 = false
    }
    
    private func zoom100(){
        self.scrollView.magnifyToFitRect(self.imageView.bounds)
        is100 = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        dispatch_after(2, dispatch_get_main_queue()) { () -> Void in
            self.zoom100()
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        if is100 {
            dispatch_after(2, dispatch_get_main_queue()) { () -> Void in
                self.zoom100()
            }
        }
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

