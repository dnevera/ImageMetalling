//: Playground - noun: a place where people can play

import Cocoa
import simd
import Accelerate

public extension Float{
    
    ///  Create linear range X points within range
    ///
    ///  - parameter r: range
    ///
    ///  - returns: X list
    static func range(r:Range<Int>) -> [Float]{
        return range(start: Float(r.startIndex), step: 1, end: Float(r.endIndex))
    }
    
    
    ///  Create linear range X points within range scaled to particular value
    ///
    ///  - parameter r: range
    ///
    ///  - returns: X list
    static func range(r:Range<Int>, scale:Float) -> [Float]{
        var r = range(start: Float(r.startIndex), step: 1, end: Float(r.endIndex))
        var denom:Float = 0
        vDSP_maxv(r, 1, &denom, vDSP_Length(r.count))
        denom /= scale
        vDSP_vsdiv(r, 1, &denom, &r, 1, vDSP_Length(r.count))
        return r
    }
    
    
    ///  Create linear range X points within range of start/end with certain step
    ///
    ///  - parameter start: start value
    ///  - parameter step:  step, must be less then end-start
    ///  - parameter end:   end, must be great the start
    ///
    ///  - returns: X list
    static func range(start start:Float, step:Float, end:Float) -> [Float] {
        let size       = Int((end-start)/step)
        
        var h:[Float]  = [Float](count: size, repeatedValue: 0)
        var zero:Float = start
        var v:Float    = step
        
        vDSP_vramp(&zero, &v, &h, 1, vDSP_Length(size))
        
        return h
        
    }
}

// MARK: - Bezier cubic splines
public extension Float {
    
    func cubicBesierFunction(c1 c1:float2, c2:float2) -> Float{
        
        let x = self
        
        let x0a:Float = 0
        let y0a:Float = 0
        let x3a:Float = 1
        let y3a:Float = 1

        let x1a:Float = c1.x
        let y1a:Float = c1.y
        let x2a:Float = c2.x
        let y2a:Float = c2.y

        let A =   x3a - 3*x2a + 3*x1a - x0a
        let B = 3*x2a - 6*x1a + 3*x0a
        let C = 3*x1a - 3*x0a
        let D =   x0a
        
        let E =   y3a - 3*y2a + 3*y1a - y0a
        let F = 3*y2a - 6*y1a + 3*y0a
        let G = 3*y1a - 3*y0a
        let H =   y0a
        
        var currentt = x
        let nRefinementIterations = 5
        
        for _ in 0..<nRefinementIterations{
            let currentx = valueFromT (currentt, A:A, B:B, C:C, D:D)
            currentt -= (currentx - x)*(slopeFromT (currentt, A: A,B: B,C: C));
            currentt = currentt < 0 ? 0 : currentt > 1 ? 1: currentt
        }
        
        return valueFromT (currentt,  A:E, B:F , C:G, D:H)
    }
    
    func slopeFromT (t:Float, A:Float, B:Float, C:Float) -> Float {
        return 1.0/(3.0*A*t*t + 2.0*B*t + C)
    }
    
    func valueFromT (t:Float, A:Float, B:Float, C:Float, D:Float) -> Float {
        return  A*(t*t*t) + B*(t*t) + C*t + D
    }
}

public extension CollectionType where Generator.Element == Float {
    public func cubicBezierSpline(c1 c1:float2, c2:float2)-> [Float]{
        var curve = [Float]()
        for x in self {
            curve.append(x.cubicBesierFunction(c1: c1, c2: c2))
        }
        return curve
    }
}



public class Splines {
    
    public static let scale:Float    = 1
    public static let minValue:Float = 0
    public static let maxValue:Float = 1
    public static let defaultControls = [float2(minValue,minValue),float2(maxValue-0.2,maxValue)]
    public static let defaultRange    = Float.range(start: 0, step: 1/256, end: 1)
    public static let defaultCurve    = defaultRange.cubicBezierSpline(c1: Splines.defaultControls[0], c2: Splines.defaultControls[1]) as [Float]
}

let c=Splines.defaultCurve

for i in c {
    let x=i
}
