//
//  IMPAliases.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa
import simd
import Metal

#if os(iOS)
    typealias IMPImage = UIImage
    typealias IMPColor = UIColor
#else
    typealias IMPImage = NSImage
    typealias IMPColor = NSColor
#endif

typealias IMPSize  = CGSize

extension IMPColor{
    convenience init(color:float4) {
        self.init(red: CGFloat(color.x), green: CGFloat(color.y), blue: CGFloat(color.z), alpha: CGFloat(color.w))
    }
}

extension MTLSize{
    init(cgsize:CGSize){
        self.init(width: Int(cgsize.width), height: Int(cgsize.height), depth: 1)
    }
}

func * (left:MTLSize,right:(Float,Float,Float)) -> MTLSize {
    return MTLSize(
        width: Int(Float(left.width)*right.0),
        height: Int(Float(left.height)*right.1),
        depth: Int(Float(left.height)*right.2))
}

func != (left:MTLSize,right:MTLSize) ->Bool {
    return (left.width != right.width && left.height != right.height && left.depth != right.depth)
}

func == (left:MTLSize,right:MTLSize) ->Bool {
    return !(left != right)
}


