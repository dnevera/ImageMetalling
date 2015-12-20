//: Playground - noun: a place where people can play

import Cocoa
import Metal
import OpenGL.GL
import QuartzCore
import Accelerate
import simd.vector_types

enum IMPMenuTag:Int{
    case zoomeOne = 3004
    case zoom100  = 3005
}

if let i = IMPMenuTag(rawValue: 3004) {
    switch i {
    case .zoomeOne:
        print(i)
    default: break
    }
}


let s = "123 qwertf русский"
s.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
s.characters.count

let n = "123"
Int(n)
