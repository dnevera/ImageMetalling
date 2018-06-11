//
//  WindowController.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 06.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
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
