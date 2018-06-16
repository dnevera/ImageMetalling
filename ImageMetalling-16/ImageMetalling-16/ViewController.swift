//
//  ViewController.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 06.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Cocoa
import SnapKit
import IMProcessing

class ViewController: NSViewController {
    
    let context = IMPContext(lazy:true)
    
    lazy var planeFilter:IMPColorPlaneFilter = IMPColorPlaneFilter(context:self.context)
    
    /// Тут просто рисуем картинку с возможностью скрола и зума
    public lazy var targetView:TargetView = {
        let v = TargetView(frame: self.view.bounds)
        return v
    }()
    
    lazy var gridView = GridView(frame: self.view.bounds)
    
    lazy var alphaSlider = NSSlider(value: 0.5, minValue: 0, maxValue: 4, target: self, action: #selector(slider(sender:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()   
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        view.addSubview(targetView)        
        view.addSubview(alphaSlider)
        
        //alphaSlider.isContinuous = false
        
        targetView.processingView.addSubview(gridView)
        targetView.processingView.isPaused = false
        
        gridView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        alphaSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
        
        targetView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(alphaSlider.snp.top).offset(-10)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        targetView.processingView.fitViewSize(size: NSSize(width: 1024, height: 1024), 
                                              to: self.targetView.bounds.size, 
                                              moveCenter: false)
        targetView.sizeFit()  
        
        planeFilter.rgb = float3(0.5,0.5,0.5)
        planeFilter.space = .hsv
        planeFilter.spaceChannels = (0,1)
        
        targetView.processingView.image = planeFilter.destination
        
       
        planeFilter.addObserver(destinationUpdated: { (image) in
            self.targetView.processingView.image = image
        })
        
        
        gridView.updateControls = { controls in
            self.planeFilter.context.runOperation(.async) {                
                self.planeFilter.controls = controls   
                self.planeFilter.process()
            } 
        }
        
    }
    
    @objc func slider(sender:NSSlider)  {
//        gridView.solverAlpha = sender.floatValue
        self.planeFilter.reference = float3(0.5,0.5, sender.floatValue)
        self.planeFilter.context.runOperation(.async) {                
            self.planeFilter.process()
        }
    }
}

