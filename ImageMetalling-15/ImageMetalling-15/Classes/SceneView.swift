//
//  SceneView.swift
//  ImageMetalling-15
//
//  Created by denis svinarchuk on 24.05.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

import SceneKit

///
/// Базовый view сцены, всякая настроечная шняга и взаимодействие с тачпадом или мышкой.
/// Покрутить и отзумить то что лежит в constraintNode. Ноду задаем в конкретной сцене.
///
open class SceneView: NSView {
    
    // Стандартный угол обзора
    static var defaultFov:CGFloat = 35
            
    // Просто отступы для сцены от рамок основного окна
    public var padding:CGFloat    = 10 {
        didSet{ needsDisplay = true }
    }
    
    // Соотношение сторон сцены 
    public var viewPortAspect:CGFloat = 0 {
        didSet{ needsDisplay = true }
    }     
    
    public func reset(node:SCNNode) {
        updateFov(SceneView.defaultFov)
        node.pivot = SCNMatrix4Identity
        node.transform = SCNMatrix4Identity
        node.scale = SCNVector3(0.5, 0.5, 0.5)        
    }
    
    public func resetView(animate:Bool = true, duration:CFTimeInterval = 0.15, complete: ((_ node:SCNNode)->Void)?=nil) {
        let node = constraintNode()
        SCNTransaction.begin()
        SCNTransaction.completionBlock = {
            complete?(node)
        }
        SCNTransaction.animationDuration = duration
        reset(node: node)
        SCNTransaction.commit()
    }
    
    open override func layout() {
        super.layout()
        _sceneView.frame = originalFrame
    }
    
    public var fov:CGFloat = defaultFov {
        didSet{
            camera.fieldOfView = fov
        }
    }
    
    public var cameraNode:SCNNode { return _cameraNode }
    public var lightNode:SCNNode  { return _lightNode }
    
    private lazy var camera:SCNCamera = {
        let c = SCNCamera()
        c.fieldOfView = self.fov
        
        c.automaticallyAdjustsZRange = true
        
        c.vignettingPower = 0.6

        c.bloomIntensity = 1.4
        c.bloomBlurRadius = 1.0
        
        c.wantsDepthOfField = true
        c.focalBlurSampleCount = 30
        c.focusDistance = 1.0
        
        return c
    }()
    
    private var lastWidthRatio: CGFloat = 0
    private var lastHeightRatio: CGFloat = 0
    
    open func constraintNode() -> SCNNode {
        return _midNode
    }
    
    public var sceneView:SCNView {
        return _sceneView
    }
    
    public let scene = SCNScene()
    
    open func configure(frame: CGRect){
        
        _sceneView.frame = originalFrame        
        _sceneView.scene = scene
        
        addSubview(_sceneView)
        
        let pan = NSPanGestureRecognizer(target: self, action: #selector(panGesture(recognizer:)))
        pan.buttonMask = 1
        _sceneView.addGestureRecognizer(pan)
        
        let press = NSPressGestureRecognizer(target: self, action: #selector(sceneTapped(recognizer:)))
        _sceneView.addGestureRecognizer(press)        
        
        scene.rootNode.addChildNode(_cameraNode)
        scene.rootNode.addChildNode(_midNode)
        scene.rootNode.addChildNode(_lightNode)
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure(frame: self.frame)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure(frame: self.frame)
    }
    
    
    var originalFrame:NSRect {
        let size = originalBounds.size
        let x    = (frame.size.width - size.width)/2
        let y    = (frame.size.height - size.height)/2
        return NSRect(x:x, y:y, width:size.width, height:size.height)
    }
    
    var originalBounds:NSRect {
        get{
            let w = viewPortAspect != 0 ? bounds.height * viewPortAspect : bounds.width
            let h = bounds.height
            let scaleX = w / maxCanvasSize.width
            let scaleY = h / maxCanvasSize.height
            let scale = max(scaleX, scaleY)
            return NSRect(x:0, y:0,
                          width:  w / scale,
                          height: h / scale)
        }
    }
    
    private var maxCanvasSize:NSSize {
        return NSSize(width:bounds.size.width - padding,
                      height:bounds.size.height - padding)
    }
    
    private lazy var _midNode:SCNNode = { 
        let node = SCNNode()
        node.position = SCNVector3(x: 0, y: 0, z: 0)
        return node
    }()
    
    private lazy var _cameraNode:SCNNode = {
        let n = SCNNode()
        
        //initial camera setup
        n.position = SCNVector3(x: 0, y: 0, z: 3.0)
        n.eulerAngles.y = -2 * CGFloat.pi * self.lastWidthRatio
        n.eulerAngles.x = -CGFloat.pi * self.lastHeightRatio

        n.camera = self.camera      
        
        let constraint = SCNLookAtConstraint(target: self.constraintNode())
        n.constraints = [constraint]
        
        return n
    }()
    
    private lazy var _lightNode:SCNNode = {
        
        let light = SCNLight()
        light.type = SCNLight.LightType.directional
        light.castsShadow = true
        light.color = NSColor.white 
        
        let n = SCNNode()
        n.light = light
        n.position = SCNVector3(x: 1, y: 1, z: 1)        
        let constraint = SCNLookAtConstraint(target: self.constraintNode())
        n.constraints = [constraint]
        
        return n
    }()
    
    private lazy var _sceneView:SCNView = {
        let f = SCNView(frame: self.bounds,
                        options: ["preferredRenderingAPI" : SCNRenderingAPI.metal])
        
        f.backgroundColor = NSColor.clear
        f.allowsCameraControl = false
        f.antialiasingMode = .multisampling8X
        
        if let cam = f.pointOfView?.camera {
            cam.fieldOfView = 0
        }
        
        return f
    }()
    
    private func updateFov(_ fv: CGFloat){
        if fv < 5 { fov = 5 }
        else if fv > 75 { fov = 75 }
        else { fov = fv }
    }
    
    open override func scrollWheel(with event: NSEvent) {
        updateFov(fov - event.deltaY)
    }
    
    private var zoomValue:CGFloat = 1
    open override func magnify(with event: NSEvent) {
        updateFov(fov - event.magnification * 10)
    }
    
    @objc private func panGesture(recognizer: NSPanGestureRecognizer){
        
        let translation = recognizer.translation(in: recognizer.view!)
        
        let x = translation.x
        let y = -translation.y
        
        let anglePan = sqrt(pow(x,2)+pow(y,2))*CGFloat.pi/180.0
        
        var rotationVector = SCNVector4()
        rotationVector.x = y
        rotationVector.y = x
        rotationVector.z = 0
        rotationVector.w = anglePan
        
        constraintNode().rotation = rotationVector
        
        if(recognizer.state == .ended) {
            //
            let currentPivot = constraintNode().pivot
            let changePivot = SCNMatrix4Invert( constraintNode().transform)
            let pivot = SCNMatrix4Mult(changePivot, currentPivot)
            constraintNode().pivot = pivot
            constraintNode().transform = SCNMatrix4Identity
        }
    }
    
    @objc private func sceneTapped(recognizer: NSPressGestureRecognizer) {
        let location = recognizer.location(in: _sceneView)
        
        let hitResults = _sceneView.hitTest(location, options: nil)
        if hitResults.count > 1 {
            let result = hitResults[1] 
            let node = result.node
            
            let fadeIn = SCNAction.fadeIn(duration: 0.1)
            let fadeOut = SCNAction.fadeOut(duration: 0.1)
            let pulse = SCNAction.repeat(SCNAction.sequence([fadeOut,fadeIn]), count: 2)
            
            node.runAction(pulse)
        }
    }
}

