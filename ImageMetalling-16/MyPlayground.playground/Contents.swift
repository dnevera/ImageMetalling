//: Playground - noun: a place where people can play

import Cocoa
import simd

var v = float2(5,2)
var m = float2(1,2)

var vm = float2x2(columns: (v, float2(0)))
var mm = float2x2(rows: [m, float2(0)])

let f = vm*mm
print(f)
f[0]
f[1]
f.inverse
f.transpose
