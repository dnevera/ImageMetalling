//
//  ViewController.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 14.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

class IMPClipView:NSClipView {
    
    private var viewPoint = NSPoint()
    
    override func constrainBoundsRect(proposedBounds: NSRect) -> NSRect {
        if let documentView = self.documentView{
            
            let documentFrame:NSRect = documentView.frame
            var clipFrame     = self.bounds
            
            let x = documentFrame.size.width - clipFrame.size.width
            let y = documentFrame.size.height - clipFrame.size.height
            
            clipFrame.origin = proposedBounds.origin
            
            if clipFrame.size.width>documentFrame.size.width{
                clipFrame.origin.x = CGFloat(roundf(Float(x) / 2.0))
            }
            else{
                let m = Float(max(0, min(clipFrame.origin.x, x)))
                clipFrame.origin.x = CGFloat(roundf(m))
            }
            
            if clipFrame.size.height>documentFrame.size.height{
                clipFrame.origin.y = CGFloat(roundf(Float(y) / 2.0))
            }
            else{
                let m = Float(max(0, min(clipFrame.origin.y, y)))
                clipFrame.origin.y = CGFloat(roundf(m))
            }
            
            viewPoint.x = NSMidX(clipFrame) / documentFrame.size.width;
            viewPoint.y = NSMidY(clipFrame) / documentFrame.size.height;
            
            return clipFrame
            
        }
        else{
            return super.constrainBoundsRect(proposedBounds)
        }
    }
    
    func moveToCenter(){
        if let documentView = self.documentView{
            
            let documentFrame:NSRect = documentView.frame
            var clipFrame     = self.bounds
            
            if (documentFrame.size.width < clipFrame.size.width) {
                clipFrame.origin.x = CGFloat(roundf(Float(documentFrame.size.width - clipFrame.size.width) / 2.0));
            } else {
                clipFrame.origin.x = CGFloat(roundf(Float(viewPoint.x * documentFrame.size.width - (clipFrame.size.width) / 2.0)));
            }
            
            if (documentFrame.size.height < clipFrame.size.height) {
                clipFrame.origin.y = CGFloat(roundf(Float(documentFrame.size.height - clipFrame.size.height) / 2.0));
            } else {
                clipFrame.origin.y = CGFloat(roundf(Float(viewPoint.x * documentFrame.size.height - (clipFrame.size.height) / 2.0)));
            }
            
            let scrollView = self.superview
            
            self.scrollToPoint(self.constrainBoundsRect(clipFrame).origin)
            scrollView?.reflectScrolledClipView(self)
        }
    }
    
    override func viewBoundsChanged(notification: NSNotification) {
        super.viewBoundsChanged(notification)
    }
    
    override func viewFrameChanged(notification: NSNotification) {
        super.viewBoundsChanged(notification)
        self.moveToCenter()
    }
    
    override var documentView:AnyObject?{
        didSet{
            self.moveToCenter()
        }
    }
}

class IMPScrollView:NSScrollView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.contentView = IMPClipView(frame: self.bounds)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.contentView = IMPClipView(frame: self.bounds)
    }
    
    
}

class ViewController: NSViewController {
    
    
    @IBOutlet weak var imageView: IMPView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        imageView = IMPView(frame: scrollView.bounds)
        
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

