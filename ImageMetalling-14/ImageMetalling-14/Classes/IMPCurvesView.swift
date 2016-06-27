//
//  IMPCurvesView.swift
//  ImageMetalling-14
//
//  Created by denis svinarchuk on 26.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Cocoa
import SnapKit
import IMProcessing
import simd

public func == (left: IMPCurvesCanvasView.CurveInfo, right: IMPCurvesCanvasView.CurveInfo) -> Bool {
    return left.id == right.id
}

public class IMPPopUpButton: NSPopUpButton {
    public var backgroundColor:IMPColor?
}

public class IMPCurvesCanvasView: IMPViewBase {
    
    public typealias ControlPointsUpdateHandler = ((CurveInfo:CurveInfo) -> Void)

    public class CurveInfo: Equatable{
        
        public static let defaultControlsNumber = 10
        
        public var curve:[Float] = [Float]()
        public var id:String { get{return _id} }
        public let name:String
        public let color:IMPColor
        public let maxControls:Int
        
        var controlPoints = [float2(0),float2(1)] {
            didSet{
                controlPoints = [float2](controlPoints.suffix(maxControls))
                controlPoints = controlPoints.sort({ $0.x < $1.x })
                
                if let o = view.didControlPointsUpdate {
                    o(CurveInfo: self)
                }
                
                NSLog("controlPoints = \(controlPoints)")
                view.needsDisplay = true
                view.displayIfNeeded()

            }
        }
        
        func findClosePoint(point:float2?, dist:Float = 0.05) -> Int? {
            
            guard let p = point else { return  nil}
            
            for i in 0..<controlPoints.count {
                if distance(controlPoints[i], p) < dist {
                    return i
                }
            }
            return nil
        }
        
        public var isActive = false {
            didSet {
                view.needsDisplay = true
                view.displayIfNeeded()
            }
        }
        
        public var _id:String
        public init (id: String, name: String, color: IMPColor, maxControls:Int = CurveInfo.defaultControlsNumber) {
            self._id = id
            self.name = name
            self.color = color
            self.maxControls = maxControls
        }
        
        public convenience init (name: String, color: IMPColor, maxControls:Int = CurveInfo.defaultControlsNumber) {
            self.init(id: name, name: name, color: color, maxControls:maxControls)
        }
        
        var view:IMPCurvesCanvasView!
    }

    var list = [CurveInfo]()
    
    public subscript(id:String) -> CurveInfo? {
        get{
            let el = list.filter { (object) -> Bool in
                return object.id == id
            }
            if el.count > 0 {
                return el[0]
            }
            else {
                return nil
            }
        }
        set{
            if let index = (list.indexOf { (object) -> Bool in
                return object.id == id
                }) {
                if let v = newValue {
                    v.view = self
                    list[index] = v
                }
            }
            else {
                if let v = newValue {
                    v._id = id
                    v.view = self
                    list.append(v)
                }
                else {
                    let el = list.filter { (object) -> Bool in
                        return object.id == id
                    }
                    if el.count > 0 {
                        list.removeObject(el[0])
                    }
                }
            }
        }
    }
    
    var activeCurve:CurveInfo? {
        get {
            for i in list {
                if i.isActive {
                    return i
                }
            }
            return nil
        }
    }
    
    public var didControlPointsUpdate:ControlPointsUpdateHandler?
    
    func covertPoint(event:NSEvent) -> float2 {
        let location = event.locationInWindow
        let point  = self.convertPoint(location,fromView:nil)
        return float2((point.x/bounds.size.width).float,(point.y/bounds.size.height).float)
    }
    
    var currentPoint:float2?
    var currentPointIndex:Int?
    
    override public func mouseDragged(event: NSEvent) {
        
        guard let cp = currentPoint else { return }

        let xy = covertPoint(event)

        if let curve = activeCurve {
            if let i = curve.findClosePoint(cp) {
                currentPointIndex = i
                currentPoint = xy
            }
            else if currentPointIndex != nil {
                currentPoint = xy
            }
            
            curve.controlPoints[currentPointIndex!] = currentPoint!
        }
    }
    
    override public func mouseDown(event: NSEvent) {
        let xy = covertPoint(event)
        
        currentPointIndex = nil
        
        if let curve = activeCurve {
            if let i = curve.findClosePoint(xy) {
                curve.controlPoints[i] = xy
                currentPoint = xy
            }
            else {
                for i in 0..<curve.curve.count {
                    let x = i.float/curve.curve.count.float
                    let y = curve.curve[i]
                    let p = float2(x,y)
                    if distance(p, xy) < 0.05 {
                        curve.controlPoints.append(xy)
                        currentPoint = xy
                        break
                    }
                }
            }
        }
    }
    
    func drawGrid(dirtyRect: NSRect)  {
        let blackColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        
        blackColor.set()
        let noHLines = 4
        let noVLines = 4
        
        let vSpacing = dirtyRect.size.height / CGFloat(noHLines)
        let hSpacing = dirtyRect.size.width / CGFloat(noVLines)
        
        let bPath:NSBezierPath = NSBezierPath()
        bPath.lineWidth = 0.5
        for i in 1..<noHLines{
            let yVal = CGFloat(i) * vSpacing
            bPath.moveToPoint(NSMakePoint(0, yVal))
            bPath.lineToPoint(NSMakePoint(dirtyRect.size.width , yVal))
        }
        bPath.stroke()
        
        for i in 1..<noVLines{
            let xVal = CGFloat(i) * hSpacing
            bPath.moveToPoint(NSMakePoint(xVal, 0))
            bPath.lineToPoint(NSMakePoint(xVal, dirtyRect.size.height))
        }
        bPath.stroke()
    }
    
    func drawCurve(dirtyRect: NSRect, info:CurveInfo){
        let path = NSBezierPath()
        
        var a = info.color.alphaComponent
        if !info.isActive {
            a *= 0.5
        }
        let color = IMPColor(red: info.color.redComponent,   green: info.color.greenComponent, blue: info.color.blueComponent, alpha: a)

        let fillColor = color
        
        fillColor.set()
        path.fill()
        path.lineWidth = 1
        
        path.moveToPoint(NSPoint(x:0, y:0))
        
        for i in 0..<info.curve.count {
            let x = CGFloat(i) * dirtyRect.size.width / CGFloat(255)
            let y = info.curve[i].cgfloat*dirtyRect.size.height

            let xy = float2((x/dirtyRect.size.width).float,(y/dirtyRect.size.height).float)
            
            if let i = info.findClosePoint(xy) {
                let p = info.controlPoints[i]
                
                let rect = NSRect(
                    x: p.x.cgfloat * dirtyRect.size.width-2.5,
                    y: p.y.cgfloat * dirtyRect.size.height-2.5,
                    width: 5, height: 5)
                
                if  currentPoint != nil && distance(currentPoint!, xy) < 0.05  {
                    NSBezierPath.fillRect(rect)
                }
                else {
                    path.appendBezierPathWithRect(rect)
                }
            }
            
            path.lineToPoint(NSPoint(x: x, y: y))
        }
        
        path.stroke()
    }
    
    
    
    override public func drawRect(dirtyRect: NSRect)
    {
        super.drawRect(dirtyRect)
        drawGrid(dirtyRect)
        for i in list {
            drawCurve(dirtyRect, info: i)
        }
    }
  
}

public class IMPCurvesView: IMPViewBase {
    
    public var backgroundColor:IMPColor? {
        didSet{
            wantsLayer = true
            layer?.backgroundColor = backgroundColor?.CGColor
            curvesSelector.backgroundColor = backgroundColor
        }
    }
    
    lazy var canvas:IMPCurvesCanvasView = {
        return IMPCurvesCanvasView(frame: self.bounds)
    }()
    
    public subscript(id:String) -> IMPCurvesCanvasView.CurveInfo? {
        get{
            return canvas[id]
        }
        set{
            if let v = newValue {
                canvas[id] = v
                curvesSelector.addItemWithTitle(v.name)
            }
        }
    }
    
    public var didControlPointsUpdate:IMPCurvesCanvasView.ControlPointsUpdateHandler? {
        get {
            return canvas.didControlPointsUpdate
        }
        set {
            canvas.didControlPointsUpdate = newValue
        }
    }

    lazy var curvesSelector:IMPPopUpButton = {
        let v = IMPPopUpButton(frame:NSRect(x:10,y:10,width: self.bounds.size.width, height: 40), pullsDown: false)
        v.autoenablesItems = false
        v.target = self
        v.action = #selector(self.selectCurve(_:))
        v.selectItemAtIndex(0)
        return v
    }()
    
    @objc private func selectCurve(sender:NSPopUpButton)  {
        for i in canvas.list {
            i.isActive = false
        }
        let el = canvas.list[sender.indexOfSelectedItem]
        el.isActive = true
    }
    
    var initial = true
    override public func updateLayer() {
        if initial {
            
            addSubview(canvas)
            addSubview(curvesSelector)

            curvesSelector.selectItemAtIndex(0)

            initial = true
            
            curvesSelector.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(self.snp_top).offset(0)
                make.left.equalTo(self).offset(0)
                make.right.equalTo(self).offset(0)
            }

            canvas.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(self.curvesSelector.snp_bottom).offset(5)
                make.left.equalTo(self).offset(0)
                make.right.equalTo(self).offset(0)
                make.bottom.equalTo(self).offset(0)
            }

        }
        
    }
}
