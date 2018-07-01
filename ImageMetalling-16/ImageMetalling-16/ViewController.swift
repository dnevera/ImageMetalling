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
    
    var imageSavingFile:URL? {
        didSet {
            if let url = imageFile, let saveUrl = imageSavingFile {
                let filter = IMPCLutFilter(context: context)
                filter.clut = self.lut12Filter.cLut
                filter.source = IMPImage(context: context, url: url)
                do {
                    try filter.destination.write(to: saveUrl, using: IMPImageFileType.jpeg, reflect: true)
                }
                catch let error {
                    Swift.print(error)
                }
            }
        }
    }
    
    var imageFile:URL? {
        didSet{
            
            detchedWindow.contentViewController = imageViewController
            detchedWindow.makeKeyAndOrderFront(nil)            

            if let url = imageFile {
                let image = IMPImage(context: context, url: url)
                imageViewController.imageView.processingView.filter?.source = image      
                let size  = image.size ?? NSSize(width: 700, height: 500)                
                imageViewController.imageView.processingView.fitViewSize(size: size, to: imageViewController.view.bounds.size, moveCenter: false)                                
                imageViewController.imageView.sizeFit()
            }            
        }
    } 
    
    lazy var imageViewController:ImageViewController = {
       let c =  ImageViewController()
        c.patchColorHandler = { color in                                                 
            self.plane01GridView.addKnot(point: self.plane01Filter.planeCoord(for:color))
            self.plane12GridView.addKnot(point: self.plane12Filter.planeCoord(for:color))
        }
        return c
    }()
    
    let context = IMPContext(lazy:true)
            
    lazy var lut01Filter:IMPMSLLutFilter = {
        let filter = IMPMSLLutFilter(context:self.context)
        filter.add(filter: self.lut12Filter)
        return filter
    }()

    lazy var lut12Filter:IMPMSLLutFilter = {
        
        let filter = IMPMSLLutFilter(context:self.context)
        
        filter.cLut.addObserver(updated: { (lut) in

            self.context.runOperation(.async, { 
                self.imageViewController.filter.clut = filter.cLut
            })

            self.context.runOperation(.async, { 
                self.lut3DView.lut = filter.cLut      
            })                    
        })
        
        return filter
    }()
    
    lazy var plane01Filter:IMPMSLPlaneFilter = IMPMSLPlaneFilter(context:self.context)        
    lazy var plane01View:TargetView = {
        let v = TargetView(frame: self.view.bounds)
        v.processingView.filter = self.plane01Filter
        v.processingView.addSubview(self.plane01GridView)
        self.plane01GridView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return v
    }()    
    lazy var plane01GridView:GridView = {
        let v = GridView(frame: self.view.bounds)        
        v.updateControls = { controls in
            self.plane01Filter.controls = controls               
            self.lut01Filter.controls = controls                
            self.context.runOperation(.async){
                self.lut01Filter.process()
            }
        }             
        return v
    }()
    
    lazy var plane12Filter:IMPMSLPlaneFilter = IMPMSLPlaneFilter(context:self.context)
    lazy var plane12View:TargetView = {
        let v = TargetView(frame: self.view.bounds)
        v.processingView.filter = self.plane12Filter
        v.processingView.addSubview(self.plane12GridView)        
        self.plane12GridView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return v
    }()    
    lazy var plane12GridView:GridView = {
        let v = GridView(frame: self.view.bounds)
        v.updateControls = { controls in
            self.plane12Filter.controls = controls               
            self.lut12Filter.controls = controls                
            self.context.runOperation(.async){
                self.lut12Filter.process()
            }
        }             
        return v
    }()
    
    public lazy var lut2DView:TargetView = {
        let v = TargetView(frame: self.view.bounds)
        return v
    }()
    
    lazy var lut3DView: LutView = LutView(frame: self.view.bounds)
    
    lazy var alphaSlider = NSSlider(value: 0.5, minValue: 0, maxValue: 2, target: self, action: #selector(slider(sender:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()   
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        view.addSubview(lut3DView)              

        view.addSubview(plane01View)        
        view.addSubview(plane12View)        
        
        view.addSubview(lut2DView)        
        view.addSubview(alphaSlider)
        
        alphaSlider.isContinuous = true
                              
        alphaSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
        
        plane01View.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.bottom.equalTo(view.snp.centerY).offset(-5)
            make.left.equalToSuperview()
            make.right.equalTo(view.snp.centerX)
        }

        plane12View.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.centerY).offset(5)
            make.bottom.equalTo(alphaSlider.snp.top).offset(-5)
            make.centerX.equalTo(plane01View.snp.centerX)
            make.width.equalTo(plane01View.snp.width)
        }        
        
        lut3DView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(lut2DView.snp.top).offset(-10)
            make.left.equalTo(plane01View.snp.right).offset(5)
            make.right.equalToSuperview()
        }

        lut2DView.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.centerY).offset(5)
            make.bottom.equalTo(alphaSlider.snp.top).offset(-10)

            make.left.equalTo(plane01View.snp.right).offset(5)
            make.right.equalToSuperview()
        }
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        plane01View.processingView.fitViewSize(size: NSSize(width: 512, height: 512), 
                                                  to: self.plane01View.bounds.size, 
                                                  moveCenter: false)

        plane12View.processingView.fitViewSize(size: NSSize(width: 512, height: 512), 
                                               to: self.plane12View.bounds.size, 
                                               moveCenter: false)

        lut2DView.processingView.fitViewSize(size: NSSize(width: 512, height: 512), 
                                                  to: self.lut2DView.bounds.size, 
                                                  moveCenter: false)
                
        plane01View.sizeFit()  
        plane12View.sizeFit()
        
        lut2DView.sizeFit()  
                        
        plane01Filter.space = .lab
        plane01Filter.reference = float3(80,0,0)
        plane01Filter.spaceChannels = (1,2)

        lut01Filter.space = plane01Filter.space        
        lut01Filter.reference = plane01Filter.reference        
        lut01Filter.spaceChannels = plane01Filter.spaceChannels

        plane12Filter.space = .hsv
        plane12Filter.reference = float3(0,1,1)
        plane12Filter.spaceChannels =  (0,2)

        lut12Filter.space = plane12Filter.space        
        lut12Filter.reference = plane12Filter.reference        
        lut12Filter.spaceChannels = plane12Filter.spaceChannels
                
        lut2DView.processingView.filter = lut12Filter  
    }
    
    @objc func slider(sender:NSSlider)  {
        plane01GridView.solverAlpha = sender.floatValue
    }
    
    
    lazy var detchedWindow:NSWindow = { 
        let w = NSWindow( contentRect: NSScreen.main!.visibleFrame, 
                          styleMask: [.closable, 
                                      .resizable, 
                                      .titled,
                                      .fullSizeContentView], 
                          backing: .buffered, 
                          defer: false, 
                          screen: NSScreen.main)
        w.isReleasedWhenClosed  = false
        w.collectionBehavior = .fullScreenAllowsTiling
        return w
    }()
}

