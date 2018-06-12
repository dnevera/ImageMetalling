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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { 
            if self.controller.gridView.mlsKind  == .affine {
                self.affineItem.state = .on
            }
            else if self.controller.gridView.mlsKind  == .similarity {
                self.singularityItem.state = .on
            } 
            else if self.controller.gridView.mlsKind  == .rigid {
                self.rigidItem.state = .on
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
    
    lazy var items: [NSMenuItem] = [self.affineItem, self.singularityItem, self.rigidItem] 
    
    @IBAction func reset(_ sender: NSMenuItem) {
        controller.gridView.knotsGrid.reset()
    }
    
    @IBAction func toggleAffine(_ sender: NSMenuItem) {
        
        for m in items { m.state = .off }
        
        affineItem.state = .on
        controller.gridView.mlsKind = .affine
    }
    
    @IBAction func toggleSimilarity(_ sender: NSMenuItem) {
        for m in items { m.state = .off }
        singularityItem.state = .on
        controller.gridView.mlsKind = .similarity
    }
    
    @IBAction func toggleRigid(_ sender: NSMenuItem) {
        for m in items { m.state = .off }
        rigidItem.state = .on
        controller.gridView.mlsKind = .rigid
    }
    
}

