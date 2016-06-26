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
    
    public class CurveInfo: Equatable{
        
        public var curve:[Float] = [Float]()
        public var id:String { get{return _id} }
        public let name:String
        public let color:IMPColor
        
        var controlPoints = [float2]()
        public var isActive = false {
            didSet {
                view.needsDisplay = true
                view.displayIfNeeded()
            }
        }
        
        public var _id:String
        public init (id: String, name: String, color: IMPColor) {
            self._id = id
            self.name = name
            self.color = color
        }
        
        public init (name: String, color: IMPColor) {
            self._id = name
            self.name = name
            self.color = color
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
    
    override public func mouseDown(event: NSEvent) {
        let location = event.locationInWindow
        let point  = self.convertPoint(location,fromView:nil)
        let xy = float2((point.x/bounds.size.width).float,(point.y/bounds.size.height).float)
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
    
    func drawCurve(dirtyRect: NSRect, curve:[Float], color:NSColor){
        let line = NSBezierPath()
        
        let fillColor = color
        
        fillColor.set()
        line.fill()
        line.lineWidth = 1
        
        line.moveToPoint(NSPoint(x:0, y:0))
        
        for i in 0..<curve.count {
            let xVal = CGFloat(i) * dirtyRect.size.width / CGFloat(255)
            let y = curve[i].cgfloat*dirtyRect.size.height
            line.lineToPoint(NSPoint(x: xVal, y: y))
        }
        
        line.stroke()
    }
    
    override public func drawRect(dirtyRect: NSRect)
    {
        super.drawRect(dirtyRect)
        drawGrid(dirtyRect)
        for i in list {
            var a = i.color.alphaComponent
            if !i.isActive {
                a *= 0.5
            }
            let color = IMPColor(red: i.color.redComponent,   green: i.color.greenComponent, blue: i.color.blueComponent, alpha: a)
            drawCurve(dirtyRect, curve: i.curve, color: color)
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
    
    lazy var curvesSelector:IMPPopUpButton = {
        let v = IMPPopUpButton(frame:NSRect(x:10,y:10,width: self.bounds.size.width, height: 40), pullsDown: false)
        v.autoenablesItems = false
        v.target = self
        v.action = #selector(self.selectCurve(_:))
        v.selectItemAtIndex(1)
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
