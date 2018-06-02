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

    var controller:ViewController! {
        return (NSApplication.shared.keyWindow?.contentViewController as? ViewController)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let view = controller?.view {
            view.window?.title = "LUT: Identity"
            view.addCursorRect(view.bounds, cursor: NSCursor.pointingHand  )
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor.darkGray.cgColor
        }
    }
    
    @IBAction func toggleRendering(_ sender: NSMenuItem) {
         controller.lutView.renderCube = !controller.lutView.renderCube 
    }
    
    @IBAction func showStatistics(_ sender: NSMenuItem) {
        controller.lutView.sceneView.showsStatistics = !controller.lutView.sceneView.showsStatistics
    }
    
    @IBAction func resetView(_ sender: NSMenuItem) {
        controller?.resetView()
    }    
    
    @IBAction func openLut(_ sender: NSMenuItem) {
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            if let url = openPanel.urls.first{
                controller?.lutUrl = url
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

