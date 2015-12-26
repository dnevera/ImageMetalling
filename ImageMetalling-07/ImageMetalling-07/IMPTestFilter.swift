//
//  IMPTestFilter.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 19.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import IMProcessing


class IMPTestFilter:IMPFilter {
    
    var hsvFilter:IMPHSVFilter!
    
    required init(context: IMPContext) {        
        super.init(context: context)
        hsvFilter = IMPHSVFilter(context: context, optimization: .NORMAL)
        addFilter(hsvFilter)                
    }
    
    var redraw: (()->Void)?
}
