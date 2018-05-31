//
//  ViewController.swift
//  ImageMetalling-15
//
//  Created by denis svinarchuk on 24.05.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Cocoa
import IMProcessing

class ViewController: NSViewController {

    @IBOutlet var lutView: LutView!
    
    let clockCursor = NSCursor(image: NSImage(named: NSImage.Name("clock"))!, hotSpot: NSPoint(x:9,y:9))
    
    override func viewDidLoad() {
        super.viewDidLoad() 
    }
                
    var lut:IMPCLut? {
        set { lutView.lut = newValue }
        get{ return lutView.lut }
    }
    
    var lutUrl:URL? {
        didSet{
            
            guard  let url = lutUrl else {
                return
            }            
            
            view.window?.title = url.lastPathComponent
                        
            let cursor = NSCursor.pointingHand
                        
            view.removeCursorRect(view.bounds, cursor: cursor)
            view.addCursorRect(view.bounds, cursor: clockCursor)
            
            DispatchQueue.global().async {
                do {
                    if url.pathExtension.hasSuffix("cube") {
                        self.lut = try IMPCLut(context: self.lutView.context, cube: url)
                    }
                    else if url.pathExtension.hasSuffix("png") {
                        self.lut = try IMPCLut(context: self.lutView.context, haldImage: url.path)
                    }
                }
                catch let error {
                    Swift.print(error)
                }
                
                DispatchQueue.main.async {
                    self.view.removeCursorRect(self.view.bounds, cursor: self.clockCursor)
                    self.view.addCursorRect(self.view.bounds, cursor: cursor)
                }
            }                      
        }
    }

    func resetView() {
        lutView.resetView()
    }
    
}

