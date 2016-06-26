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
    private let normalEnableButton = NSButton()
    private let slider = NSSlider()

    lazy var shadowsStepper:IMPStepper = {
        let s = IMPStepper(title: "Shadows", initial: 5/100, defaultValue: 5/100, min: 0.01/100, max: 10/100, step: 0.1/100, action: { (value) in
            if let s = self.shadowsHandler {
                s(value:value)
            }
        })
        return s
    }()
    
  
    lazy var highlightsStepper:IMPStepper = {
        let s = IMPStepper(title: "Highlights", initial: 2/100, defaultValue: 2/100, min: 0.01/100, max: 10/100, step: 0.1/100, action: { (value) in
            if let s = self.highlightsHandler {
                s(value:value)
            }
        })
        return s
    }()
    
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
        
        normalEnableButton.attributedTitle = NSAttributedString(string: "Normal/Luma", attributes: attributes)
        normalEnableButton.setButtonType(.SwitchButton)
        normalEnableButton.state = 0
        
        normalEnableButton.target = self
        normalEnableButton.action = #selector(self.enableNormalFilter(_:))
        addSubview(normalEnableButton)
        
        normalEnableButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.left.equalTo(separator.snp_right).offset(swidth)
            //make.width.equalTo(200)
        }
        
        separator = IMPSeparator()
        addSubview(separator)
        
        separator.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.width.equalTo(1)
            make.height.equalTo(30)
            make.left.equalTo(normalEnableButton.snp_right).offset(swidth)
        }
        
        slider.minValue = Double(0)
        slider.maxValue = Double(100)
        slider.integerValue = 100
        slider.target = self
        slider.action = #selector(self.slide(_:))
        slider.continuous = true
        slider.enabled = true
        
        addSubview(slider)
        slider.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.left.equalTo(separator.snp_right).offset(swidth)
            make.width.equalTo(200)
        }
        
        
        separator = IMPSeparator()
        addSubview(separator)
        
        separator.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.width.equalTo(1)
            make.height.equalTo(30)
            make.left.equalTo(slider.snp_right).offset(swidth)
        }
        
        addSubview(shadowsStepper)
        
        shadowsStepper.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.width.equalTo(220)
            make.height.equalTo(80)
            make.left.equalTo(separator.snp_right).offset(swidth)
        }
        
        separator = IMPSeparator()
        addSubview(separator)
        
        separator.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.width.equalTo(1)
            make.height.equalTo(30)
            make.left.equalTo(shadowsStepper.snp_right).offset(swidth)
        }

        addSubview(highlightsStepper)
        
        highlightsStepper.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.width.equalTo(220)
            make.height.equalTo(80)
            make.left.equalTo(separator.snp_right).offset(swidth)
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
    
    @objc private func enableNormalFilter(sender:NSButton)  {
        if let handler = enableNormalHandler {
            handler(flag: Bool(sender.state))
        }
    }
    
    @objc private func slide(sender:NSSlider)  {
        if let handler = slideHandler {
            handler(step: sender.integerValue)
        }
    }
    
    @objc private func reset(sender:NSButton)  {
        if let handler = resetHandler {
            handler()
        }
    }
    
    public var shadowsHandler:((value:Float)->Void)? = nil
    public var highlightsHandler:((value:Float)->Void)? = nil

    
    public var enableFilterHandler:((flag:Bool)->Void)? = nil
    public var enableNormalHandler:((flag:Bool)->Void)? = nil
    public var slideHandler:((step:Int)->Void)? = nil
    public var resetHandler:(()->Void)? = nil
    
    public var shadows:Float = 0  {
        didSet {
            shadowsStepper.defaultValue = shadows
            shadowsStepper.initialValue = shadows
        }
    }
    
    public var highlights:Float = 0  {
        didSet {
            highlightsStepper.defaultValue = highlights
            highlightsStepper.initialValue = highlights
        }
    }
    
    public var enabledFilter:Bool {
        return Bool(enableFilterButton.state)
    }
 
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
