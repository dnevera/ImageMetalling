//
//  MLSSolverProcessor.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Foundation
import IMProcessing

public class IMPMLSSolver:IMPContextProvider{
    public struct Controls {
        let p:[float2]
        let q:[float2]
        let kind:MLSSolverKind
        let alpha:Float
        
        public init(p: [float2], q: [float2], kind:MLSSolverKind = .affine, alpha:Float = 1.0){
            self.p = p
            self.q = q
            self.kind = kind
            self.alpha = alpha
        }
    }
    
    public var points:[float2] = []  {
        didSet{
            
            #if os(OSX)
            let options:MTLResourceOptions = [.storageModeShared]
            #else
            let options:MTLResourceOptions = [.storageModeShared]
            #endif
            
            _points = [float2](repeating: float2(0), count: points.count)
            
            let points_length = MemoryLayout<float2>.size * points.count

            inputPointsBuffer = context.device.makeBuffer(
                bytes: points,
                length: points_length,
                options: [])
            
            outputPointsBuffer = context.device.makeBuffer(length: points_length, options: options)       
        }
    }   
    //public var controls:Controls = Controls(p: [], q: []) 
    
    public let context: IMPContext
    
    public init(context:IMPContext, controls:Controls?=nil, complete:((_ points:[float2])->Void)? = nil){
        self.context = context
        defer {
            if let controls = controls {
                if controls.p.count == controls.q.count && controls.p.count > 0 && points.count > 0 {
                    process(controls: controls, complete: complete)
                }
            }
        }
    }  
    
    public func process(controls:Controls, complete:((_ points:[float2])->Void)?=nil) {
        
        guard controls.p.count == controls.q.count && controls.p.count > 0 && points.count > 0 else {
            complete?([])
            return
        }        
                
        context.execute(.async, complete: {             
            if let b = self.outputPointsBuffer {
                memcpy(&self._points, b.contents(), b.length)            
            }
            complete?(self._points)
        }) { (commandBuffer) in
            
            self.threadgroups.width = self.points.count                       

            let length = MemoryLayout<float2>.size * controls.p.count
            
            if self._points.count != self.points.count {
                self._points = [float2](repeating: float2(0), count: self.points.count)
            }
            
            if self.pBuffer?.length == length {
                memcpy(self.pBuffer?.contents(), controls.p, length)
                memcpy(self.qBuffer?.contents(), controls.q, length)
            }
            else {
                
                self.pBuffer = self.context.device.makeBuffer(
                    bytes: controls.p,
                    length: length,
                    options: [])
                
                self.qBuffer = self.context.device.makeBuffer(
                    bytes: controls.q,
                    length: length,
                    options: [])
                
            }
            
            guard let _pBuffer = self.pBuffer else { return }
            guard let _qBuffer = self.qBuffer else { return }
            guard let _i_pointsBuffer = self.inputPointsBuffer else { return }
            guard let _o_pointsBuffer = self.outputPointsBuffer else { return }
            
            let commandEncoder = self.function.commandEncoder(from: commandBuffer)            
            
            commandEncoder.setBuffer(_i_pointsBuffer, offset: 0, index: 0)
            commandEncoder.setBuffer(_o_pointsBuffer, offset: 0, index: 1)
            commandEncoder.setBuffer(_pBuffer, offset: 0, index: 2)
            commandEncoder.setBuffer(_qBuffer, offset: 0, index: 3)

            var count = controls.p.count
            commandEncoder.setBytes(&count, length: MemoryLayout.stride(ofValue: count), index: 4)

            var kind = controls.kind
            commandEncoder.setBytes(&kind, length: MemoryLayout.stride(ofValue: kind), index: 5)

            var alpha = controls.alpha
            commandEncoder.setBytes(&alpha, length: MemoryLayout.stride(ofValue: alpha), index: 6)

            commandEncoder.dispatchThreadgroups(self.threadgroups, threadsPerThreadgroup: self.threads)
            commandEncoder.endEncoding()            
        }   
    }
    
    
    private var _points:[float2] = []
    
    private lazy var function:IMPFunction = IMPFunction(context: self.context, kernelName: "kernel_mlsSolver")    
    private var maxThreads:Int{ return function.maxThreads }    
    private lazy var threads:MTLSize = {
        return MTLSize(width: 1, height: 1,depth: 1)
    }()   
    
    private var threadgroups = MTLSizeMake(1,1,1)    
    private lazy var pBuffer:MTLBuffer? = nil
    private lazy var qBuffer:MTLBuffer? = nil
    
    private lazy var inputPointsBuffer:MTLBuffer? = nil
    private lazy var outputPointsBuffer:MTLBuffer? = nil

}
