//: Playground - noun: a place where people can play

import Cocoa
import Metal
import OpenGL.GL
import QuartzCore
import Accelerate
import simd.vector_types

let hsize   = 4
let grid    = int2(8,5)
let xoffset = Int(grid.x)%hsize
let size    = Int(grid.x*grid.y)


for var tid = 0; tid<hsize; tid++ {
    print("\(tid)")
    var s = ""
    for var i=0; i<size; i+=hsize {
        let gid = i+tid
        let x = gid%Int(grid.x)
        let y = gid/Int(grid.x)
        s += String(format: "[%2li,%2li],", x,y)
        if i%Int(grid.x) == Int(grid.x)-1 {
            s+="\n"
        }
    }
    print(s)
}


let device = MTLCreateSystemDefaultDevice()

print(" max threads \(device?.maxThreadsPerThreadgroup) ")

