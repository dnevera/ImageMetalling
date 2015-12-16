//
//  CGRect+IMProcessing.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Foundation

extension CGRect{
    var center:CGPoint{
        get{
            return CGPoint(x: origin.x + size.width * 0.5, y: origin.y + size.height * 0.5)
        }
        set {
            origin.x = newValue.x - size.width * 0.5
            origin.y = newValue.y - size.height * 0.5
        }
    }
}
