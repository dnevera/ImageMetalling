//
//  WindowController.swift
//  ImageMetalling-15
//
//  Created by denis svinarchuk on 24.05.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    
    private var restorationID:String {
        return  "MainWindowControllerID"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        windowFrameAutosaveName = NSWindow.FrameAutosaveName(rawValue: restorationID)
        window?.identifier = NSUserInterfaceItemIdentifier(rawValue: restorationID)
        if let w = window {
            contentViewController?.view.setFrameSize(w.contentRect(forFrameRect: w.frame).size)
        }
    }
    
}
