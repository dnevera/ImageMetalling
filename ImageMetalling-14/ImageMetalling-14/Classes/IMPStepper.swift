//
//  IMPStepper.swift
//  ImageMetalling-14
//
//  Created by denis svinarchuk on 26.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Cocoa
import IMProcessing
import SnapKit

typealias IMPStepperCallback  = ((value:Float) -> Void)


class IMPStepper: NSView {
    
    var label:IMPLabel!
    var text:NSTextField!
    var stepper: NSStepper!
    var resetButton:NSButton!
    
    var action:IMPStepperCallback!
    
    var initialValue:Float = 0 {
        didSet{
            stepper.floatValue = initialValue
            textUpdate()
            self.callback(self.stepper)
        }
    }
    
    var defaultValue:Float = 0 {
        didSet{
            stepper.floatValue = defaultValue
            textUpdate()
            self.callback(self.stepper)
        }
    }
    
    init(title:String, initial:Float, defaultValue:Float, min:Float, max:Float, step:Float, frame:NSRect = NSRect(x: 0, y: 0, width: 300, height: 40),
         action:IMPStepperCallback){
        super.init(frame:frame)
        
        self.action = action
        
        initialValue = initial
        
        resetButton = NSButton(frame: NSRect(x: 230, y: 0, width: 50, height: bounds.height))
        resetButton.title = "Reset"
        resetButton.target = self
        resetButton.action = #selector(IMPStepper.resetCallback(_:))
        addSubview(resetButton)
        
        resetButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.right.equalTo(self).offset(-10)
            make.width.equalTo(60)
        }
        
        self.defaultValue  = defaultValue
        
        stepper = NSStepper(frame: NSRect(x: 210, y: 0, width: 20, height: bounds.height))
        stepper.maxValue = max.double
        stepper.minValue = min.double
        stepper.increment = step.double
        stepper.floatValue = initialValue
        stepper.target = self
        stepper.action = #selector(IMPStepper.callback(_:))
        addSubview(stepper)
        
        stepper.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.right.equalTo(resetButton.snp_left).offset(-10)
        }
        
        label  = IMPLabel(frame: NSRect(x: 0, y: 0, width: 100, height: bounds.height))
        addSubview(label)
        label.stringValue = title
        label.alignment = .Left
        label.maximumNumberOfLines = 1
        label.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.snp_left).offset(0)
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.width.equalTo(100)
        }
        
        text = NSTextField(frame: NSRect(x: 105, y: 0, width: 50, height: bounds.height))
        text.editable = false
        text.drawsBackground = false
        text.bezeled = false
        text.selectable = false
        text.bordered = false
        text.alignment = .Center
        text.textColor = IMPColor.lightGrayColor()
        
        initialValue = initial
        
        if step >= 1 {
            text.stringValue = String(format: "%5.0f",initialValue)
        }
        else{
            text.stringValue = String(format: "%3.4f",initialValue)
        }
        
        addSubview(text)
        text.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.snp_centerY).offset(0)
            make.right.equalTo(stepper.snp_left).offset(-10)
        }
    }
    
    func resetToValue(){
        stepper.floatValue = defaultValue
        textUpdate()
    }
    
    func reset(){
        self.stepper.floatValue = self.defaultValue
        self.callback(self.stepper)
    }
    
    func resetCallback(sender:NSButton){
        reset()
    }
    
    func textUpdate(){
        let value = self.stepper.floatValue
        
        if self.stepper.increment >= 1 {
            self.text.stringValue = String(format: "%5.0f",value)
        }
        else{
            self.text.stringValue = String(format: "%3.4f",value)
        }
    }
    
    func apply(){
        asyncChanges { () -> Void in
            self.textUpdate()
            self.action(value: self.stepper.floatValue)
        }
    }
    
    var value:Float = 0 {
        didSet{
            self.stepper.floatValue = value
            apply()
        }
    }
    
    func callback(sender:NSStepper){
        apply()
    }
    
    var q = dispatch_queue_create("IMPStepperCallback", DISPATCH_QUEUE_SERIAL)
    
    private func asyncChanges(block:()->Void) {
        dispatch_async(q, { () -> Void in
            dispatch_async( dispatch_get_main_queue(), { () -> Void in
                block()
            })
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}