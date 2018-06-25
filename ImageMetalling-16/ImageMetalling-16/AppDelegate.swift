//
//  AppDelegate.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 06.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var controller:ViewController! {
        return (NSApplication.shared.keyWindow?.contentViewController as? ViewController)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
                
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            guard self.controller != nil else {
                return
            }

            if self.controller.plane01GridView.mlsKind  == .affine {
                self.affineItem.state = .on
            }
            else if self.controller.plane01GridView.mlsKind  == .similarity {
                self.singularityItem.state = .on
            } 
            else if self.controller.plane01GridView.mlsKind  == .rigid {
                self.rigidItem.state = .on
            }   
            
            if self.controller.plane01GridView.solverLang  == .cpp {
                self.cpp.state = .on
            } 
            else if self.controller.plane01GridView.solverLang  == .metal {
                self.metal.state = .on
            }   
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
       
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBOutlet weak var affineItem: NSMenuItem!
    @IBOutlet weak var singularityItem: NSMenuItem!    
    @IBOutlet weak var rigidItem: NSMenuItem!
    
    @IBOutlet weak var swift: NSMenuItem!    
    @IBOutlet weak var cpp: NSMenuItem!    
    @IBOutlet weak var metal: NSMenuItem!
    
    lazy var items: [NSMenuItem] = [self.affineItem, self.singularityItem, self.rigidItem] 
    lazy var langItems: [NSMenuItem] = [self.swift, self.cpp, self.metal] 
    
    @IBAction func reset(_ sender: NSMenuItem) {

        controller?.plane01GridView.knotsGrid.reset()        
        controller?.plane01GridView.solverAlpha = 0.5

        controller?.plane12GridView.knotsGrid.reset()        
        controller?.plane12GridView.solverAlpha = 0.5

        controller?.alphaSlider.floatValue = controller.plane01GridView.solverAlpha 

        controller?.plane01GridView.updatePoints(updatePlane: true)
        controller?.plane12GridView.updatePoints(updatePlane: true)
    }
    
    @IBAction func toggleAffine(_ sender: NSMenuItem) {
        
        for m in items { m.state = .off }
        
        affineItem.state = .on
        controller?.plane01GridView.mlsKind = .affine
    }
    
    @IBAction func toggleSimilarity(_ sender: NSMenuItem) {
        for m in items { m.state = .off }
        singularityItem.state = .on
        controller?.plane01GridView.mlsKind = .similarity
        controller?.plane12GridView.mlsKind = .similarity
    }
    
    @IBAction func toggleRigid(_ sender: NSMenuItem) {
        for m in items { m.state = .off }
        rigidItem.state = .on
        controller?.plane01GridView.mlsKind = .rigid
        controller?.plane12GridView.mlsKind = .rigid
    }
    
    
    @IBAction func solveInMetal(_ sender: NSMenuItem) {
        for m in langItems { m.state = .off }
        metal.state = .on
        controller?.plane01GridView.solverLang = .metal
        controller?.plane12GridView.solverLang = .metal
    }
    
    @IBAction func solveInCpp(_ sender: NSMenuItem) {
        for m in langItems { m.state = .off }
        cpp.state = .on
        controller?.plane01GridView.solverLang = .cpp
        controller?.plane12GridView.solverLang = .cpp
    }
    
    
    @IBAction func pinEdges(_ sender: NSMenuItem) {
        controller?.plane01GridView.knotsGrid.pinEdges()
        controller?.plane12GridView.knotsGrid.pinEdges()
    }
    
    @IBAction func openFile(_ sender: NSMenuItem) {
        guard let controller = self.controller else {
            return
        }
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            if let url = openPanel.urls.first{
                controller.imageFile = url
            }
        }
    }
    
    @IBAction func saveImage(_ sender: NSMenuItem) {
        guard let controller = self.controller else {
            return
        }
        
        let p = NSSavePanel()
        p.isExtensionHidden = false
        p.allowedFileTypes = [
            "png", "jpg", "cr2", "tiff"
        ]
        
        p.nameFieldStringValue = ""
        
        if p.runModal() == NSApplication.ModalResponse.OK {
            if let url = p.url {
                controller.imageSavingFile = url
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
            "png", "jpg", "cr2", "tiff", "orf"
        ]
        return p
    }()
    
    lazy var savePanel:NSSavePanel = {
        let p = NSSavePanel()
        p.isExtensionHidden = false
        p.allowedFileTypes = [
            "png", "jpg", "cr2", "tiff"
        ]
        return p
    }()
}

