//
//  IMPPaletteListView.swift
//  ImageMetalling-08
//
//  Created by denis svinarchuk on 02.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Cocoa
import IMProcessing

public class IMPPaletteListView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    
    var scrollView:NSScrollView!
    var colorListView:NSTableView!
    
    public var colorList:[IMPColor] = [
        IMPColor(red: 0, green: 0, blue: 0, alpha: 1),
        IMPColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1),
        IMPColor(red: 1, green: 1, blue: 1, alpha: 1),
        ]{
        didSet{
            colorListView.reloadData()
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        scrollView = NSScrollView(frame: self.bounds)
        scrollView.drawsBackground = false
        scrollView.allowsMagnification = false
        scrollView.autoresizingMask = [.ViewHeightSizable, .ViewWidthSizable]

        colorListView = NSTableView(frame: self.bounds)
        colorListView.backgroundColor = IMPColor.clearColor()
        colorListView.headerView = nil
        colorListView.intercellSpacing = IMPSize(width: 5,height: 5)
        colorListView.columnAutoresizingStyle = .UniformColumnAutoresizingStyle
        
        scrollView.documentView = colorListView
        
        let column1 = NSTableColumn(identifier: "Color")
        let column2 = NSTableColumn(identifier: "Value")
        column1.width = 300
        column2.width = 200
        column1.title = ""
        column2.title = "Value"
        colorListView.addTableColumn(column1)
        colorListView.addTableColumn(column2)
        
        colorListView.setDataSource(self)
        colorListView.setDelegate(self)
        
        self.addSubview(scrollView)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return colorList.count
    }
    
    public func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 36
    }
    
    public func tableView(tableView: NSTableView, willDisplayCell cell: AnyObject, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        (cell as! NSView).wantsLayer = true
        (cell as! NSView).layer?.backgroundColor = IMPColor.clearColor().CGColor
    }
    
    public func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var result:NSView?

        let color = colorList[row]

        if tableColumn?.identifier == "Color"{
            let id = "Color"
            result = tableView.makeViewWithIdentifier(id, owner: self)
            if result == nil {
                result = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 40))
                result?.wantsLayer = true
                result?.identifier = id
            }
            result?.layer?.backgroundColor = color.CGColor
        }
        else{
            let id = "Value"
            result = tableView.makeViewWithIdentifier(id, owner: self) as? NSTextField
            if result == nil {
                result = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 40))

                (result as? NSTextField)?.bezeled = false
                (result as? NSTextField)?.drawsBackground = false
                (result as? NSTextField)?.editable  = false
                (result as? NSTextField)?.selectable = true
                (result as? NSTextField)?.alignment  = .Right
                
                result?.identifier = id
            }
            let rgb = color.rgb * 255
            (result as! NSTextField).stringValue = String(format: "[%.0f,%.0f,%.0f]", rgb.r,rgb.g,rgb.b)
            (result as! NSTextField).textColor = color * 2
        }
        
        let rowView = colorListView.rowViewAtRow(row, makeIfNecessary:false)
        rowView?.backgroundColor = IMPColor.clearColor()
        
        return result
    }
    
    public func reloadData(){
        colorListView.sizeLastColumnToFit()
        colorListView.reloadData()
    }
    
    override public func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        self.reloadData()
        // Drawing code here.
    }
    
}
