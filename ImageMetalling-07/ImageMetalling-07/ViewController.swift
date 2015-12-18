//
//  ViewController.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 14.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import simd

class ViewController: NSViewController {
    
    @IBOutlet weak var histogramContainerView: NSView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    var imageView: IMPView!
    var histogramView: IMPView!
    
    class viewFilter:IMPFilter {
        
        var analayzer:IMPHistogramAnalyzer!
        let dominantSolver = IMPHistogramDominantColorSolver()
        let rangeSolver = IMPHistogramRangeSolver()
        
        required init(context: IMPContext) {
            
            super.init(context: context)
            
            self.addFunction(IMPFunction(context: self.context, name: "kernel_passthrough"))
            
            analayzer = IMPHistogramAnalyzer(context: self.context)
            
            analayzer.histogram = IMPHistogram(channels: 4)
            
            analayzer.downScaleFactor = 1
            analayzer.region = IMPCropRegion(top: 0.0, right: 0.0, left: 0.0, bottom: 0.0)
            
            analayzer.solvers.append(dominantSolver)
            analayzer.solvers.append(rangeSolver)
            
            analayzer.analyzerDidUpdate = { (histogram) in
                
//                print("\n")
//                print(" hsr = \(histogram.channels[0]);")
//                print(" hsg = \(histogram.channels[1]);")
//                print(" hsb = \(histogram.channels[2]);")
//                print(" hsy = \(histogram.channels[3]);")
//                print("hold on; plot(0:1/255:1, hsr/max(hsr), 'r'); plot(0:1/255:1, hsg/max(hsg), 'g'); plot(0:1/255:1, hsb/max(hsb), 'b'); plot(0:1/255:1, hsy/max(hsy), 'k'); grid on; axis([0 1 0 1]); ")
//                
//                print("\n")
                print(" *** range    = \(self.rangeSolver.min, self.rangeSolver.max)")
                print(" *** dominant = \(self.dominantSolver.color*255.0), \(self.dominantSolver.color)")
                
            }
            
            self.processingWillStart = { (source) in
                let t  = 10
                let t1 = NSDate .timeIntervalSinceReferenceDate()
                for _ in 0..<t{
                    self.analayzer.source = source
                }
                let t2 = NSDate .timeIntervalSinceReferenceDate()
                let size = Float((source.texture?.width)!*(source.texture?.height)!)*self.analayzer.downScaleFactor
                let s = size*Float(4*t*self.analayzer.histogram.channels.count)
                print(" *** wil start process: \(source) tm = \(t2-t1) rate=\(Float(s)/Float(t2-t1)/1024/1024)Mb/s")
            }
            
            self.processingDidFinish = { (destination) in
                print(" *** did finish process: \(destination)")
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = IMPColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1).CGColor
        
        histogramContainerView.wantsLayer = true
        histogramContainerView.layer?.backgroundColor = IMPColor.redColor().CGColor
        
        histogramView = IMPView(frame: histogramContainerView.bounds)
        histogramView.backgroundColor = IMPColor.blueColor()
        histogramContainerView.addSubview(histogramView)
        
        imageView = IMPView(frame: scrollView.bounds)
        
        imageView.filter = viewFilter(context: IMPContext())

        scrollView.drawsBackground = false
        scrollView.documentView = imageView
        scrollView.allowsMagnification = true
        scrollView.acceptsTouchEvents = true
        
        IMPDocument.sharedInstance.addDocumentObserver { (file) -> Void in
            if let image = IMPImage(contentsOfFile: file){
                
                NSLog(" *** View controller: file %@, %@", file, image)
                self.imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                self.imageView.source = IMPImageProvider(context: self.imageView.context, image: image)
                
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

