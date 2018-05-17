//
//  ViewController.swift
//  ImageMetalling-14
//
//  Created by denis svinarchuk on 16.05.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Cocoa
import SpriteKit
import IMProcessing
import IMProcessingUI
import SnapKit

class ViewController: NSViewController {
    
    var patch = PatchNode(size: 20)
    
    var context = IMPContext()
    
    var imagePath:String? {
        didSet{
            guard  let path = imagePath else {
                return
            }            
            
            let image = IMPImage(context: context, path: path)
            
            patchColors.source = image
            targetView.processingView.image = IMPImage(context: context, path: path)
            
            let size  = image.size ?? NSSize(width: 700, height: 500)
            
            self.targetView.processingView.fitViewSize(size: size, to: self.targetView.bounds.size, moveCenter: false)
            self.targetView.sizeFit()
            
            patch.position.x = targetView.processingView.frame.size.width/2
            patch.position.y = targetView.processingView.frame.size.height/2
            
            scene.size = self.targetView.processingView.bounds.size
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(targetView)
        
        targetView.autoresizingMask = [.height, .width] 
        targetView.frame = view.bounds 
        
        targetView.processingView.addSubview(skview)
        
        scene.scaleMode       = .resizeFill
        scene.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.0)
        scene.addChild(patch)
        
        patch.position.x = targetView.processingView.frame.size.width/2
        patch.position.y = targetView.processingView.frame.size.height/2
        
        skview.addGestureRecognizer(panGesture)
        
        view.addSubview(colorLabel)
        colorLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        
        defer {
            skview.autoresizingMask = [.height, .width]
            skview.frame = targetView.processingView.bounds
            skview.allowsTransparency = true
            skview.presentScene(scene)
        }
    }
    
    public lazy var targetView:TargetView = {
        let v = TargetView(frame: self.view.bounds)
        return v
    }()
    
    private lazy var skview:SKView = SKView(frame: self.view.bounds)
    private lazy var scene:SKScene = SKScene(size: self.skview.bounds.size)
    private lazy var panGesture:NSPanGestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(panHandler(recognizer:)))
    
    @objc private func panHandler(recognizer:NSPanGestureRecognizer)  {
        let position:NSPoint = recognizer.location(in: skview)
        patch.position = position
        
        let size = skview.bounds.size
        let point =  float2((position.x / size.width).float, 1-(position.y / size.height).float)
        
        patchColors.centers = [point]
    }
    
    private lazy var patchColors:IMPColorObserver = {
        let f = IMPColorObserver(context: self.context)        
        f.addObserver(destinationUpdated: { (destination) in
            var rgb = self.patchColors.colors[0] 
            let color = NSColor(color: float4(rgb.r,rgb.g,rgb.b,1))
            rgb = rgb * float3(255)
            DispatchQueue.main.async {
                self.colorLabel.backgroundColor = color
                self.colorLabel.stringValue = String(format: "%3.0f, %3.0f, %3.0f", rgb.r, rgb.g, rgb.b)
            }
        })        
        return f
    }()
    
    private lazy var colorLabel:NSTextField = self.makeLabel(frame: self.view.bounds)
    
    private func makeLabel(frame:NSRect) -> NSTextField {
        let label = NSTextField(frame:frame)
        label.alignment = .center
        label.cell?.lineBreakMode = .byTruncatingMiddle
        label.backgroundColor = NSColor.clear
        label.isEditable = false        
        label.isBezeled = false
        label.font =  NSFont(name: "Courier New", size: 12)
        return label
    }
}

