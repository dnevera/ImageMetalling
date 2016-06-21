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
    
    /// Основной фильтр коррекции геометрических искажений
    lazy var freeWarp:IMLTBezierWarpFilter = {
        let w = IMLTBezierWarpFilter(context: self.context)
        w.backgroundColor = IMPColor(color: IMPPrefs.colors.background)
        return w
    }()
    
    /// Квадратная сетка
    lazy var grid:IMPGridGenerator = {
        let g = IMPGridGenerator(context: self.context)
        g.enabled = self.toolBar.enabledGrid
        g.adjustment.step  = 50
        g.adjustment.color = float4(1,1,1,0.5)
        g.adjustment.subDivisionColor = float4(0.75,0,0,0.9)
        return g
    }()
    
    /// Подсвечивание областей за которые можно тянуть картинку во время коррекции
    lazy var imageSpots:IMPGridGenerator = {
        let g = IMPGridGenerator(context: self.context)
        g.enabled = self.grid.enabled
        g.adjustment.step  = 50
        g.adjustment.color = float4(0)
        g.adjustment.subDivisionColor = float4(0)
        g.adjustment.spotAreaColor = float4(1,1,1,0.3)
        g.adjustment.spotAreaType = .Solid
        return g
    }()

    /// Для визуализации кропа будем использовать фильтр виньетирования.
    /// Просто выставим резкие границы.
    lazy var cropView:IMPVignetteFilter = {
        let f = IMPVignetteFilter(context:self.context, type:.Frame)
        f.adjustment.blending.opacity = 0.9
        f.adjustment.start = 0
        f.adjustment.end = 0
        f.adjustment.color = IMPPrefs.colors.background.rgb
        return f
    }()
    

    /// Композитный фильтр
    lazy var filter:IMPFilter = {
        let f = IMPFilter(context: self.context)
        
        /// Деформатор в пространстве Bezier кривых 
        f.addFilter(self.freeWarp)
        
        /// Первый слой с подсветкой будет трансфоримироваться с основной картинкой
        f.addFilter(self.imageSpots)

        /// Визуализация кропа
        f.addFilter(self.cropView)
        
        /// Сетка
        f.addFilter(self.grid)
        
        return f
    }()
    
    lazy var imageView:IMPImageView = {
        let v = IMPImageView(context: self.context, frame: self.view.bounds)
        v.filter = self.filter
        v.backgroundColor = IMPColor(color: IMPPrefs.colors.background)
        
        /// События от курсора экрана обрабатываем для манипуляции с геометрией
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
                    
                    let filter = IMPFilter(context: IMPContext())
                    let warp   = IMLTBezierWarpFilter(context: filter.context)
                    warp.points = self.freeWarp.points

                    let crop   = IMPCropFilter(context: filter.context)
                    crop.region = self.cropView.region
                    
                    filter.addFilter(warp)
                    filter.addFilter(crop)
                    
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
    
    ///  Зона действия курсора.
    ///  Подразумеваем 8 зон за которые нам можно тянуть фотопластину:
    ///  - угловые зоны позволяют исправлять угловые искажения
    ///  - центральные по краяем парралельные стороным прямоугольника основного 
    ///    "рабочего стола"
    ///  Кждая зона 1/3 фотопластины.
    ///
    enum PointerPlace: Int {
        case LeftBottom
        case LeftTop
        case RightTop
        case RightBottom
        case Top
        case Bottom
        case Left
        case Right
        case Center
        case Undefined
    }
    
    /// Конвертируем абсолютное значение текущего курсора в координаты скорректированного объекта
    func convertPoint(point:NSPoint, fromFrame:NSRect, toFrame:NSRect) -> NSPoint {
        
        let size = float2(toFrame.size.width.float,toFrame.size.height.float)

        let x = (point.x/fromFrame.size.width - 0.5 ) * 2
        let y = (point.y/fromFrame.size.height - 0.5 ) * 2
        
        var p = ((float4(x.float,y.float,0,1)).xy/2) + float2(0.5)
        p = p * size
        
        return NSPoint(x: p.x.cgfloat,y: p.y.cgfloat)
    }
    
    var pointerPlace:PointerPlace = .Undefined
    
    /// Вычисляем зону где находится курсор
    func getPointerPlace(point:NSPoint, view:NSView) ->  PointerPlace {
        
        var frame = view.frame
        
        let w = frame.size.width.float
        let h = frame.size.height.float
        
        let point = convertPoint(point, fromFrame: view.frame, toFrame: frame)
        
        if point.x > w/3 && point.x < w*2/3 && point.y < h/3 {
            return .Bottom
        }
        else if point.x < w/3 && point.y > h/3 && point.y < h*2/3 {
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
        else if point.x > w*2/3 && point.y > h/3 && point.y < h*2/3 {
            return .Right
        }
        else if point.x > w*2/3 && point.y < h/3 {
            return .RightBottom
        }
        else if point.x > w*2/3 && point.y > h*2/3 {
            return .RightTop
        }
        else if point.x >= w*1/3 && point.x <= w*2/3 && point.y >= h*1/3 && point.y <= h*2/3{
            return .Center
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

        case .Center:
            spotArea = IMPRegion(left: 1/3, right: 1/3, top: 1/3, bottom: 1/3)

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
    }
    
    func localMouseUp(theEvent: NSEvent, location:NSPoint, view:NSView) {
        touched = false
        self.spotArea(IMPRegion.null)
    }
    
    func pointerMoved(theEvent: NSEvent, location:NSPoint, view:NSView)  {
        if !touched {
            return
        }
        
        mouse_point = location
        
        let w = view.frame.size.width.float
        let h = view.frame.size.height.float
        let position = float2(mouse_point.x.float,h-mouse_point.y.float)/float2(w,h)
        
        let distancex = 1/w * mouse_point_offset.x.float
        let distancey = 1/h * mouse_point_offset.y.float

        if toolBar.enabledCrop {
            
            var cropArea = cropView.region
            
            switch pointerPlace {
                
            case .LeftBottom:
                cropArea = cropArea + IMPRegion(left: -distancex, right: 0, top: 0, bottom: -distancey)
            case .Left:
                cropArea = cropArea + IMPRegion(left: -distancex, right: 0, top: 0, bottom: 0)
            case .LeftTop:
                cropArea = cropArea + IMPRegion(left: -distancex, right: 0, top: distancey, bottom: 0)
                
            case .Top:
                cropArea = cropArea + IMPRegion(left: 0, right: 0, top: distancey, bottom: 0)
            case .RightTop:
                cropArea = cropArea + IMPRegion(left: 0, right: distancex, top: distancey, bottom: 0)
            case .Right:
                cropArea = cropArea + IMPRegion(left: 0, right: distancex, top: 0, bottom: 0)
                
            case .RightBottom:
                cropArea = cropArea + IMPRegion(left: 0, right: distancex, top: 0, bottom: -distancey)
            case .Bottom:
                cropArea = cropArea + IMPRegion(left: 0, right: 0, top: 0, bottom: -distancey)
                
            case .Center:
                cropArea = cropArea + IMPRegion(left: -distancex/2, right: distancex/2, top: distancey/2, bottom: -distancey/2)
                
            default:
                break
            }

            cropArea.left = cropArea.left < 0 ? 0 : cropArea.left > 0.49 ? 0.49 : cropArea.left
            cropArea.right = cropArea.right < 0 ? 0 : cropArea.right > 0.49 ? 0.49 : cropArea.right
            cropArea.bottom = cropArea.bottom < 0 ? 0 : cropArea.bottom > 0.49 ? 0.49 : cropArea.bottom
            cropArea.top = cropArea.top < 0 ? 0 : cropArea.top > 0.49 ? 0.49 : cropArea.top
            
            cropView.region  = cropArea
        }
        else {
            for i in 0..<4 {
                for j in 0..<4{
                    let p = IMLTBezierWarpFilter.baseControlPoints[i,j]
                    var d = 1-distance(position, p)
                    d = d < 0.5 ? 0 : pow(d, 2)
                    freeWarp.points[i,j] += float2(distancex,-distancey) * d
                }
            }
        }
        
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
    
    func reset(){
        
        let startSlider = Float(toolBar.gridSize)
        let startWarp = freeWarp.points
        let finalWarp = IMPFloat2x4x4()
        
        let startCrop = cropView.region
        let finalCrop = IMPRegion()
        
        IMPDisplayTimer.cancelAll()
        IMPDisplayTimer.execute(duration: duration, options: .EaseInOut, update: { (atTime) in
            
            self.freeWarp.points = startWarp.lerp(final: finalWarp, t: atTime.float)
            self.cropView.region = startCrop.lerp(final: finalCrop, t: atTime.float)
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
    
    let duration:NSTimeInterval = 0.2
    
    lazy var toolBar:IMPToolBar = {
        let t = IMPToolBar(frame: NSRect(x: 0,y: 0,width: 100,height: 20))
        
        t.enableFilterHandler = { (flag) in
            self.filter.enabled = flag
            self.grid.enabled = t.enabledGrid
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
        
        let startWarp = freeWarp.points
        let startCrop = cropView.region
        
        IMPDisplayTimer.cancelAll()
        IMPDisplayTimer.execute(duration: duration, options: .EaseOut, update: { (atTime) in
           self.freeWarp.points = startWarp.lerp(final: self.config.points, t: atTime.float)
            self.cropView.region = startCrop.lerp(final: self.config.crop, t: atTime.float)
        })
    }
    
    func updateConfig() {
        config.points = freeWarp.points
        config.crop = cropView.region
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
                      width: size.width*(1-region.right)-x,
                      height: size.height*(1-region.bottom)-y)
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
    
    var points = IMPFloat2x4x4()
    var crop = IMPRegion()

    public init(){}
    
    required public init?(_ map: Map) {
    }
    
    public func mapping(map: Map) {
        points <- (map["points"],transformTensor)
        crop <- (map["crop"],transformRegion)
    }

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

    let transformTensor = TransformOf<IMPFloat2x4x4, [[Float]]>(fromJSON: { (value: [[Float]]?) -> IMPFloat2x4x4? in

        if let value = value {
            var t = IMPFloat2x4x4()
            var i = 0
            for v in value {
                let p = float2(v[0],v[1])
                t[i] = p
                i += 1
            }
            return t
        }
        return nil
        }, toJSON: { (value: IMPFloat2x4x4?) -> [[Float]]? in
            if let tensor = value {
                var json = [[Float]]()
                for i in 0..<16{
                    let t = tensor[i]
                    json.append([Float]([t.x,t.y]))
                }
                return json
            }
            return nil
    })
}



