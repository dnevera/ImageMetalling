//
//  AppDelegate.swift
//  ImageMetalling-14
//
//  Created by denis svinarchuk on 16.05.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import AppKit
import IMProcessing
import IMProcessingUI
import ImageIO

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSOpenSavePanelDelegate {

    lazy var openPanel:NSOpenPanel = {
        let p = NSOpenPanel()
        p.canChooseFiles = true
        p.canChooseDirectories = false
        p.resolvesAliases = true
        p.isExtensionHidden = false
        p.allowedFileTypes = [
            "jpg", "JPEG", "TIFF", "TIF", "PNG", "JPG", "dng", "DNG", "CR2", "ORF"
        ]
        return p
    }()
    
    @IBAction func openFile(_ sender: NSMenuItem) {
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            if let path = openPanel.urls.first?.path {
                (NSApplication.shared.keyWindow?.contentViewController as? ViewController)?.imagePath = path
            }
        }
    }
    
}

