//
//  IMPSlider.swift
//  DehancerEAPOSX
//
//  Created by denis svinarchuk on 07.01.16.
//  Copyright © 2016 dehancer.com. All rights reserved.
//

import Cocoa
import IMProcessing
import SnapKit

typealias IMPSliderCallback  = ((value:Float) -> Void)

public class IMPSlider: NSView {
    
    var label:IMPLabel!
    public var slider:NSSlider!
    
    var action:IMPSliderCallback!
    
    func __init__(){
    }
    
    init(title:String?, range:Range<Int>, initial:Int, frame:NSRect = NSRect(x: 0, y: 0, width: 100, height: 100), action:IMPSliderCallback){
        super.init(frame:frame)
        
        self.action = action
        
        if title != nil {
            label  = IMPLabel(frame: bounds)
            addSubview(label)
            label.stringValue = title!
            label.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(0)
                make.right.equalTo(self).offset(0)
                make.height.equalTo(20)
            }
        }
        
        slider = NSSlider(frame: bounds)
        slider.minValue = Double(range.startIndex)
        slider.maxValue = Double(range.endIndex)
        slider.integerValue = initial
        slider.target = self
        slider.action = #selector(IMPSlider.callback(_:))
        slider.continuous = true
        addSubview(slider)
        slider.snp_makeConstraints { (make) -> Void in
            if label != nil {
                make.top.equalTo(label.snp_bottom).offset(5)
            }
            else {
                make.top.equalTo(self).offset(5)
            }
            make.left.equalTo(self).offset(0)
            make.right.equalTo(self).offset(0)
            make.bottom.equalTo(self).offset(0)
        }
        
    }
    
    public var value:Float = 0 {
        didSet{
            asyncChanges { () -> Void in
                self.slider.integerValue = Int(self.value * 100)
                self.action(value: self.value)
            }
        }
    }
    
    func callback(sender:NSSlider){
        value = sender.floatValue/100
    }
    
    var q = dispatch_queue_create("IMPSliderCallback", DISPATCH_QUEUE_SERIAL)
    
    private func asyncChanges(block:()->Void) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            block()
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

