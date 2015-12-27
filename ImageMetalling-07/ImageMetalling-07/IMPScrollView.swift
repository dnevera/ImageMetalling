//
//  IMPScrollView.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

class IMPScrollView:NSScrollView {
    
    private var cv:IMPClipView!
    
    private func configure(){
        cv = IMPClipView(frame: self.bounds)
        self.contentView = cv
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configure()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.configure()
    }
    
    override func magnifyToFitRect(rect: NSRect) {
        super.magnifyToFitRect(rect)
        self.cv.moveToCenter(true)
    }
}

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
    
    func moveToCenter(always:Bool = false){
        if let documentView = self.documentView{
            
            let documentFrame:NSRect = documentView.frame
            var clipFrame     = self.bounds
            
            if documentFrame.size.width < clipFrame.size.width || always {
                clipFrame.origin.x = CGFloat(roundf(Float(documentFrame.size.width - clipFrame.size.width) / 2.0));
            } else {
                clipFrame.origin.x = CGFloat(roundf(Float(viewPoint.x * documentFrame.size.width - (clipFrame.size.width) / 2.0)));
            }
            
            if documentFrame.size.height < clipFrame.size.height || always {
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
