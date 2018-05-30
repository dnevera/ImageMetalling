//
//  MetalNode.swift
//  ImageMetalling-15
//
//  Created by denis svinarchuk on 25.05.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Cocoa
import Metal
import SceneKit
import IMProcessing

class MetalMeshData {
    
    var geometry:SCNGeometry
    var vertexBuffer1:MTLBuffer
    var vertexBuffer2:MTLBuffer
    var normalBuffer:MTLBuffer
    var vertexCount:Int
    
    init(
        geometry:SCNGeometry,
        vertexCount:Int,
        vertexBuffer1:MTLBuffer,
        vertexBuffer2:MTLBuffer,
        normalBuffer:MTLBuffer) {
        self.geometry = geometry
        self.vertexCount = vertexCount
        self.vertexBuffer1 = vertexBuffer1
        self.vertexBuffer2 = vertexBuffer2
        self.normalBuffer = normalBuffer
    }
    
}
