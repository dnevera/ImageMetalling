//
//  AppDelegate.swift
//  ImageMetalling-15
//
//  Created by denis svinarchuk on 24.05.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBAction func resetView(_ sender: NSMenuItem) {(NSApplication.shared.keyWindow?.contentViewController as? ViewController)?.resetView()
    }    
    
    @IBAction func openLut(_ sender: NSMenuItem) {
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            if let url = openPanel.urls.first{
                (NSApplication.shared.keyWindow?.contentViewController as? ViewController)?.lutUrl = url
            }
        }
    }
    
    lazy var openPanel:NSOpenPanel = {
        let p = NSOpenPanel()
        p.canChooseFiles = true
        p.canChooseDirectories = false
        p.resolvesAliases = true
        p.isExtensionHidden = false
        p.allowedFileTypes = [
            "cube", "png"
        ]
        return p
    }()

}

