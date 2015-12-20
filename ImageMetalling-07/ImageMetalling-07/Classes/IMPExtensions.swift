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

enum IMProcessing{
    struct names {
        static let prefix = "com.improcessing."
    }
}

extension IMPColor{
    convenience init(color:float4) {
        self.init(red: CGFloat(color.x), green: CGFloat(color.y), blue: CGFloat(color.z), alpha: CGFloat(color.w))
    }
}

extension float3{
    var r:Float{ set{ x = r } get{ return x } }
    var g:Float{ set{ y = g } get{ return y } }
    var b:Float{ set{ z = b } get{ return z } }
    init(color:IMPColor){
        self.init(Float(color.redComponent),Float(color.greenComponent),Float(color.blueComponent))
    }
    init(colors:[String]){
        self.init(colors[0].floatValue,colors[1].floatValue,colors[2].floatValue)
    }
}

extension float4{
    var r:Float{ set{ x = r } get{ return x } }
    var g:Float{ set{ y = g } get{ return y } }
    var b:Float{ set{ z = b } get{ return z } }
    var a:Float{ set{ w = a } get{ return w } }
    var rgb:float3 {
        set{
            x = rgb.x
            y = rgb.y
            z = rgb.z
        }
        get{
            return float3(x,y,z)
        }
    }
    init(rgb:float3,a:Float){
        self.init(rgb.x,rgb.y,rgb.z,a)
    }
    init(color:IMPColor){
        self.init(Float(color.redComponent),Float(color.greenComponent),Float(color.blueComponent),Float(color.alphaComponent))
    }
    init(colors:[String]){
        self.init(colors[0].floatValue,colors[1].floatValue,colors[2].floatValue,colors[3].floatValue)
    }
}

func / (left:float3,right:Float) -> float3 {
    return float3(left.x/right,left.y/right,left.z/right)
}

func / (left:float4,right:Float) -> float4 {
    return float4(left.x/right,left.y/right,left.z/right,left.w/right)
}

extension MTLSize{
    init(cgsize:CGSize){
        self.init(width: Int(cgsize.width), height: Int(cgsize.height), depth: 1)
    }
}

extension String {
    
    var floatValue: Float {
        return (self as NSString).floatValue
    }
    var intValue: Int {
        return (self as NSString).integerValue
    }
    var isNumeric: Bool {
        if Float(self) != nil {
            return true
        }
        else if Int(self) != nil {
            return true
        }
        return false
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

extension IMPBlendingMode{
    static let LUMNINOSITY = IMPBlendingMode(0)
    static let NORMAL      = IMPBlendingMode(1)
}


