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
import IMProcessingUI

let USE_MOUSE_OVER = false
let PRINT_TIME = false

class GridView: NSView, IMPDeferrable {
    
    public enum SolverLang {
        case cpp
        case metal
    }
    
    let resolution = 12
    
    var solverAlpha:Float = 0.5 {
        didSet{
            updatePoints(updatePlane: true)
        }
    }
    
    var solverLang:SolverLang = .metal {
        didSet{
            updatePoints(updatePlane: true)
        }
    }
    
    var mlsKind:MLSSolverProtocol.Kind = .affine {
        didSet{
            updatePoints(updatePlane: true)
        }
    }
    
    lazy var knotsGrid:KnotsGrid = KnotsGrid(bounds: self.bounds, 
                                             dimension: (width:self.resolution, height: self.resolution), 
                                             radius:10, 
                                             padding:20)
    
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
    
    var updateControls:((_ controls:MLSControls)->Void)?
    
    func config() {
        
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
    }
    
    let context = IMPContext()
    
    lazy var mls_solver:MLSSolverProtocol       = IMPMLSSolver(context: self.context, points:self.knotsGrid.mesh.sources)
    lazy var mls_solver_cpp:MLSSolverProtocol   = MLSSolverCpp(points:self.knotsGrid.mesh.sources)
    
    lazy var updateQ = DispatchQueue(label: "updateQ")
    
    func updatePoints(updatePlane:Bool = false)  {
        
        var p = [float2]()
        var q = [float2]()
        
        for (i,k) in knotsGrid.children.enumerated() {
            if let kk = k as? KnotNode, kk.isPinned {
                q.append(k.position.convert(from: knotsGrid.box))
                p.append(knotsGrid.mesh.sources[i])
            }
        }
        
        let controls = IMPMLSSolver.Controls(p: p, q: q, kind: mlsKind, alpha: solverAlpha) 
        
        let tm = Date()
        
        if updatePlane {
            DispatchQueue.global().async {
                self.updateControls?(controls)                
            }
        }
                
        if PRINT_TIME {
            Swift.print(" ... updateControls   processing time \(-tm.timeIntervalSinceNow)")
        }
        
        switch self.solverLang {
        case .cpp:
            
            self.mls_solver_cpp.process(controls: controls) { (points) in
                DispatchQueue.main.async {
                    self.knotsGrid.update(points)
                    if PRINT_TIME {
                        Swift.print(" ... cpp   processing time \(-tm.timeIntervalSinceNow)")
                    }
                }
            }   
                        
        case .metal:
            self.mls_solver.process(controls: controls) { (points) in
                DispatchQueue.main.async {
                    self.knotsGrid.update(points)
                    if PRINT_TIME {
                        Swift.print(" ... metal processing time \(-tm.timeIntervalSinceNow)")
                    }
                }
            }                   
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
            
            DispatchQueue.global().async {
                self.lastNode?.position = location    
                (self.lastNode as? KnotNode)?.isPinned = true                
            }
            
            self.updatePoints(updatePlane: true)
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
            guard USE_MOUSE_OVER else {return}
            if index >= 0 && index < self.knotsGrid.children.count {
                node?.run(KnotsGrid.scaleIn)
            }
        }) { (index, node) in
            guard USE_MOUSE_OVER else {return}
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
