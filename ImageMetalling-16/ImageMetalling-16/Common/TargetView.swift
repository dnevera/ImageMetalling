//
//  TargetView.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 12.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Cocoa
import IMProcessing
import IMProcessingUI

/// Image preview window
open class TargetView: IMPViewBase{
    
    public lazy var processingView:IMProcessingView = { 
        let v = IMProcessingView(frame:NSRect(x: 0, y:0, width: 200, height: 200))
        v.placeHolderColor = NSColor.white
        return v
    }()    
    
    open func configure(){}
    
    ///  Magnify image to fit rectangle
    ///
    ///  - parameter rect: rectangle which is used to magnify the image to fit size an position
    public func magnifyToFitRect(rect:CGRect){
        isSizeFit = false
        _scrollView.magnify(toFit: rect)
    }
    
    private var isSizeFit = true
    
    ///  Fite image to current view size
    public func sizeFit(){
        isSizeFit = true
        if let rect = _scrollView.documentView?.bounds {
            _scrollView.magnify(toFit: rect)
        }
    }
    
    public func imageMove(_ distance:NSPoint) {
        if let rect = _scrollView.documentView?.visibleRect {
            var point = rect.origin
            point = NSPoint(x: point.x + distance.x, y: point.y + distance.y) 
            _scrollView.documentView?.scroll(point)
        }
    }
    
    ///  Present image in oroginal size
    public func sizeOriginal(at point:NSPoint? = nil){
        isSizeFit = false            
        let size = _scrollView.visibleRect.size
        guard let origSize = processingView.image?.size else { return } //_imageView.drawableSize
        var scale = max(origSize.width/size.width, origSize.height/size.height)
        scale = scale < 1 ? 1 : scale
        _scrollView.magnify(at: point, scale: scale)
    }
    
    ///  Scale image 
    public func scale(_ scale: CGFloat, at point:NSPoint? = nil){
        isSizeFit = false            
        _scrollView.magnify(at: point, scale: scale)
    }
    
    @objc func magnifyChanged(event:NSNotification){
        isSizeFit = false
    }
    
    public var scrollView:IMPScrollView {
        return _scrollView
    }
    
    public init(){
        super.init(frame: NSRect())
        defer{
            self._configure()
        }
    }
    
    ///  Create image view object with th context within properly frame
    ///
    ///  - parameter frame:     view frame rectangle
    ///
    public override init(frame: NSRect){
        super.init(frame: frame)
        defer{
            self._configure()
        }
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        defer{
            self._configure()
        }
    }
    
    override open func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        if isSizeFit {
            sizeFit()
        }
    }    
    
    public var imageArea:NSRect {
        guard var frame = _scrollView.documentView?.frame else { return NSZeroRect }
        frame.origin.x += _scrollView.contentInsets.left
        frame.origin.y += _scrollView.contentInsets.top
        frame.size.width -= _scrollView.contentInsets.right
        frame.size.height -= _scrollView.contentInsets.bottom
        return frame
    }
    
    private var _scrollView:IMPScrollView!
    
    private func _configure(){
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(magnifyChanged(event:)),
            name: NSScrollView.willStartLiveMagnifyNotification,
            object: nil)
        
        _scrollView = IMPScrollView(frame: bounds)
        
        _scrollView.drawsBackground = false
        _scrollView.wantsLayer = true
        _scrollView.layer?.backgroundColor = NSColor.clear.cgColor
        
        _scrollView.allowsMagnification = true
        _scrollView.hasVerticalScroller = true
        _scrollView.hasHorizontalScroller = true        
        _scrollView.autoresizingMask = [.height, .width]                
        _scrollView.documentView = processingView
        
        addSubview(_scrollView)
        
        configure()
    }                 
}


extension NSView {
    
    public func fitViewSize(size:NSSize?, to viewSize:NSSize, moveCenter:Bool){
        
        guard let imageSize = size else { return }         
        
        if (imageSize.height > 0.0 && viewSize.height > 0.0) {
            
            let imageAspect = imageSize.width / imageSize.height
            let viewAspect = viewSize.width / viewSize.height
            
            if (imageAspect > viewAspect) {
                
                let height = viewSize.width / imageAspect
                
                self.frame = NSMakeRect(0,
                                        moveCenter ? 0.5 * (viewSize.height - height) : 0, 
                                        viewSize.width,
                                        height)
                
            } else if (imageAspect < viewAspect) {
                
                let width = viewSize.height * imageAspect
                
                self.frame = NSMakeRect(moveCenter ? 0.5 * (viewSize.width - width) : 0, 
                                        0, 
                                        width, 
                                        viewSize.height)
            }            
        }            
    }
}
