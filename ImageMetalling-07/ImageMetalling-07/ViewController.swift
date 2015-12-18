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
    
    @IBOutlet weak var histogramContainerView: NSView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    var imageView: IMPView!
    var histogramView: IMPView!
    
    class histogramLayer: IMPFilter {
        
        var analayzer:IMPHistogramAnalyzer!
        var histogram:IMPHistogramLayerSolver!
        
        required init(context: IMPContext) {
            
            super.init(context: context)
            
            histogram = IMPHistogramLayerSolver(context: self.context)
            histogram.layer.backgroundColor = IMPPrefs.colors.background
            
            self.addFilter(histogram)
            
            analayzer = IMPHistogramAnalyzer(context: self.context)
            analayzer.solvers.append(histogram)
                        
            self.processingWillStart = { (source) in
                self.analayzer.source = source
            }
        }
    }
    
    class viewFilter:IMPFilter {
        
        var analayzer:IMPHistogramAnalyzer!
        let dominantSolver = IMPHistogramDominantColorSolver()
        let rangeSolver = IMPHistogramRangeSolver()
        
        required init(context: IMPContext, histogram:histogramLayer) {
            
            super.init(context: context)
            
            self.addFunction(IMPFunction(context: self.context, name: "kernel_passthrough"))
            analayzer = IMPHistogramAnalyzer(context: self.context)
            
            analayzer.histogram = IMPHistogram(channels: 4)
            
            analayzer.downScaleFactor = 1
            analayzer.region = IMPCropRegion(top: 0.0, right: 0.0, left: 0.0, bottom: 0.0)
            
            analayzer.solvers.append(dominantSolver)
            analayzer.solvers.append(rangeSolver)
            
            analayzer.analyzerDidUpdate = { (histogram) in
                
                print(" *** range    = \(self.rangeSolver.min, self.rangeSolver.max)")
                print(" *** dominant = \(self.dominantSolver.color*255.0), \(self.dominantSolver.color)")
                
            }
            
            self.processingWillStart = { (source) in
                self.analayzer.source = source
                //histogram.source = source
            }
        }

        required init(context: IMPContext) {
            fatalError("init(context:) has not been implemented")
        }
        
        var redraw: (()->Void)?
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = IMPColor(color: IMPPrefs.colors.background).CGColor
        
        histogramContainerView.wantsLayer = true
        histogramContainerView.layer?.backgroundColor = IMPColor.redColor().CGColor
        
        
        histogramView = IMPView(frame: histogramContainerView.bounds)
        histogramView.backgroundColor = IMPColor.blueColor()
        
        let hfilter = histogramLayer(context: IMPContext())
        
        histogramView.filter = hfilter

        histogramContainerView.addSubview(histogramView)

        
        imageView = IMPView(frame: scrollView.bounds)
        
        imageView.filter = viewFilter(context: IMPContext(), histogram: hfilter)
        
        scrollView.drawsBackground = false
        scrollView.documentView = imageView
        scrollView.allowsMagnification = true
        scrollView.acceptsTouchEvents = true
        
        IMPDocument.sharedInstance.addDocumentObserver { (file) -> Void in
            if let image = IMPImage(contentsOfFile: file){
                
                NSLog(" *** View controller: file %@, %@", file, image)
                self.imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                self.imageView.source = IMPImageProvider(context: self.imageView.context, image: image)
                self.histogramView.source = self.imageView.source
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
        
    private func zoomOne(){
        self.scrollView.magnifyToFitRect(self.scrollView.bounds)
    }
    
    private func zoom100(){
        self.scrollView.magnifyToFitRect(self.imageView.bounds)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

