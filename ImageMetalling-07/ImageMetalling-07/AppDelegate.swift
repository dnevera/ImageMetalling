//
//  AppDelegate.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 14.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let openRecentKey = "imageMetalling-open-recent"
    private var openRecentList:[String]?{
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey(openRecentKey) as? [String]
        }
    }
    
    @IBOutlet weak var openRecentMenu: NSMenu!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        if let list = self.openRecentList{
            for file in list{
                self.appendOpenRecent(file)
            }
            self.openFilePath(list[0])
        }
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func openFile(sender: AnyObject) {
        
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseFiles  = true;
        openPanel.resolvesAliases = true;
        openPanel.extensionHidden = false;
        openPanel.allowedFileTypes = ["jpg", "tiff", "png"]
        
        let result = openPanel.runModal()
        
        if result == NSModalResponseOK {
            self.openRecentListAdd(openPanel.URLs)
        }
    }
    
    func openRecentHandler(sender:NSMenuItem){
        self.openFilePath(sender.title)
    }
    
    private func openFilePath(filePath: String){
        IMPDocument.sharedInstance.currentFile = filePath
    }
    
    private func appendOpenRecent(file:String){
        
        var list = self.openRecentList ?? [String]()
        
        if list.contains(file) == false {
            list.append(file)
            
            NSUserDefaults.standardUserDefaults().setObject(list as NSArray, forKey: openRecentKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        let newRecentItem = NSMenuItem(title: file, action: "openRecentHandler:" , keyEquivalent: "");
        newRecentItem.enabled = true
        openRecentMenu.addItem(newRecentItem)
    }
    
    private func openRecentListAdd(file:String){
        self.appendOpenRecent(file)
        self.openFilePath(file)
    }
    
    private func openRecentListAdd(urls:[NSURL]){
        for url in urls{
            if let file = url.path{
                self.openRecentListAdd(file)
            }
        }
    }
}

