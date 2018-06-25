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
import Carbon.HIToolbox

let USE_MOUSE_OVER = false
let PRINT_TIME = false

class GridView: NSView, IMPDeferrable {
    
    public enum SolverLang {
        case cpp
        case metal
    }
    
    let resolution = 16
    
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
    
    var isGroupping = false {
        didSet{
            if knotsGrid.grouppingIndex >= 0 {
                guard let g = knotsGrid.grouppingKnots[knotsGrid.grouppingIndex], g.count > 0 else {
                    return
                } 
            }
            knotsGrid.grouppingIndex += 1
            knotsGrid.grouppingKnots[knotsGrid.grouppingIndex] = []
        }
    }    
    
    func config() {
        
        postsFrameChangedNotifications = true
        postsBoundsChangedNotifications = true
        
        scene.scaleMode       = .resizeFill
        scene.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.0)
        scene.addChild(knotsGrid)
        
        skview.addGestureRecognizer(panGesture)
        
        clickGesture.numberOfTouchesRequired = 1  
        clickGesture.numberOfClicksRequired = 1
        skview.addGestureRecognizer(clickGesture)   
        
        pressGesture.numberOfTouchesRequired = 1
        skview.addGestureRecognizer(pressGesture)
        
        addSubview(skview)
        
        skview.autoresizingMask = [.height, .width]
        skview.frame = NSInsetRect(bounds, 0, 0)
        skview.allowsTransparency = true
        skview.presentScene(scene)     
        
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {
            self.flagsChanged(with: $0)
            if $0.modifierFlags.contains([.command]) {
                self.isGroupping = true
            }
            else {
                self.isGroupping = false
            }
            return $0
        }        
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
            self.updateControls?(controls)                
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
        
        self.window?.makeFirstResponder(self)
        
        let location:NSPoint = recognizer.location(in: skview)
        let point  = skview.convert(location,from:nil)
        
        findNode(at: point, leaved: { (index, node) in            
            (node as? KnotNode)?.isPinned = true
        })
    }
    
    var panLocationBegan = CGPoint.zero
    @objc private func panHandler(recognizer:NSPanGestureRecognizer)  {
        let location:NSPoint = recognizer.location(in: skview)
        
        if isGroupping {            
            findNode(at: location) { (index, node) in
                if let node = (node as? KnotNode) {
                    if let grp = self.knotsGrid.grouppingKnots[self.knotsGrid.grouppingIndex] {
                        if !grp.contains(where: { (n) -> Bool in
                            return n == node 
                        }){
                            self.knotsGrid.grouppingKnots[self.knotsGrid.grouppingIndex]?.append(node)
                        }
                    }
                    node.isPinned = true                    
                }
            }            
            return
        }
                
        if lastNode != nil && lastIndex >= 0 {

            if let idx = knotsGrid.grouppingKnots.index(where: { (key, values) -> Bool in
                return values.contains(where: { (node) -> Bool in
                    return  node == lastNode!
                })
            }) {
                let knots = knotsGrid.grouppingKnots[idx] 
                var offset = CGPoint.zero 
                for k in knots.value {
                    if lastNode == k {
                        offset = CGPoint(x:k.position.x-location.x, y:k.position.y-location.y) 
                        k.position = location
                        break
                    }                    
                }
                for k in knots.value {
                    if lastNode != k {
                        k.position = CGPoint(x:k.position.x-offset.x, y:k.position.y-offset.y)
                    }                    
                }

            }
            else {            
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
                                      options: [.activeInKeyWindow,.mouseMoved, .enabledDuringMouseDrag, .mouseEnteredAndExited],
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
    
    func findNode(at point:NSPoint, leaved: ((_ index:Int, _ node:SKNode?)->Void)? = nil, entered: ((_ index:Int, _ node:SKNode)->Void)?=nil) {
        
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
                entered?(index, n)
                lastIndex = index
                lastNode = n
            }
        }
    }
    
    private var lastIndex = -1
    private var lastNode:SKNode? = nil
    
    private lazy var skview:SKView = SKView(frame: self.bounds)
    private lazy var scene:SKScene = SKScene(size: self.skview.bounds.size)
    
    private lazy var clickGesture:NSClickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(pressHandler(recognizer:)))
   
    private lazy var pressGesture:NSClickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(pressHandler(recognizer:)))
    
    
    private lazy var panGesture:NSPanGestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(panHandler(recognizer:)))
    
}
