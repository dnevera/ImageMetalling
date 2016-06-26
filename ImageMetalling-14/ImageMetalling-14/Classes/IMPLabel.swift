//
//  IMPLabel.swift
//  DehancerEAPOSX
//
//  Created by denis svinarchuk on 07.01.16.
//  Copyright © 2016 dehancer.com. All rights reserved.
//

import Cocoa
import IMProcessing
import SnapKit

class IMPLabel: NSTextField {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        drawsBackground = false
        bezeled = false
        editable = false
        alignment = .Center
        textColor = IMPColor.lightGrayColor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }    
}
