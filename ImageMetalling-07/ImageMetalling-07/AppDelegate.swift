//
//  AppDelegate.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 14.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import IMProcessing

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    private let openRecentKey = "imageMetalling-open-recent"
    
    private var openRecentMenuItems = Dictionary<String,NSMenuItem>()
    
    private func addOpenRecentMenuItemMenu(file:String){
        let menuItem = openRecentMenu.insertItemWithTitle(file, action: "openRecentHandler:", keyEquivalent: "", atIndex: 0)
        openRecentMenuItems[file]=menuItem
    }
    
    private var openRecentList:[String]?{
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey(openRecentKey) as? [String]
        }
    }

    
    private func addOpenRecentFileMenuItem(file:String){

        var list = removeOpenRecentFileMenuItem(file)
        
        list.insert(file, atIndex: 0)
        
        NSUserDefaults.standardUserDefaults().setObject(list, forKey: openRecentKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        addOpenRecentMenuItemMenu(file)
    }
    
    private func removeOpenRecentFileMenuItem(file:String) -> [String] {

        var list = openRecentList ?? [String]()
        
        if let index = list.indexOf(file){
            list.removeAtIndex(index)
            if let menuItem = openRecentMenuItems[file] {
                openRecentMenu.removeItem(menuItem)
            }
        }
        
        NSUserDefaults.standardUserDefaults().setObject(list, forKey: openRecentKey)
        NSUserDefaults.standardUserDefaults().synchronize()

        return list
    }
    
    private var recentListMenuItems:[NSMenuItem] = [NSMenuItem]()
    
    @IBOutlet weak var openRecentMenu: NSMenu!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        for w in NSApp.windows{
            w.backgroundColor = IMPColor(color: IMPPrefs.colors.background)
        }
        
        if let list = openRecentList {
            for file in list.reverse() {
                addOpenRecentMenuItemMenu(file)
            }
            IMPDocument.sharedInstance.currentFile = list[0]
        }
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    
    @IBAction func menuAction(sender: NSMenuItem) {
        IMPMenuHandler.sharedInstance.currentMenuItem = sender
    }
    
    
    @IBAction func clearRecentOpened(sender: AnyObject) {
        if let list = openRecentList {
            for file in list {
                removeOpenRecentFileMenuItem(file)
            }
        }
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
        addOpenRecentFileMenuItem(filePath)
    }
    
    private func openRecentListAdd(file:String){
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

