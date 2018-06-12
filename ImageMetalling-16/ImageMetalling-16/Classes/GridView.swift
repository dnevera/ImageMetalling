//
//  GridView.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 06.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Cocoa
import SpriteKit
import simd
import IMProcessing

class GridView: NSView {
    
    var mlsKind:MSLSolverSwift.Kind = .affine {
        didSet{
            updatePoints()
        }
    }
    
    lazy var knotsGrid:KnotsGrid = KnotsGrid(bounds: self.bounds, dimension: (width: 8, height: 8), radius:10, padding:20)
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        config()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        config()
    }
    
    
    override func layout() {
        super.layout()
        knotsGrid.bounds = bounds    
    }    
    
    func config() {
        
        wantsLayer = true
        layer?.backgroundColor = NSColor.darkGray.cgColor
        postsFrameChangedNotifications = true
        postsBoundsChangedNotifications = true
        
        scene.scaleMode       = .resizeFill
        scene.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.0)
        scene.addChild(knotsGrid)
        
        skview.addGestureRecognizer(panGesture)
        
        pressGesture.numberOfTouchesRequired = 1    
        skview.addGestureRecognizer(pressGesture)        
        
        addSubview(skview)
        
        skview.autoresizingMask = [.height, .width]
        skview.frame = NSInsetRect(bounds, 0, 0)
        skview.allowsTransparency = true
        skview.presentScene(scene)  
        
        mls_solver.points = knotsGrid.mlsPoints.sources
        
    }
    
    let context = IMPContext()
    
    lazy var mls_solver:IMPMlsSolver = IMPMlsSolver(context: self.context)
    
    func updatePoints()  {
        
        var p = [float2]()
        var q = [float2]()
        
        for (i,k) in knotsGrid.children.enumerated() {
            if let kk = k as? KnotNode, kk.isPinned {
                q.append(k.position.convert(from: knotsGrid.box))
                p.append(knotsGrid.mlsPoints.sources[i])
            }
        }
        
        do {
            
            let controls = IMPMlsSolver.Controls(p: p, q: q, kind: mlsKind, alpha: 1.0) 
            
            mls_solver.controls = controls
            
            self.mls_solver.process { (points) in
                DispatchQueue.main.async {
                    for i in 0..<points.count {
                        
                        let knot = self.knotsGrid.children[i] as! KnotNode
                        
                        if knot.isPinned { continue }
                        
                        knot.position = points[i].convert(to: self.knotsGrid.box)
                    }                    
                }
            }    

            return
            
            for i in 0..<knotsGrid.children.count {

                //if i >= 1 { continue }
                
                let knot = knotsGrid.children[i] as! KnotNode 
                
                
                let p1 = knot.position.convert(from: knotsGrid.box)
                
                let msl = try _MLSSolver(point: p1, 
                                      p: p, 
                                      q: q,
                                      kind: mlsKind,
                                      alpha: 1.5
                )
                
                let _msl = try MSLSolverSwift(point: p1, 
                                        p: p,  
                                        q: q,
                                        kind: mlsKind,
                                        alpha: 1.5
                )
                
                let pp = msl.value(at: knotsGrid.mlsPoints.sources[i]).convert(to: knotsGrid.box)
                let pp2 = _msl.value(at: knotsGrid.mlsPoints.sources[i]).convert(to: knotsGrid.box)
                
                //Swift.print("p[\(i) = \(pp)]")
                knot.position = pp2
            }                
        }
        catch let error {
            print("\(error)")
        }
        
    }
    
    @objc private func pressHandler(recognizer:NSPanGestureRecognizer)  {
        if lastNode != nil && lastIndex >= 0 {
            (lastNode as? KnotNode)?.isPinned = true
        }        
    }
    
    @objc private func panHandler(recognizer:NSPanGestureRecognizer)  {
        let location:NSPoint = recognizer.location(in: skview)
        
        if lastNode != nil && lastIndex >= 0 {            
            lastNode?.position = location    
            (lastNode as? KnotNode)?.isPinned = true
            
            updatePoints()
        }
    }
    
    private lazy var trackingArea:NSTrackingArea? = nil
    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = trackingArea { removeTrackingArea(t) }
        
        trackingArea = NSTrackingArea(rect: frame,
                                      options: [.activeInKeyWindow,.mouseMoved,.mouseEnteredAndExited],
                                      owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = event.locationInWindow
        let point  = skview.convert(location,from:nil)
        
        findNode(at: point, leaved: { (index, node) in
            if index >= 0 && index < self.knotsGrid.children.count {
                node?.run(KnotsGrid.scaleIn)
            }
        }) { (index, node) in
            if self.lastIndex < 0 {
                node.run(KnotsGrid.scaleOut)
            }
        }        
    }
    
    func findNode(at point:NSPoint, leaved: ((_ index:Int, _ node:SKNode?)->Void)? = nil, entered: ((_ index:Int, _ node:SKNode)->Void)) {
        
        let sceneTouchPoint = scene.convertPoint(fromView: point)
        let node = knotsGrid.atPoint(sceneTouchPoint)
        
        if node == scene || node == knotsGrid {
            leaved?(lastIndex, lastNode)
            lastIndex = -1
            return
        }
        
        if let name = node.name, let index = Int(name) {
            if index >= 0 {
                
                var n = node
                if n.parent?.name != nil {
                    n = n.parent!
                }
                entered(index, n)
                lastIndex = index
                lastNode = n
            }
        }
    }
    
    private var lastIndex = -1
    private var lastNode:SKNode? = nil
    
    private lazy var skview:SKView = SKView(frame: self.bounds)
    private lazy var scene:SKScene = SKScene(size: self.skview.bounds.size)
    
    private lazy var pressGesture:NSClickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(pressHandler(recognizer:)))
    
    private lazy var panGesture:NSPanGestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(panHandler(recognizer:)))
    
}
