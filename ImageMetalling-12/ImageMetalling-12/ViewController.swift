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
import ObjectMapper

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

public extension NSRect {
    mutating func setRegion(region:IMPRegion){
        let x = region.left.cgfloat*size.width
        let y = region.top.cgfloat*size.height
        self = NSRect(x: origin.x+x,
                      y: origin.y+y,
                      width: size.width*(1-region.right)-x,
                      height: size.height*(1-region.bottom)-y)
    }
}

class ViewController: NSViewController {

    let duration:NSTimeInterval = 0.2

    lazy var toolBar:IMPToolBar = {
        let t = IMPToolBar(frame: NSRect(x: 0,y: 0,width: 100,height: 20))
 
        t.enableFilterHandler = { (flag) in
            self.filter.enabled = flag
            self.grid.enabled = t.enabledGrid
        }
        
        t.enableAspectRatioHandler = { (flag) in
            self.aspectRatio(flag)
        }
        
        t.enableGridHandler = { (flag) in
            self.grid.enabled = flag
        }
        
        t.gridSizeHendler = { (step) in
            self.grid.adjustment.step = uint(step)
        }
        
        t.resetHandler = {
            self.reset()
        }
        
        return t
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

    lazy var grid:IMTLGridGenerator = {
        let g = IMTLGridGenerator(context: self.context)
        g.enabled = self.toolBar.enabledGrid
        g.adjustment.step  = 50
        g.adjustment.color = float4(1,1,1,0.5)
        g.adjustment.subDivisionColor = float4(0.75,0,0,0.9)
        return g
    }()
    
    lazy var imageSpots:IMTLGridGenerator = {
        let g = IMTLGridGenerator(context: self.context)
        g.enabled = self.grid.enabled
        g.adjustment.step  = 50
        g.adjustment.color = float4(0)
        g.adjustment.subDivisionColor = float4(0)
        g.adjustment.spotAreaColor = float4(1,1,1,0.3)
        g.adjustment.spotAreaType = .Solid
        return g
    }()

    lazy var filter:IMPFilter = {
        let f = IMPFilter(context: self.context)
        f.addFilter(self.imageSpots)
        f.addFilter(self.warp)
        f.addFilter(self.crop)
        f.addFilter(self.grid)
        return f
    }()
    
    lazy var imageView:IMPImageView = {
        let v = IMPImageView(context: self.context, frame: self.view.bounds)
        v.filter = self.filter
        v.backgroundColor = IMPColor(color: IMPPrefs.colors.background)
        
        v.addMouseEventObserver({ (event, location, view) in
            switch event.type {
            case .LeftMouseDown:
                self.localMouseDown(event, location:location, view:view)
            case .LeftMouseUp:
                self.localMouseUp(event, location:location, view:view)
            case .MouseMoved:
                self.localMouseMoved(event, location:location, view:view)
            case .MouseExited:
                if !self.touched {
                    self.spotArea(IMPRegion.null)
                }
            case .LeftMouseDragged:
                self.localMouseDragged(event, location:location, view:view)
            default:
                break
            }
        })

        return v
    }()
    
    func spotArea(region:IMPRegion)  {
        self.imageSpots.adjustment.spotArea = region
    }
    
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
                    self.currentImageFile = file

                    self.asyncChanges({ () -> Void in
                        self.zoomFit()
                        dispatch_after(1 * NSEC_PER_SEC, dispatch_get_main_queue(), {
                            self.restoreConfig()
                        })
                    })
                }
            }
        }
        
        imageView.dragOperation = { (files) in
            
            if files.count > 0 {
                
                let path = files[0]
                let url = NSURL(fileURLWithPath: path)
                if let suffix = url.pathExtension {
                    for ext in ["jpg", "jpeg"] {
                        if ext.lowercaseString == suffix.lowercaseString {
                            IMPDocument.sharedInstance.currentFile = path
                            return true
                        }
                    }
                }
            }
            return false
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
        
        view.addSubview(toolBar)
        
        toolBar.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view.snp_bottom).offset(1)
            make.left.equalTo(self.view.snp_left).offset(-1)
            make.right.equalTo(self.view.snp_right).offset(1)
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(600)
        }
        
        view.addSubview(imageView)
        imageView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view.snp_top).offset(10)
            make.bottom.equalTo(self.toolBar.snp_top).offset(0)
            make.left.equalTo(self.view).offset(10)
            make.right.equalTo(self.view.snp_right).offset(0)
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
    
    enum PointerPlace: Int {
        case LeftBottom
        case LeftTop
        case RightTop
        case RightBottom
        case Top
        case Bottom
        case Left
        case Right
        case Undefined
    }
    
    func convertPoint(point:NSPoint, fromFrame:NSRect, toFrame:NSRect) -> NSPoint {
        
        let transform = warp.destinationQuad.transformTo(destination: warp.sourceQuad)
        let size = float2(toFrame.size.width.float,toFrame.size.height.float)

        let x = (point.x/fromFrame.size.width - 0.5 ) * 2
        let y = (point.y/fromFrame.size.height - 0.5 ) * 2
        
        var p = ((transform * float4(x.float,y.float,0,1)).xy/2) + float2(0.5)
        p = p * size
        
        return NSPoint(x: p.x.cgfloat,y: p.y.cgfloat)
    }
    
    var pointerPlace:PointerPlace = .Undefined
    
    func getPointerPlace(point:NSPoint, view:NSView) ->  PointerPlace {
        
        var frame = view.frame
        
        frame.setRegion(warp.sourceQuad.croppedRegion(warp.destinationQuad))
        let w = frame.size.width.float
        let h = frame.size.height.float
        
        let point = convertPoint(point, fromFrame: view.frame, toFrame: frame)
        
        if point.x > w/3 && point.x < w*2/3 && point.y < h/3 {
            return .Bottom
        }
        else if point.x < w/3 && point.y >= h/3 && point.y <= h*2/3 {
            return .Left
        }
        else if point.x < w/3 && point.y < h/3 {
            return .LeftBottom
        }
        else if point.x < w/3 && point.y > h*2/3 {
            return .LeftTop
        }
            
        else if point.x > w/3 && point.x < w*2/3 && point.y > h*2/3 {
            return .Top
        }
        else if point.x > w*2/3 && point.y >= h/3 && point.y <= h*2/3 {
            return .Right
        }
        else if point.x > w*2/3 && point.y < h/3 {
            return .RightBottom
        }
        else if point.x > w*2/3 && point.y > h*2/3 {
            return .RightTop
        }
        
        return .Undefined
    }
    
    func localMouseMoved(theEvent: NSEvent, location:NSPoint, view:NSView) {
        
        if touched {return}

        let point = location
        
        var spotArea = IMPRegion.null
        
        switch getPointerPlace(point,view:view) {
            
        case .LeftBottom:
            spotArea = IMPRegion(left: 0, right: 2/3, top: 0, bottom: 2/3)
        case .Left:
            spotArea = IMPRegion(left: 0, right: 2/3, top: 1/3, bottom: 1/3)
        case .LeftTop:
            spotArea = IMPRegion(left: 0, right: 2/3, top: 2/3, bottom: 0)
            
        case .Top:
            spotArea = IMPRegion(left: 1/3, right: 1/3, top: 2/3, bottom: 0)
        case .RightTop:
            spotArea = IMPRegion(left: 2/3, right: 0, top: 2/3, bottom: 0)
        case .Right:
            spotArea = IMPRegion(left: 2/3, right: 0, top: 1/3, bottom: 1/3)
   
        case .RightBottom:
            spotArea = IMPRegion(left: 2/3, right: 0, top: 0, bottom: 2/3)
        case .Bottom:
            spotArea = IMPRegion(left: 1/3, right: 1/3, top: 0, bottom: 2/3)

        default:
            spotArea = IMPRegion.null
            break
        }
        
        self.spotArea(spotArea)
    }

    func localMouseDown(theEvent: NSEvent, location:NSPoint, view:NSView) {
        
        mouse_point = location
        mouse_point_before = mouse_point
        mouse_point_offset = NSPoint(x: 0,y: 0)
        touched = true
        
        pointerPlace = getPointerPlace(mouse_point, view: view)
        deltaStrechedQuad = warp.destinationQuad
    }
    
    func localMouseUp(theEvent: NSEvent, location:NSPoint, view:NSView) {
        
        touched = false
        deltaStrechedQuad = warp.destinationQuad-deltaStrechedQuad
        
        self.spotArea(IMPRegion.null)
        
        if toolBar.enabledAspectRatio {
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
                }, complete: { (flag) in
                    self.updateConfig()
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
                }, complete: { (flag) in
                    self.updateConfig()
            })
        }
    }
    
    func pointerMoved(theEvent: NSEvent, location:NSPoint, view:NSView)  {
        if !touched {
            return
        }
        
        mouse_point = location
        
        let w = view.frame.size.width.float
        let h = view.frame.size.height.float
        
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
        updateConfig()
    }
    
    func localMouseDragged(theEvent: NSEvent, location:NSPoint, view:NSView) {
        pointerMoved(theEvent, location:location, view:view)
        localMouseMoved(theEvent, location:location, view:view)
    }
    
    
    func enableFilter(sender:NSButton){
        if sender.state == 1 {
            filter.enabled = true
        }
        else {
            filter.enabled = false
        }
    }
    

    var lastCropRegion = IMPRegion()
    var lastStrechedQuad = IMPQuad()
    lazy var deltaStrechedQuad:IMPQuad = IMPQuad.null
    
    func aspectRatio(flag:Bool){
        if flag {
            
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
                }, complete: { (flag) in
                    self.updateConfig()
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
                }, complete: { (flag) in
                    self.updateConfig()
            })
        }

    }
       
    func reset(){
        
        
        lastCropRegion    = IMPRegion()
        lastStrechedQuad  = IMPQuad()
        deltaStrechedQuad = IMPQuad.null

        let startDestination =  warp.destinationQuad
        let finalWarp =  IMPQuad()
        
        let startCrop = crop.region
        let finalCrop = IMPRegion()
        
        let startSlider = Float(toolBar.gridSize)
        
        IMPDisplayTimer.cancelAll()
        IMPDisplayTimer.execute(duration: duration, options: .EaseInOut, update: { (atTime) in
            
            self.warp.destinationQuad = startDestination.lerp(final: finalWarp, t: atTime.float)
            self.crop.region = startCrop.lerp(final: finalCrop, t: atTime.float)
            self.toolBar.gridSize = Int(startSlider.lerp(final: 50, t: atTime.float))
            
            }, complete: { (flag) in
                self.toolBar.gridSize = 50
                self.updateConfig()
                self.saveConfig()
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

    override func viewWillDisappear() {
        saveConfig()
    }
    
    var currentImageFile:String? = nil {
        willSet {
            self.saveConfig()
        }
    }
    
    var configKey:String? {
        if let file = self.currentImageFile {
            return "IMTL-CONFIG-" + file
        }
        return nil
    }
    
    func restoreConfig() {
        
        if let key = self.configKey {
            let json =  NSUserDefaults.standardUserDefaults().valueForKey(key) as? String
            if let m = Mapper<IMTLConfig>().map(json) {
                config = m
            }
        }
        else{
            config = IMTLConfig()
        }
        
        let startCrop = crop.region
        let startQuad = warp.destinationQuad
        
        IMPDisplayTimer.cancelAll()
        IMPDisplayTimer.execute(duration: duration, options: .EaseOut, update: { (atTime) in
            self.warp.destinationQuad = startQuad.lerp(final: self.config.quad, t: atTime.float)
            self.crop.region = startCrop.lerp(final: self.config.crop, t: atTime.float)
            
        })
    }
    
    func updateConfig() {
        config.quad = warp.destinationQuad
        config.crop = crop.region
    }
    
    func saveConfig(){
        if let key = self.configKey {
            let json =  Mapper().toJSONString(config, prettyPrint: true)            
            NSUserDefaults.standardUserDefaults().setValue(json, forKey: key)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    lazy var config = IMTLConfig()
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

public class IMTLConfig:Mappable {
    
    var quad = IMPQuad()
    var crop = IMPRegion()
    
    public init(){}
    
    required public init?(_ map: Map) {
    }
    
    public func mapping(map: Map) {
        quad <- (map["quad"],transformQuad)
        crop <- (map["crop"],transformRegion)
    }
    
    
    let transformQuad = TransformOf<IMPQuad, [String:[Float]]>(fromJSON: { (value: [String:[Float]]?) -> IMPQuad? in
        
        if let value = value {
            let left_bottom  = value["left_bottom"]!
            let left_top     = value["left_top"]!
            let right_bottom = value["right_bottom"]!
            let right_top    = value["right_top"]!
            let object = IMPQuad(
                left_bottom:  float2(left_bottom[0],left_bottom[1]),
                left_top:     float2(left_top[0],left_top[1]),
                right_bottom: float2(right_bottom[0],right_bottom[1]),
                right_top:    float2(right_top[0],right_top[1]))
            return object
        }
        return nil
        }, toJSON: { (value: IMPQuad?) -> [String:[Float]]? in
            if let quad = value {
                let json = [
                    "left_bottom":  [quad.left_bottom.x, quad.left_bottom.y],
                    "left_top":     [quad.left_top.x,    quad.left_top.y],
                    "right_bottom": [quad.right_bottom.x,quad.right_bottom.y],
                    "right_top":    [quad.right_top.x,   quad.right_top.y],
                ]
                return json
            }
            return nil
    })
    
    let transformRegion = TransformOf<IMPRegion, [String:Float]>(fromJSON: { (value: [String:Float]?) -> IMPRegion? in
        
        if let value = value {
            return IMPRegion(
                left:   value["left"]!,
                right:  value["right"]!,
                top:    value["top"]!,
                bottom: value["bottom"]!)
        }
        return nil
        }, toJSON: { (value: IMPRegion?) -> [String:Float]? in
            if let region = value {
                let json = [
                    "left":  region.left,
                    "right": region.right,
                    "top":   region.top,
                    "bottom":  region.bottom,
                ]
                return json
            }
            return nil
    })

}



