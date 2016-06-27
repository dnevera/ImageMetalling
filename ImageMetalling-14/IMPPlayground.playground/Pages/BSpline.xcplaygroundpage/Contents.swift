//: [Previous](@previous)

import Foundation
import simd
import Accelerate


public func * (left:float4x4, right:float4x3) -> float4x3 {
    var r = float4x3()
    for i in 0..<4{
        for j in 0..<3{
            r[i][j] = 0.0
            for k in 0..<4{
                r[i][j] += left[i][k] * right[k][j]
            }
        }
    }
    return r
}

let bSplineBasis = float4x4(rows: [
    float4(1/6, 4/6, 1/6, 0),
    float4(0,   4/6, 2/6, 0),
    float4(0,   2/6, 4/6, 0),
    float4(0,   1/6, 4/6, 1/6)
    ])

let m = float4x3(rows: [
    float4(1.0/6.0, 4.0/6.0, 1.0/6.0, 0.0),
    float4(0.0, 4.0/6.0, 2.0/6.0, 0.0 ),
    float4(0.0, 2.0/6.0, 4.0/6.0, 0.0 )
    ])


extension float4x4 {
    static let BSplineBasis = float4x4(rows: [
        float4(1/6, 4/6, 1/6, 0),
        float4(0,   4/6, 2/6, 0),
        float4(0,   2/6, 4/6, 0),
        float4(0,   1/6, 4/6, 1/6)
        ])
    static let BSpline = float4x4(rows: [
        float4( 1, -3, 3, 1),
        float4( 3, -6, 3, 0),
        float4(-3,  0, 3, 0),
        float4( 1,  4, 1, 0)
        ])
}


extension _ArrayType where Generator.Element == Float {
    public func bSpline(controls:[float2])-> [Float] {
        var cpts = controls
        
        if cpts.count < 4 {
            fatalError("bSpline(controls:[float2]) must have at least 4 points")
        }
        
        var curve = [Float]()
        for i in 0..<controls.count-3 {
            let p0 = controls[i]
            let p1 = controls[i+1]
            let p2 = controls[i+2]
            let v = float4x3(rows: [
                float4(p0.x, p0.y, 0, 0),
                float4(p1.x, p1.y, 0, 0),
                float4(p2.x, p2.y, 0, 0)
                ])
            
        }
        return curve
    }
}