//
//  ViewController.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 14.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    
    @IBOutlet weak var imageView: IMPView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    class IMPDesaturateFilter:IMPFilter {
        required init(context: IMPContext) {
            super.init(context: context)
            let kernel = IMPFunction(context: self.context, name: "kernel_desaturate")
            self.addFunction(kernel)
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

