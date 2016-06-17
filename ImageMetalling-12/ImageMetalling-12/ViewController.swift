//
//  ViewController.swift
//  ImageMetalling-12
//
//  Created by denis svinarchuk on 12.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//
//
//  http://dolboeb.livejournal.com/2957593.html
//
//

import Cocoa
import IMProcessing
import SnapKit
import ImageIO
import MediaLibrary

public extension IMPQuad {
    
    public func differenceRegion(quad:IMPQuad) -> IMPRegion {
        let difference = self-quad
        
        let left        = min(difference.left_bottom.x,difference.left_top.x)
        let right       = max(difference.right_top.x,difference.right_bottom.x)
        
        let top         = max(difference.left_top.y,difference.right_top.y)
        let bottom      = min(difference.left_bottom.y,difference.right_bottom.y)
        
        return IMPRegion(left: left, right: right, top: top, bottom: bottom)
    }
    
    func fit2source(diff:IMPRegion) -> IMPRegion {
        var diff = diff
        diff.left = diff.left > 0 ? 0 : diff.left
        diff.right = diff.right < 0 ? 0 : diff.right
        diff.top = diff.top < 0 ? 0 : diff.top
        diff.bottom = diff.bottom > 0 ? 0 : diff.bottom
        return diff
    }
    
    public func croppedRegion(quad:IMPQuad) -> IMPRegion {
        let diff = fit2source(differenceRegion(quad))
        return IMPRegion(left: abs(diff.left)/2, right: abs(diff.right)/2, top: abs(diff.top)/2, bottom: abs(diff.bottom)/2)
    }
    
    public func strechedQuad(quad:IMPQuad) -> IMPQuad {
        
        let diff = fit2source(differenceRegion(quad))
        
        var stretchedQuad = quad
        
        stretchedQuad.left_bottom.x += diff.left
        stretchedQuad.left_top.x    += diff.left
        
        stretchedQuad.right_bottom.x += diff.right
        stretchedQuad.right_top.x    += diff.right
        
        stretchedQuad.left_top.y   += diff.top
        stretchedQuad.right_top.y  += diff.top
        
        stretchedQuad.right_bottom.y += diff.bottom
        stretchedQuad.left_bottom.y  += diff.bottom
        
        return stretchedQuad
    }
}


class ViewController: NSViewController {

    let duration:NSTimeInterval = 0.2
    
    lazy var sview:NSView = {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = IMPColor.clearColor().CGColor
        return v
    }()
    
    lazy var pannelScrollView:NSScrollView = {
        
        let v = NSScrollView()
        
        v.wantsLayer = true
        v.drawsBackground = false
        v.allowsMagnification = false
        v.contentView.wantsLayer = true
        v.documentView = self.sview
        
        self.sview.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(v).inset(NSEdgeInsetsMake(0, 0, 0, 0))
        }

        return v
    }()

    var context = IMPContext()
    
    lazy var warp:IMPWarpFilter = {
        let w = IMPWarpFilter(context: self.context)
        w.backgroundColor = IMPColor(color: IMPPrefs.colors.background)
        return w
    }()

    lazy var crop:IMPVignetteFilter = {
        let f = IMPVignetteFilter(context:self.context, type:.Frame)
        f.adjustment.blending.opacity = 0.8
        f.adjustment.start = 0
        f.adjustment.end = 0
        f.adjustment.color = IMPPrefs.colors.background.rgb
        return f
    }()

    lazy var grid:IMPGridGenerator = {
        let g = IMPGridGenerator(context: self.context)
        g.enabled = false
        g.adjustment.step  = 50
        g.adjustment.color = float4(1,1,1,0.5)
        g.adjustment.subDivisionColor = float4(1,0,0,0.9)
        return g
    }()
 
    lazy var imageGrid:IMPGridGenerator = {
        let g = IMPGridGenerator(context: self.context)
        g.enabled = self.grid.enabled
        g.adjustment.color = float4(0)
        g.adjustment.subDivisionColor = float4(0,0,0,1)
        return g
    }()

    lazy var filter:IMPFilter = {
        let f = IMPFilter(context: self.context)
        f.addFilter(self.imageGrid)
        f.addFilter(self.warp)
        f.addFilter(self.grid)
        f.addFilter(self.crop)
        return f
    }()
    
    lazy var imageView:IMPImageView = {
        let v = IMPImageView(context: self.context, frame: self.view.bounds)
        v.filter = self.filter
        v.backgroundColor = IMPColor(color: IMPPrefs.colors.background)
        return v
    }()
    
    let autoWarpButton = NSButton()
    var gridSlider:IMPSlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !IMPContext.supportsSystemDevice {
            
            self.asyncChanges({ () -> Void in
                let alert = NSAlert(error: NSError(domain: "com.imagemetalling.08", code: 0, userInfo: [
                    NSLocalizedFailureReasonErrorKey:"MTL initialization error",
                    NSLocalizedDescriptionKey:"The system does not support MTL..."
                    ]))
                alert.runModal()
            })
            return
        }
        
        
        func loadImage(file:String, size:Float) -> IMPImageProvider? {
            var image:IMPImageProvider? = nil
            do{
                //
                // Загружаем файл и связываем источником фильтра
                //
                let meta = IMPJpegProvider.metadata(file)
                
                var orientation = IMPExifOrientationUp
                if let o = meta?[IMProcessing.meta.imageOrientationKey] as? NSNumber {
                    orientation = IMPExifOrientation(rawValue: o as Int)
                }
                
                image = try IMPJpegProvider(context: self.context, file: file, maxSize: size, orientation: orientation)
                
            }
            catch let error as NSError {
                self.asyncChanges({ () -> Void in
                    let alert = NSAlert(error: error)
                    alert.runModal()
                })
            }
            
            return image
        }
        
        IMPDocument.sharedInstance.addDocumentObserver { (file, type) -> Void in
            if type == .Image {
                if let image = loadImage(file, size: 1200) {
                    
                    self.imageView.filter?.source = image
                    self.warp.destinationQuad = IMPQuad()
                    self.crop.region = IMPRegion()
                    
                    self.asyncChanges({ () -> Void in
                        self.zoomFit()
                    })
                }
            }
        }
        
        IMPDocument.sharedInstance.addSavingObserver { (file, type) in
            if type == .Image {
                if let image = loadImage(IMPDocument.sharedInstance.currentFile!, size: 0) {
                    
                    NSLog("save \(file)")
                    let filter = IMPFilter(context: IMPContext())
                    let warp   = IMPWarpFilter(context: filter.context)
                    let crop   = IMPCropFilter(context: filter.context)
                    filter.addFilter(warp)
                    filter.addFilter(crop)
                    warp.sourceQuad = self.warp.sourceQuad
                    warp.destinationQuad = self.warp.destinationQuad
                    crop.region = self.crop.region
                    
                    filter.source = image
                    
                    do {
                        try filter.destination?.writeToJpeg(file, compression: 1)
                    }
                    catch let error as NSError {
                        self.asyncChanges({ () -> Void in
                            let alert = NSAlert(error: error)
                            alert.runModal()
                        })
                    }
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
                default:
                    break
                }
            }
        }
        
        view.addSubview(pannelScrollView)
        pannelScrollView.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(280)
            make.top.equalTo(self.view).offset(0)
            make.bottom.equalTo(self.view).offset(0)
            make.right.equalTo(self.view).offset(0)
        }
        
        view.addSubview(imageView)
        imageView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(10)
            make.bottom.equalTo(self.view).offset(-10)
            make.left.equalTo(self.view).offset(10)
            make.right.equalTo(self.pannelScrollView.snp_left).offset(0)
        }

        
        let enableFilterLabel = IMPLabel(frame: NSRect())
        enableFilterLabel.stringValue = "Enable Filter"
        sview.addSubview(enableFilterLabel)

        enableFilterLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view).offset(20)
            make.height.equalTo(40)
            make.width.equalTo(120)
            make.left.equalTo(sview).offset(20)
        }
        
        
        let enableFilterButton = NSButton()
        enableFilterButton.title = ""
        enableFilterButton.setButtonType(.SwitchButton)
        enableFilterButton.state = 1
        
        enableFilterButton.target = self
        enableFilterButton.action = #selector(ViewController.enableFilter(_:))
        sview.addSubview(enableFilterButton)
        
        enableFilterButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view).offset(20)
            make.width.equalTo(40)
            make.left.equalTo(enableFilterLabel.snp_right).offset(20)
        }
        
        let autoWarpLabel = IMPLabel(frame: NSRect())
        autoWarpLabel.stringValue = "Keep aspect ratio"
        sview.addSubview(autoWarpLabel)

        autoWarpLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(enableFilterButton).offset(20)
            make.height.equalTo(40)
            make.width.equalTo(120)
            make.left.equalTo(sview).offset(20)
        }
        
        autoWarpButton.setButtonType(.SwitchButton)
        autoWarpButton.title = ""
        autoWarpButton.state = 0
        
        autoWarpButton.target = self
        autoWarpButton.action = #selector(ViewController.autoWarp(_:))
        sview.addSubview(autoWarpButton)
        
        autoWarpButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(enableFilterButton).offset(20)
            make.width.equalTo(40)
            make.left.equalTo(autoWarpLabel.snp_right).offset(20)
        }
        
        
        let gridLabel = IMPLabel(frame: NSRect())
        gridLabel.stringValue = "Grid On"
        sview.addSubview(gridLabel)
        
        gridLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(autoWarpButton).offset(20)
            make.height.equalTo(40)
            make.width.equalTo(120)
            make.left.equalTo(sview).offset(20)
        }
        
        let gridButton = NSButton()
        gridButton.setButtonType(.SwitchButton)
        gridButton.title = ""
        gridButton.state = Int(grid.enabled)
        
        gridButton.target = self
        gridButton.action = #selector(ViewController.gridOn(_:))
        sview.addSubview(gridButton)
        
        gridButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(gridLabel).offset(20)
            make.width.equalTo(40)
            make.left.equalTo(gridLabel.snp_right).offset(20)
        }
        
        gridSlider = IMPSlider(
            title: "Grid size",
            range: 0..<100, initial: 50)
        { (value) -> Void in
            let v = uint((value) * 100)
            self.grid.adjustment.step = v
        }
        
        gridSlider.slider.enabled = grid.enabled
        
        sview.addSubview(gridSlider)
        gridSlider.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(gridButton.snp_bottom).offset(20)
            make.left.equalTo(sview).offset(10)
            make.right.equalTo(sview).offset(-10)
            make.height.equalTo(40)
        }
        

        let resetButton = NSButton()
        resetButton.title = "Reset"
        
        resetButton.target = self
        resetButton.action = #selector(ViewController.reset(_:))
        sview.addSubview(resetButton)
        
        resetButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(gridSlider.snp_bottom).offset(20)
            make.width.equalTo(120)
            make.left.equalTo(sview).offset(20)
        }
        
    }

    var mouse_point_offset = NSPoint()
    var mouse_point_before = NSPoint()
    var mouse_point = NSPoint() {
        didSet{
            mouse_point_before = oldValue
            mouse_point_offset = mouse_point_before - mouse_point
        }
    }
    
    var touched = false
    var warpDelta:Float = 0.005
    
    enum PointerPlace {
        case LeftBottom
        case LeftTop
        case RightBottom
        case RightTop
        case Top
        case Bottom
        case Left
        case Right
        case Undefined
    }
    
    var pointerPlace:PointerPlace = .Undefined
    
    func getPointerPlace(point:NSPoint) ->  PointerPlace {
        
        let w = self.imageView.frame.size.width.float
        let h = self.imageView.frame.size.height.float
        
        if point.x > w/3 && point.x < w*2/3 && point.y < h/2 {
            return .Bottom
        }
        else if point.x < w/2 && point.y >= h/3 && point.y <= h*2/3 {
            return .Left
        }
        else if point.x < w/3 && point.y < h/3 {
            return .LeftBottom
        }
        else if point.x < w/3 && point.y > h*2/3 {
            return .LeftTop
        }
            
        else if point.x > w/3 && point.x < w*2/3 && point.y > h/2 {
            return .Top
        }
        else if point.x > w/2 && point.y >= h/3 && point.y <= h*2/3 {
            return .Right
        }
        else if point.x > w/3 && point.y < h/3 {
            return .RightBottom
        }
        else if point.x > w/3 && point.y > h*2/3 {
            return .RightTop
        }
        
        return .Undefined
    }
    
    override func mouseDown(theEvent: NSEvent) {
        let event_location = theEvent.locationInWindow
        mouse_point = self.imageView.convertPoint(event_location,fromView:nil)
        mouse_point_before = mouse_point
        mouse_point_offset = NSPoint(x: 0,y: 0)
        touched = true
        
        pointerPlace = getPointerPlace(mouse_point)
        deltaStrechedQuad = warp.destinationQuad
    }
    
    override func mouseUp(theEvent: NSEvent) {
        
        touched = false
        deltaStrechedQuad = warp.destinationQuad-deltaStrechedQuad

        if autoWarpButton.state == 1{
            stretchWarp()
        }
        else{
            cropWarp()
        }
    }
    
    func stretchWarp(){
        if !touched {
            let start =  warp.destinationQuad
            let final = warp.sourceQuad.strechedQuad(warp.destinationQuad)
            
            IMPDisplayTimer.cancelAll()
            IMPDisplayTimer.execute(duration: duration, options: .EaseInOut, update: { (atTime) in
                self.warp.destinationQuad = start.lerp(final: final, t: atTime.float)
            })
        }
    }
    
    func cropWarp() {
        if !touched {
            let start  = crop.region
            let final = warp.sourceQuad.croppedRegion(warp.destinationQuad)
            
            IMPDisplayTimer.cancelAll()
            IMPDisplayTimer.execute(duration: duration, options: .EaseInOut, update: { (atTime) in
                self.crop.region = start.lerp(final: final, t: atTime.float)
            })
        }
    }
    
    func pointerMoved(theEvent: NSEvent)  {
        if !touched {
            return
        }
        
        let event_location = theEvent.locationInWindow
        mouse_point = self.imageView.convertPoint(event_location,fromView:nil)
        
        let w = self.imageView.frame.size.width.float
        let h = self.imageView.frame.size.height.float
        
        let distancex = 1/w * mouse_point_offset.x.float
        let distancey = 1/h * mouse_point_offset.y.float

        var destinationQuad = warp.destinationQuad
        
        if pointerPlace == .Left {
            destinationQuad.left_bottom.x = destinationQuad.left_bottom.x - distancex
            destinationQuad.left_top.x = destinationQuad.left_top.x - distancex
        }
        else if pointerPlace == .Bottom {
            destinationQuad.left_bottom.y = destinationQuad.left_bottom.y - distancey
            destinationQuad.right_bottom.y = destinationQuad.right_bottom.y - distancey
        }
        else if pointerPlace == .LeftBottom {
            destinationQuad.left_bottom.x = destinationQuad.left_bottom.x - distancex
            destinationQuad.left_bottom.y = destinationQuad.left_bottom.y - distancey
        }
        else if pointerPlace == .LeftTop {
            destinationQuad.left_top.x = destinationQuad.left_top.x - distancex
            destinationQuad.left_top.y = destinationQuad.left_top.y - distancey
        }
            
        else if pointerPlace == .Right {
            destinationQuad.right_bottom.x = destinationQuad.right_bottom.x - distancex
            destinationQuad.right_top.x = destinationQuad.right_top.x - distancex
        }
        else if pointerPlace == .Top {
            destinationQuad.left_top.y = destinationQuad.left_top.y - distancey
            destinationQuad.right_top.y = destinationQuad.right_top.y - distancey
        }
        else if pointerPlace == .RightBottom {
            destinationQuad.right_bottom.x = destinationQuad.right_bottom.x - distancex
            destinationQuad.right_bottom.y = destinationQuad.right_bottom.y - distancey
        }
        else if pointerPlace == .RightTop {
            destinationQuad.right_top.x = destinationQuad.right_top.x - distancex
            destinationQuad.right_top.y = destinationQuad.right_top.y - distancey
        }
                
        warp.destinationQuad = destinationQuad
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        pointerMoved(theEvent)
    }
    
    override func touchesMovedWithEvent(theEvent: NSEvent) {
        pointerMoved(theEvent)
    }

    
    func enableFilter(sender:NSButton){
        if sender.state == 1 {
            filter.enabled = true
        }
        else {
            filter.enabled = false
        }
    }
    
    func gridOn(sender:NSButton){
        if sender.state == 1 {
            imageGrid.enabled = true
            grid.enabled = true
            gridSlider.slider.enabled = true
        }
        else {
            gridSlider.slider.enabled = false
            imageGrid.enabled = false
            grid.enabled = false
        }
    }
    

    var lastCropRegion = IMPRegion()
    var lastStrechedQuad = IMPQuad()
    lazy var deltaStrechedQuad:IMPQuad = IMPQuad.null
    
    func autoWarp(sender:NSButton){
        if sender.state == 1 {
            
            lastCropRegion = crop.region
            lastStrechedQuad = warp.destinationQuad
            deltaStrechedQuad = IMPQuad.null

            let startCrop = crop.region
            let finalCrop = IMPRegion()
            let startQuad = warp.destinationQuad
            let finalQuad = warp.sourceQuad.strechedQuad(warp.destinationQuad)
            
            IMPDisplayTimer.cancelAll()
            IMPDisplayTimer.execute(duration: duration, options: .EaseInOut, update: { (atTime) in
                self.warp.destinationQuad = startQuad.lerp(final: finalQuad, t: atTime.float)
                self.crop.region = startCrop.lerp(final: finalCrop, t: atTime.float)
            })
        }
        else {

            lastStrechedQuad = lastStrechedQuad+deltaStrechedQuad
            deltaStrechedQuad = IMPQuad.null

            let startQuad     = warp.destinationQuad
            let startCrop     = self.crop.region
            let finalCrop     = warp.sourceQuad.croppedRegion(lastStrechedQuad)
            
            IMPDisplayTimer.cancelAll()
            IMPDisplayTimer.execute(duration: duration, options: .EaseInOut, update: { (atTime) in
                self.warp.destinationQuad = startQuad.lerp(final: self.lastStrechedQuad, t: atTime.float)
                self.crop.region = startCrop.lerp(final: finalCrop, t: atTime.float)
            })
        }
    }
    
    func reset(sender:NSButton){
        
        
        lastCropRegion    = IMPRegion()
        lastStrechedQuad  = IMPQuad()
        deltaStrechedQuad = IMPQuad.null

        let startDestination =  warp.destinationQuad
        let finalWarp =  IMPQuad()
        
        let startCrop = crop.region
        let finalCrop = IMPRegion()
        
        let startSlider = gridSlider.value
        
        IMPDisplayTimer.cancelAll()
        IMPDisplayTimer.execute(duration: duration, options: .EaseInOut, update: { (atTime) in
            self.warp.destinationQuad = startDestination.lerp(final: finalWarp, t: atTime.float)
            self.crop.region = startCrop.lerp(final: finalCrop, t: atTime.float)
            self.gridSlider.value = startSlider.lerp(final: 0.5, t: atTime.float)
            }, complete: { (flag) in
                self.gridSlider.value = 0.5
        })
    }
    
    
    func zoomFit(){
        asyncChanges { () -> Void in
            self.imageView.sizeFit()
        }
    }
    
    func zoom100(){
        asyncChanges { () -> Void in
            self.imageView.sizeOriginal()
        }
    }
    

    var q = dispatch_queue_create("ViewController", DISPATCH_QUEUE_CONCURRENT)

    private func asyncChanges(block:()->Void) {
        dispatch_async(q, { () -> Void in
            dispatch_after(0, dispatch_get_main_queue()) { () -> Void in
                block()
            }
        })
    }

}

public func == (left:NSPoint, right:NSPoint) -> Bool{
    return left.x==right.x && left.y==right.y
}

public func != (left:NSPoint, right:NSPoint) -> Bool{
    return !(left==right)
}

public func - (left:NSPoint, right:NSPoint) -> NSPoint {
    return NSPoint(x: left.x-right.x, y: left.y-right.y)
}

public func + (left:NSPoint, right:NSPoint) -> NSPoint {
    return NSPoint(x: left.x+right.x, y: left.y+right.y)
}


extension IMPJpegProvider {
    
    static func metadata(file:String) -> [String: AnyObject]?  {
        let url = NSURL(fileURLWithPath: file)
        
        guard let imageSrc = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            NSLog ("Error: file name : %@", file);
            return nil
        }
        
        let  meta = CGImageSourceCopyPropertiesAtIndex ( imageSrc, 0, nil ) as NSDictionary?
        
        guard let metadata = meta as? [String: AnyObject] else {
            NSLog ("Error: read meta : %@", file);
            return nil
        }
        
        return metadata
    }
}

