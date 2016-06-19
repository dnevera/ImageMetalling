//
//  IMPToolBar.swift
//  ImageMetalling-12
//
//  Created by denis svinarchuk on 17.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Cocoa
import IMProcessing
import SnapKit

//
// Всякая UI - шелуха 
//


class IMPSeparator: NSView {
    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 1, height: 40))
        self.wantsLayer = true
        var rgba = IMPPrefs.colors.indentColor
        rgba.a = 0.65
        self.layer?.backgroundColor = IMPColor(rgba:rgba).CGColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class IMPToolBar: NSView {
    
    private let enableFilterButton = NSButton()
    private let aspectRatioButton = NSButton()
    private let gridButton = NSButton()
    private let gridSlider = NSSlider()

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.borderWidth = 0.5
        var rgba = IMPPrefs.colors.indentColor
        rgba.a = 0.65
        self.layer?.borderColor = IMPColor(rgba:rgba).CGColor
        self.layer?.backgroundColor = IMPColor(rgba:IMPPrefs.colors.toolbarColor).CGColor
        
        let swidth = 15
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .Center
        
        let attributes = [ NSForegroundColorAttributeName : IMPColor.grayColor(), NSParagraphStyleAttributeName : pstyle ]
        
        enableFilterButton.attributedTitle = NSAttributedString(string: "After/Before", attributes: attributes)
        enableFilterButton.setButtonType(.SwitchButton)
        enableFilterButton.state = 1
        
        
        enableFilterButton.target = self
        enableFilterButton.action = #selector(self.enableFilter(_:))
        addSubview(enableFilterButton)
        
        enableFilterButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.left.equalTo(self.snp_left).offset(swidth)
        }
        
        var separator = IMPSeparator()
        addSubview(separator)
        
        separator.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.width.equalTo(1)
            make.height.equalTo(30)
            make.left.equalTo(enableFilterButton.snp_right).offset(swidth)
        }
        
        aspectRatioButton.attributedTitle = NSAttributedString(string: "Keep aspect ratio", attributes: attributes)
        aspectRatioButton.setButtonType(.SwitchButton)
        aspectRatioButton.state = 0
        
        aspectRatioButton.target = self
        aspectRatioButton.action = #selector(self.enableAspectRatio(_:))
        addSubview(aspectRatioButton)
        
        aspectRatioButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.left.equalTo(separator.snp_right).offset(10)
        }
        
        separator = IMPSeparator()
        addSubview(separator)
        
        separator.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.width.equalTo(1)
            make.height.equalTo(30)
            make.left.equalTo(aspectRatioButton.snp_right).offset(swidth)
        }
        
        gridButton.attributedTitle = NSAttributedString(string: "Grid", attributes: attributes)
        gridButton.setButtonType(.SwitchButton)
        gridButton.state = 1
        
        gridButton.target = self
        gridButton.action = #selector(self.enableGrid(_:))
        addSubview(gridButton)
        
        gridButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.left.equalTo(separator.snp_right).offset(swidth)
        }
        
        gridSlider.minValue = Double(0)
        gridSlider.maxValue = Double(100)
        gridSlider.integerValue = 50
        gridSlider.target = self
        gridSlider.action = #selector(self.slide(_:))
        gridSlider.continuous = true
        gridSlider.enabled = Bool(gridButton.state)
        
        addSubview(gridSlider)
        gridSlider.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.left.equalTo(gridButton.snp_right).offset(swidth)
            make.width.equalTo(200)
        }
        
        
        let resetButton = NSButton()
        resetButton.wantsLayer = true
        resetButton.layer?.backgroundColor = IMPColor.clearColor().CGColor
        resetButton.image = NSImage(named:"Undo")
        resetButton.bordered = false
        resetButton.toolTip = "Reset"
        
        resetButton.target = self
        resetButton.action = #selector(self.reset(_:))
        addSubview(resetButton)
        
        resetButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.right.equalTo(self.snp_right).offset(-swidth)
        }
    }
    
    @objc private func enableFilter(sender:NSButton)  {
        if let handler = enableFilterHandler {
            handler(flag: Bool(sender.state))
        }
    }
    
    @objc private func enableAspectRatio(sender:NSButton)  {
        if let handler = enableAspectRatioHandler {
            handler(flag: Bool(sender.state))
        }
    }
    
    @objc private func enableGrid(sender:NSButton)  {
        if sender.state == 1 {
            gridSlider.enabled = true
        }
        else {
            gridSlider.enabled = false
        }
        if let handler = enableGridHandler {
            handler(flag: Bool(sender.state))
        }
    }
    
    @objc private func slide(sender:NSSlider)  {
        if let handler = gridSizeHendler {
            handler(step: sender.integerValue)
        }
    }
    
    @objc private func reset(sender:NSButton)  {
        if let handler = resetHandler {
            handler()
        }
    }
    
    
    public var enableFilterHandler:((flag:Bool)->Void)? = nil
    public var enableGridHandler:((flag:Bool)->Void)? = nil
    public var enableAspectRatioHandler:((flag:Bool)->Void)? = nil
    public var gridSizeHendler:((step:Int)->Void)? = nil
    public var resetHandler:(()->Void)? = nil
    
    public var enabledFilter:Bool {
        return Bool(enableFilterButton.state)
    }
    
    public var enabledAspectRatio:Bool {
        return Bool(aspectRatioButton.state)
    }
    
    public var enabledGrid:Bool {
        return Bool(gridButton.state)
    }
    
    public var gridSize:Int {
        set{
            dispatch_async(dispatch_get_main_queue()) {
                self.gridSlider.integerValue = newValue
                if let handler = self.gridSizeHendler {
                    handler(step: newValue)
                }
            }
        }
        get{
            return gridSlider.integerValue
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
