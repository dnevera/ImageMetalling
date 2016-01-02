//
//  IMPPaletteListView.swift
//  ImageMetalling-08
//
//  Created by denis svinarchuk on 02.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Cocoa
import IMProcessing

//class __IMPTextCenteredView:NSTextField {
//    func titleRectForBounds(frame:NSRect) {
//        
//        let stringHeight       = self.attributedStringValue.size().height
//        let titleRect          = super.titleRectForBounds(frame)
//        titleRect.origin.y = frame.origin.y +
//        (frame.size.height - stringHeight) / 2.0;
//        return titleRect;
//    }
//    - (void) drawInteriorWithFrame:(NSRect)cFrame inView:(NSView*)cView {
//    [super drawInteriorWithFrame:[self titleRectForBounds:cFrame] inView:cView];
//    }
//}

public class IMPPaletteListView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    
    var scrollView:NSScrollView!
    var colorListView:NSTableView!
    
    public var colorList:[float3] = [float3(0,0,0),float3(0.5,0.5,0.5),float3(1,1,1)]{
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
        
        scrollView.documentView = colorListView
        
        let column1 = NSTableColumn(identifier: "Color")
        let column2 = NSTableColumn(identifier: "Value")
        column1.width = 200
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
        return 40
    }
    
    public func tableView(tableView: NSTableView, willDisplayCell cell: AnyObject, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        (cell as! NSView).wantsLayer = true
        (cell as! NSView).layer?.backgroundColor = IMPColor.clearColor().CGColor
    }
    
    public func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var result:NSView?

        let color = IMPColor(color: float4(rgb: colorList[row], a: 1))

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
            let id = "Color"
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
            (result as! NSTextField).stringValue = " ## "
            (result as! NSTextField).textColor = color
        }
        
        let rowView = colorListView.rowViewAtRow(row, makeIfNecessary:false)
        rowView?.backgroundColor = IMPColor.clearColor()
        
        return result
    }
    
    override public func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        colorListView.reloadData()
        // Drawing code here.
    }
    
}
