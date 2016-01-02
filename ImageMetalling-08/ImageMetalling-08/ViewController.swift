//
//  ViewController.swift
//  ImageMetalling-08
//
//  Created by denis svinarchuk on 01.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Cocoa
import IMProcessing
import SnapKit


class ViewController: NSViewController {

    let context = IMPContext()
    var imageView:IMPImageView!
    
    var pannelScrollView = NSScrollView()
    var histogramView:IMPHistogramView!
    var paletteView:IMPPaletteListView!
    
    var filter:IMPTestFilter!
    
    override func viewDidLoad() {

        super.viewDidLoad()

        configurePannel()
        
        filter = IMPTestFilter(context: context)
        
        imageView = IMPImageView(context: context, frame: view.bounds)
        imageView.filter = filter
        imageView.backgroundColor = IMPColor(color: IMPPrefs.colors.background)

        
        filter.addDestinationObserver { (destination) -> Void in
            self.histogramView.source = destination
        }
        
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view).inset(NSEdgeInsetsMake(10, 10, 10, 320))
        }
        
        
        
        // Do any additional setup after loading the view.
        
        IMPDocument.sharedInstance.addDocumentObserver { (file, type) -> Void in
            if type == .Image {
                if let image = IMPImage(contentsOfFile: file){
                    self.imageView.source = IMPImageProvider(context: self.imageView.context, image: image)
                }
            }
        }
        
        IMPMenuHandler.sharedInstance.addMenuObserver { (item) -> Void in
            if let tag = IMPMenuTag(rawValue: item.tag) {
                switch tag {
                case .zoomFit:
                    self.zoomFit()
                case .zoom100:
                    self.zoom100()
                }
            }
        }
    }
    
    private func zoomFit(){
        asyncChanges { () -> Void in
            self.imageView.sizeFit()
        }
    }
    
    private func zoom100(){
        asyncChanges { () -> Void in
            self.imageView.sizeOriginal()
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        asyncChanges { () -> Void in
            self.imageView.sizeFit()
        }
    }
    
    var q = dispatch_queue_create("ViewController", DISPATCH_QUEUE_CONCURRENT)
    
    private func asyncChanges(block:()->Void) {
        dispatch_async(q, { () -> Void in
            //
            // немного того, но... :)
            //
            dispatch_after(0, dispatch_get_main_queue()) { () -> Void in
                block()
            }
        })
    }
    
    var sview:NSView!
    var allHeights = CGFloat(0)
    private func configurePannel(){
        
        pannelScrollView.wantsLayer = true
        view.addSubview(pannelScrollView)
        
        pannelScrollView.drawsBackground = false
        pannelScrollView.documentView = imageView
        pannelScrollView.allowsMagnification = false
        pannelScrollView.contentView.wantsLayer = true
        
        sview = NSView(frame: pannelScrollView.bounds)
        sview.wantsLayer = true
        sview.layer?.backgroundColor = IMPColor.clearColor().CGColor
        pannelScrollView.documentView = sview
        
        pannelScrollView.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(320)
            make.top.equalTo(pannelScrollView.superview!).offset(10)
            make.bottom.equalTo(pannelScrollView.superview!).offset(10)
            make.right.equalTo(pannelScrollView.superview!).offset(10)
        }
        
        sview.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(pannelScrollView).inset(NSEdgeInsetsMake(0, 0, 0, 0))
        }
        
        histogramView = IMPHistogramView(frame: NSRect(x: 0, y: 0, width: 320, height: 240))
        histogramView.backgroundColor = IMPColor.clearColor()
        
        sview.addSubview(histogramView)
        
        
        histogramView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(sview).offset(10)
            make.left.equalTo(sview).offset(10)
            make.right.equalTo(sview).offset(-10)
            make.height.equalTo(200)
        }
        allHeights+=200
        
        paletteView = IMPPaletteListView(frame: view.bounds)
        paletteView.wantsLayer = true
        paletteView.layer?.backgroundColor = IMPColor.clearColor().CGColor

        sview.addSubview(paletteView)

        paletteView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(histogramView.snp_bottom).offset(10)
            make.left.equalTo(sview).offset(10)
            make.right.equalTo(sview).offset(-10)
            make.height.equalTo(240)
        }
        allHeights+=240
        
    }
    
    override func viewDidLayout() {
        let h = view.bounds.height < allHeights ? allHeights+40 : view.bounds.height
        sview.snp_remakeConstraints { (make) -> Void in
            make.top.equalTo(pannelScrollView).offset(0)
            make.left.equalTo(pannelScrollView).offset(0)
            make.right.equalTo(pannelScrollView).offset(0)
            make.height.equalTo(h)
        }
        //paletteView.reloadData()
    }
}

