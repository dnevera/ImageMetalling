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

    lazy var knotsGrid:KnotsGrid = KnotsGrid(bounds: self.bounds, dimension: (width: 10, height: 10), radius:10, padding:20)

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
                
    }
    
    @objc private func pressHandler(recognizer:NSPanGestureRecognizer)  {
        if lastNode != nil && lastIndex >= 0 {
            (lastNode as? KnotNode)?.isPinned = true
        }        
    }
    
    @objc private func panHandler(recognizer:NSPanGestureRecognizer)  {
        let location:NSPoint = recognizer.location(in: skview)
        
        lastNode?.position = location    
        (lastNode as? KnotNode)?.isPinned = true
        
        if lastNode != nil && lastIndex >= 0 {
            
            var p = [float2]()
            var q = [float2]()

            for (i,k) in knotsGrid.children.enumerated() {
                if let kk = k as? KnotNode, kk.isPinned {
                    q.append(k.position.convert(from: knotsGrid.box))
                    p.append(knotsGrid.mlsPoints.sources[i])
                }
            }
                        
            do {
                
                for i in 0..<knotsGrid.children.count {
                    //if i == lastIndex { continue }

                    let msl = try MSLSolver(point: knotsGrid.children[i].position.convert(from: knotsGrid.box), 
                                            p: p,  
                                            q: q,
                                            kind: .similarity,
                                            alpha: 1
                    ) 
                    
                    knotsGrid.children[i].position = msl.value(at: knotsGrid.mlsPoints.sources[i]).convert(to: knotsGrid.box)
                }                
            }
            catch let error {
                print("\(error)")
            }
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
