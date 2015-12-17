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
    
    
    @IBOutlet weak var imageView: IMPView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    class IMPDesaturateFilter:IMPFilter {
        
        var analayzer:IMPHistogramAnalyzer!
        let dominantSolver = IMPHistogramDominantColorSolver()
        let rangeSolver = IMPHistogramRangeSolver()
        
        required init(context: IMPContext) {
            
            super.init(context: context)
            //let kernel = IMPFunction(context: self.context, name: "kernel_desaturate")
            let kernel = IMPFunction(context: self.context, name: "kernel_passthrough")
            self.addFunction(kernel)
            
            analayzer = IMPHistogramAnalyzer(context: self.context)
            analayzer.solvers.append(dominantSolver)
            analayzer.solvers.append(rangeSolver)
            
            analayzer.analyzerDidUpdate = { (histogram) in
                
                //print(" hs = \(histogram.channels[0]);")
                //print(" hs = \(histogram)")
                
                print(" range    = \(self.rangeSolver.min, self.rangeSolver.max)")
                print(" dominant = \(self.dominantSolver.color*255.0)")
                
            }
            
            self.processingWillStart = { (source) in
                let t  = 1
                let t1 = NSDate .timeIntervalSinceReferenceDate()
                for _ in 0..<t{
                    self.analayzer.source = source
                }
                let t2 = NSDate .timeIntervalSinceReferenceDate()
                let s = (source.texture?.width)!*(source.texture?.height)!*4*t
                print(" *** wil start process: \(source) tm = \(t2-t1) rate=\(Float(s)/Float(t2-t1)/1024/1024)Mb/s")
            }
            
            self.processingDidFinish = { (destination) in
                print(" *** did finish process: \(destination)")
                //self.analayzer.source = destination
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        imageView = IMPView(frame: scrollView.bounds)
        
        imageView.filter = IMPDesaturateFilter(context: IMPContext())
        
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

