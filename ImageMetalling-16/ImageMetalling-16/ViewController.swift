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
import IMProcessingUI

class ViewController: NSViewController, IMPDeferrable {
    
    let contextFilters = IMPContext(lazy:false)
    let context = IMPContext(lazy:true)
    
    lazy var planeFilter:IMPMSLPlaneFilter = IMPMSLPlaneFilter(context:self.contextFilters)
    
    lazy var lutFilter:IMPMSLLutFilter = {
        let filter = IMPMSLLutFilter(context:self.contextFilters)
        
        filter.cLut.addObserver(updated: { (lut) in
            self.deferrable.delay = 0.5
            self.deferrable.block = {
                self.context.runOperation(.async, { 
                    self.lut3DView.lut = self.lutFilter.cLut                
                })                    
            }
        })
        
        return filter
    }()
    
    /// Тут просто рисуем картинку с возможностью скрола и зума
    public lazy var colorPlaneView:TargetView = {
        let v = TargetView(frame: self.view.bounds)
        return v
    }()
    
    /// Тут просто рисуем картинку с возможностью скрола и зума
    public lazy var lut2DView:TargetView = {
        let v = TargetView(frame: self.view.bounds)
        return v
    }()
    
    lazy var lut3DView: LutView = LutView(frame: self.view.bounds)
    lazy var gridView = GridView(frame: self.view.bounds)
    
    lazy var alphaSlider = NSSlider(value: 0.5, minValue: 0, maxValue: 1, target: self, action: #selector(slider(sender:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()   
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        view.addSubview(lut3DView)              
        view.addSubview(colorPlaneView)        
        view.addSubview(lut2DView)        
        view.addSubview(alphaSlider)
        
        alphaSlider.isContinuous = true
        
        colorPlaneView.processingView.addSubview(gridView)
        colorPlaneView.processingView.isPaused = false
        
        gridView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        alphaSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
        
        colorPlaneView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalTo(view.snp.centerX).offset(-100)
            make.bottom.equalTo(view.snp.centerY).offset(-5)
        }
        
        lut2DView.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.centerY).offset(5)
            make.left.equalToSuperview()
            make.right.equalTo(colorPlaneView.snp.right)
            make.bottom.equalTo(alphaSlider.snp.top).offset(-10)
        }
        
        lut3DView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.left.equalTo(colorPlaneView.snp.right).offset(5)
            make.bottom.equalTo(alphaSlider.snp.top).offset(-10)
        }
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        colorPlaneView.processingView.fitViewSize(size: NSSize(width: 1024, height: 1024), 
                                                  to: self.colorPlaneView.bounds.size, 
                                                  moveCenter: false)
        colorPlaneView.sizeFit()  
        lut2DView.sizeFit()  
        
        colorPlaneView.processingView.isPaused = false
        lut2DView.processingView.isPaused = false
        
        let space = IMPColorSpace.lab
        let reference = float3(50,0,0)
        let spaceChannels = (1,2)
        
        planeFilter.space = space
        lutFilter.space = space
        
        planeFilter.reference = reference
        lutFilter.reference = reference
        
        planeFilter.spaceChannels = spaceChannels
        lutFilter.spaceChannels = spaceChannels
        
        colorPlaneView.processingView.filter = planeFilter
        lut2DView.processingView.filter = lutFilter
        
        gridView.updateControls = { controls in
            self.planeFilter.controls = controls   
            self.lutFilter.controls = controls                   
        }
        
    }
    
    @objc func slider(sender:NSSlider)  {
        //        gridView.solverAlpha = sender.floatValue
        let value = sender.floatValue*100
        self.planeFilter.reference = float3(value,0,1)
    }
}

