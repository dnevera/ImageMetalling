//
//  IMPDocument.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import IMProcessing

public enum IMPDocumentType{
    case Image
    case LUT
}

public typealias IMPDocumentObserver = ((file:String, type:IMPDocumentType) -> Void)

public class IMPDocument: NSObject {
    
    private override init() {}
    private var didUpdateDocumnetHandlers = [IMPDocumentObserver]()
    
    static let sharedInstance = IMPDocument()
    
    var currentFile:String?{
        didSet{
            
            addOpenRecentFileMenuItem(currentFile!)
            
            for o in self.didUpdateDocumnetHandlers{
                o(file: currentFile!, type: .Image)
            }
        }
    }
    
    func addDocumentObserver(observer:IMPDocumentObserver){
        didUpdateDocumnetHandlers.append(observer)
    }
    
    func saveCurrent(filename:String){
        if let cf = currentFile{
            addOpenRecentFileMenuItem(cf)
        }
    }
    
    private let openRecentKey = "imageMetalling-open-recent"
    
    private var openRecentMenuItems = Dictionary<String,NSMenuItem>()
    
    public weak var openRecentMenu: NSMenu! {
        didSet{
            if let list = openRecentList {
                if list.count>0{
                    for file in list.reverse() {
                        addOpenRecentMenuItemMenu(file)
                    }
                    IMPDocument.sharedInstance.currentFile = list[0]
                }
            }
        }
    }
    
    public func clearRecent(){
        if let list = openRecentList {
            for file in list {
                removeOpenRecentFileMenuItem(file)
            }
        }
    }
    
    public func openRecentListAdd(urls:[NSURL]){
        for url in urls{
            if let file = url.path{
                self.addOpenRecentFileMenuItem(file)
            }
        }
    }
    
    private func addOpenRecentMenuItemMenu(file:String){
        if let menu = openRecentMenu {
            let menuItem = menu.insertItemWithTitle(file, action: Selector("openRecentHandler:"), keyEquivalent: "", atIndex: 0)
            openRecentMenuItems[file]=menuItem
        }
    }
    
    private func openFilePath(filePath: String){
        currentFile = filePath
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
    
    var currentLutFile:String?{
        didSet{
            for o in self.didUpdateDocumnetHandlers{
                o(file: currentLutFile!, type: .LUT)
            }
        }
    }
    
    public func openFilePanel(types:[String]){
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseFiles  = true;
        openPanel.resolvesAliases = true;
        openPanel.extensionHidden = false;
        openPanel.allowedFileTypes = ["jpg", "tif", "tiff", "png"]
        
        let result = openPanel.runModal()
        
        if result == NSModalResponseOK {
            IMPDocument.sharedInstance.currentFile = openPanel.URLs[0].path
        }
    }
    
    public func openLutPanel(){
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseFiles  = true;
        openPanel.resolvesAliases = true;
        openPanel.extensionHidden = false;
        openPanel.allowedFileTypes = ["cube", "CUBE", "Cube"]
        
        let result = openPanel.runModal()
        
        if result == NSModalResponseOK {
            IMPDocument.sharedInstance.currentLutFile=openPanel.URLs[0].path
        }
    }
}

