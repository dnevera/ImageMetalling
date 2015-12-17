//: Playground - noun: a place where people can play

import Cocoa
import Metal
import OpenGL.GL
import QuartzCore
import Accelerate
//import MetalPerformanceShaders


func createIntensityDistribution(size:Int) -> (Int,[Float]){
    let m:Float    = Float(size-1)
    var h:[Float]  = [Float](count: size, repeatedValue: 0)
    var zero:Float = 0
    var v:Float    = 1.0/m
    //
    // Создает вектор с монотонно возрастающими или убывающими значениями
    //
    vDSP_vramp(&zero, &v, &h, 1, vDSP_Length(size))
    return (size,h);
}

let vh = createIntensityDistribution(256)
vh.0
vh.1

var str = "Hello, playground"

func testClosure(closure: (value:Int)->Void ){
    for i in 0...5{
        closure(value: i)
    }
}

testClosure { (value) -> Void in
    print(" *** value = \(value)")
}


let device = MTLCreateSystemDefaultDevice()

print(" *** MTL device \(device)")

var size:Int32 = 0

var pixelAttributes:[NSOpenGLPixelFormatAttribute] = [UInt32(NSOpenGLPFADoubleBuffer), UInt32(NSOpenGLPFAAccelerated), 0]
var pixelFormat = NSOpenGLPixelFormat(attributes: &pixelAttributes)
var processingContext = NSOpenGLContext(format: pixelFormat!, shareContext: nil)


processingContext?.makeCurrentContext()

glGetIntegerv(GLenum(GL_MAX_TEXTURE_SIZE), &size)

print(" *** device size = \(size)")


typealias DisplayLinkCallback = @convention(block) ( CVDisplayLink!, UnsafePointer<CVTimeStamp>, UnsafePointer<CVTimeStamp>, CVOptionFlags, UnsafeMutablePointer<CVOptionFlags>, UnsafeMutablePointer<Void>)->Void

func DisplayLinkSetOutputCallback( displayLink:CVDisplayLink, callback:DisplayLinkCallback )
{
    let block:DisplayLinkCallback = callback
    let myImp = imp_implementationWithBlock( unsafeBitCast( block, AnyObject.self ) )
    let callback = unsafeBitCast( myImp, CVDisplayLinkOutputCallback.self )
    
    CVDisplayLinkSetOutputCallback( displayLink, callback, UnsafeMutablePointer<Void>() )
}


let dl:CVDisplayLink = {
    var linkRef:CVDisplayLink?
    CVDisplayLinkCreateWithActiveCGDisplays( &linkRef )
    
    return linkRef!
}()

var u = 0
var tm = time(nil)

let callback = { (
    _:CVDisplayLink!,
    _:UnsafePointer<CVTimeStamp>,
    _:UnsafePointer<CVTimeStamp>,
    _:CVOptionFlags,
    _:UnsafeMutablePointer<CVOptionFlags>,
    _:UnsafeMutablePointer<Void>)->Void in
    
    print("yep -> \(u, time(nil), tm - time(nil))")
    if time(nil) - tm > 0{
        tm = time(nil)
        u=0
    }
    u++
    
}

DisplayLinkSetOutputCallback( dl, callback: callback )

//CVDisplayLinkStart( dl )

//NSRunLoop.mainRunLoop().run()

//sleep(1)

//CVDisplayLinkStop( dl )

