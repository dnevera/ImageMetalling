//
//  AppDelegate.swift
//  ImageMetalling-12
//
//  Created by denis svinarchuk on 12.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Cocoa
import IMProcessing
import simd

enum IMPPrefs{
    struct colors {
        static let background  = float4(x:0.1,y:0.1,z:0.1,w:1.0)
        static let toolbarColor  = float4(x:0.1,y:0.1,z:0.1,w:1.0)
        static let indentColor = float4(x:0.3,y:0.3,z:0.3,w:1.0)
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSToolbarDelegate{
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        for w in NSApp.windows{
            w.backgroundColor = IMPColor(color: IMPPrefs.colors.background)
        }
        IMPDocument.sharedInstance.openRecentMenu = openRecentMenu
    }


    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBOutlet weak var openRecentMenu: NSMenu!
    
    @IBAction func clearOpenRecent(sender: AnyObject) {
        IMPDocument.sharedInstance.clearRecent()
    }
    
    @IBAction func chooseMenuItem(sender: AnyObject) {
        IMPMenuHandler.sharedInstance.currentMenuItem = sender as? NSMenuItem
    }
    
    @IBAction func openFile(sender: AnyObject) {
        IMPDocument.sharedInstance.openFilePanel(["jpg", "jpeg"])
    }
    
    @IBAction func saveFile(sender: NSMenuItem) {
        
        let savePanel = NSSavePanel()
        savePanel.extensionHidden = false;
        savePanel.allowedFileTypes = ["jpg"]
        
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd-HH_mm_ss"
        dateFormat.stringFromDate(NSDate())
        
        savePanel.nameFieldStringValue = String(format: "improcessing-result-\(dateFormat.stringFromDate(NSDate())).jpg")
        let result = savePanel.runModal()
        
        if result == NSModalResponseOK {
            IMPDocument.sharedInstance.saveCurrent((savePanel.URL?.path)!)
        }
        else {
            print("\(result)")
        }
    }
    
    func openRecentHandler(sender:NSMenuItem){
        IMPDocument.sharedInstance.currentFile = sender.title
    }        
}

