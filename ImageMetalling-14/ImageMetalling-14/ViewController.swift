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


class ViewController: NSViewController {
    
    var context = IMPContext()
    
    lazy var contrast:IMTLAutoContrastFilter = {
        let c = IMTLAutoContrastFilter(context: self.context)
        c.addDestinationObserver(destination: { (destination) in
            
            if c.autoContrastEnabled {
                self.curvesView["Red"]?.controlPoints = c.curvesFilter.splines.redControls
                self.curvesView["Green"]?.controlPoints = c.curvesFilter.splines.greenControls
                self.curvesView["Blue"]?.controlPoints = c.curvesFilter.splines.blueControls
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.curvesView["Red"]?.curve = c.curvesFilter.splines.redCurve
                self.curvesView["Green"]?.curve = c.curvesFilter.splines.greenCurve
                self.curvesView["Blue"]?.curve = c.curvesFilter.splines.blueCurve
                self.curvesView.display()
            })
            
        })
        return c
    }()
    
    /// Композитный фильтр
    lazy var filter:IMPFilter = {
        let f = IMPFilter(context: self.context)
        
        f.addFilter(self.contrast)
        
        return f
    }()
    
    lazy var imageView:IMPImageView = {
        let v = IMPImageView(context: self.context, frame: self.view.bounds)
        v.filter = self.filter
        v.backgroundColor = IMPColor(color: IMPPrefs.colors.background)
        return v
    }()
    
    lazy var curvesView:IMPCurvesView = {
        let v = IMPCurvesView(frame: self.view.bounds)
        
        v.didControlPointsUpdate = { (info) in
            
            self.contrast.autoContrastEnabled = false
            
            if info.id == "Red" {
                self.contrast.curvesFilter.splines.redControls = info.controlPoints
            }
            else if info.id == "Green" {
                self.contrast.curvesFilter.splines.greenControls = info.controlPoints
            }
            else if info.id == "Blue" {
                self.contrast.curvesFilter.splines.blueControls = info.controlPoints
            }
        }
        
        v.wantsLayer = true
        v.layer?.backgroundColor = IMPColor.clearColor().CGColor
        v["Red"]   = IMPCurvesCanvasView.CurveInfo(name: "Red",   color:  IMPColor(red: 1,   green: 0.2, blue: 0.2, alpha: 0.8), maxControls:2)
        v["Green"] = IMPCurvesCanvasView.CurveInfo(name: "Green", color:  IMPColor(red: 0,   green: 1,   blue: 0,   alpha: 0.6), maxControls:2)
        v["Blue"]  = IMPCurvesCanvasView.CurveInfo(name: "Blue",  color:  IMPColor(red: 0.2, green: 0.2, blue: 1,   alpha: 0.8), maxControls:2)
        return v
    }()
    
    lazy var rightPanel:NSView = {
        let v = NSView(frame: self.view.bounds)
        return v
    }()
    
    lazy var histogramView:IMPHistogramView = {
        let v = IMPHistogramView(context: self.context, frame: NSRect(x: 0, y: 0, width: 200, height: 80))
        v.type = .PDF
        self.filter.addDestinationObserver(destination: { (destination) in
            v.filter?.source = destination
        })
        return v
    }()
    
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
                    
                    let filter = IMPFilter(context: IMPContext())
                    let contrast = IMTLAutoContrastFilter(context: self.context)
                    filter.addFilter(contrast)
                    
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
        
        view.addSubview(rightPanel)
        rightPanel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view.snp_top).offset(5)
            make.bottom.equalTo(self.view.snp_bottom).offset(-5)
            make.right.equalTo(self.view.snp_right).offset(-5)
            make.width.equalTo(320)
        }
        
        rightPanel.addSubview(curvesView)
        curvesView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.rightPanel.snp_top).offset(10)
            make.left.equalTo(self.rightPanel).offset(5)
            make.right.equalTo(self.rightPanel).offset(-5)
            make.height.equalTo(200)
        }

        rightPanel.addSubview(histogramView)
        histogramView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.curvesView.snp_bottom).offset(20)
            make.left.equalTo(self.rightPanel).offset(5)
            make.right.equalTo(self.rightPanel).offset(5)
            make.height.equalTo(200)
        }
        
        view.addSubview(toolBar)
        toolBar.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view).offset(1)
            make.left.equalTo(self.view).offset(-1)
            make.right.equalTo(self.rightPanel.snp_left).offset(1)
            make.height.equalTo(80)
            make.width.greaterThanOrEqualTo(600)
        }
        
        view.addSubview(imageView)
        imageView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view.snp_top).offset(10)
            make.bottom.equalTo(self.toolBar.snp_top).offset(0)
            make.left.equalTo(self.view.snp_left).offset(10)
            make.right.equalTo(self.rightPanel.snp_left).offset(0)
        }
    }
    
    func enableFilter(sender:NSButton){
        if sender.state == 1 {
            filter.enabled = true
        }
        else {
            filter.enabled = false
        }
    }
    
    func reset(){
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
    
    let duration:NSTimeInterval = 0.2
    
    lazy var toolBar:IMPToolBar = {
        let t = IMPToolBar(frame: NSRect(x: 0,y: 0,width: 100,height: 40))
        
        t.shadows = self.contrast.shadows
        t.highlights = self.contrast.highlights
        
        t.enableFilterHandler = { (flag) in
            self.filter.enabled = flag
        }
        
        t.enableNormalHandler = { (flag) in
            self.contrast.curvesFilter.adjustment.blending.mode = flag == false ? .LUMNINOSITY : .NORMAL
        }
        
        t.slideHandler = { (step) in
            self.contrast.autoContrastEnabled = true
            self.contrast.degree = step.float/100
        }
        
        t.shadowsHandler = { (value) in
            self.contrast.shadows = value
        }
        
        t.highlightsHandler = { (value) in
            self.contrast.highlights = value
        }

        t.resetHandler = {
            self.reset()
        }
        
        return t
    }()
    
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
        
    }
    
    func updateConfig() {
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

///
/// Всякие полезные и в целом понятные уитилитарные расширения
///


public extension NSRect {
    mutating func setRegion(region:IMPRegion){
        let x = region.left.cgfloat*size.width
        let y = region.top.cgfloat*size.height
        self = NSRect(x: origin.x+x,
                      y: origin.y+y,
                      width: size.width*(1-region.right.cgfloat)-x,
                      height: size.height*(1-region.bottom.cgfloat)-y)
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

/// https://github.com/Hearst-DD/ObjectMapper
///
/// Мапинг объектов в JSON для сохранения контекста редактирования файла, просто для удобства
///
public class IMTLConfig:Mappable {
    public init(){}
    required public init?(_ map: Map) {
    }
    public func mapping(map: Map) {
    }
}



