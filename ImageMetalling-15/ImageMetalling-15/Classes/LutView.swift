//
//  LutView.swift
//  ImageMetalling-15
//
//  Created by denis svinarchuk on 24.05.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Cocoa
import IMProcessing
import IMProcessingUI
import SceneKit

class LutView: SceneView, SCNSceneRendererDelegate {

    let resolution = 16

    let context = IMPContext() 

    lazy var lutMapper:IMPCLutMapper = {
        let lut = IMPCLutMapper(context: self.context)
        var colors:[float3] = []
        colorGrid{ rgb in
            colors.append(rgb)
        }
        lut.reference = colors       
        return lut
    }() 
        
    var isChanched = false
    var colors:[float3] = []
    var lut:IMPCLut? {
        didSet{
            do {
                guard let lut3d = try self.lut?.convert(to: .lut_3d, lutSize: 16) else { return }
                
                lutMapper.process(clut: lut3d) { (colors) in

                    self.colors = [float3](colors)
                                        
                    let p =  SCNMaterialProperty(contents: lut3d.texture as Any)
                    self.material.setValue(p, forKey: "lut3d")
                    
                    self.isChanched = true
                    
                    self.sceneView.sceneTime += 1            
                }   
            }
            catch let error {
                Swift.print("\(error)")
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        guard isChanched else { return }
        
        for (i,rgb) in colors.enumerated() /*meshGrid.enumerated()*/ {
            let p = meshGrid[i]
            let rgba = float4(rgb.r,rgb.g,rgb.b,1)
            p.color = NSColor(color: rgba)
        }     
        
        self.isChanched = false
    }
    
    override func configure(frame: CGRect) {
        super.configure(frame: frame)
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
                        
        scene.rootNode.addChildNode(meshNode)            
        
        do {
            lut = try IMPCLut(context: context, lutType: .lut_3d, lutSize: 16, format: .float)
        }
        catch let error {
            Swift.print("\(error)")
        }
        
        for c in cornerColors {
            let n = IMPSCNRgbPoint(color: c, radius: 0.05, type: .sphere)
            facetCornerNodes.append(n)
            _ = n.attach(to: meshNode)
        }
        
        for f in facetColors {
            
            if let i0 = facetCornerNodes.index(where: { return $0.color == f.0 }),
                let i1 = facetCornerNodes.index(where: { return $0.color == f.1 }) {
                
                let c0 = facetCornerNodes[i0]
                let c1 = facetCornerNodes[i1]
                let line = IMPSCNLine(parent: meshNode,
                                      v1: c0.position,
                                      v2: c1.position,
                                      color: f.0,
                                      endColor: f.1)
                meshNode.addChildNode(line)                
            }
            
            for n in self.meshGrid {
                self.meshNode.addChildNode(n)                        
            }                
        }
        
        meshGeometry.materials = [self.material]
    }    
    
    public override func constraintNode() -> SCNNode {
        return meshNode
    }
        
    lazy var meshGeometry:SCNGeometry = {
        let g = SCNSphere(radius: 2);
        return g
    }()
    
    lazy var meshNode:SCNNode = {
        let c = SCNNode(geometry: self.meshGeometry)
        c.position = SCNVector3(x: 0, y: 0, z: 0)
        c.scale = SCNVector3(0.5, 0.5, 0.5)     
        return c
    }()
    
    let cornerColors:[NSColor] = [
        NSColor(red: 1, green: 0, blue: 0, alpha: 1), // 0
        NSColor(red: 0, green: 1, blue: 0, alpha: 1), // 1
        NSColor(red: 0, green: 0, blue: 1, alpha: 1), // 2
        
        NSColor(red: 1, green: 1, blue: 0, alpha: 1), // 3
        NSColor(red: 0, green: 1, blue: 1, alpha: 1), // 4
        NSColor(red: 1, green: 0, blue: 1, alpha: 1), // 5
        
        NSColor(red: 1, green: 1, blue: 1, alpha: 1), // 6
        NSColor(red: 0, green: 0, blue: 0, alpha: 1), // 7
    ]
    
    lazy var facetColors:[(NSColor,NSColor)] = [
        (self.cornerColors[7],self.cornerColors[0]), // black -> red
        (self.cornerColors[7],self.cornerColors[1]), // black -> green
        (self.cornerColors[2],self.cornerColors[7]), // black -> blue
        
        (self.cornerColors[0],self.cornerColors[3]), // red -> yellow
        (self.cornerColors[5],self.cornerColors[0]), // red -> purple
        
        (self.cornerColors[1],self.cornerColors[3]), // green -> yellow
        (self.cornerColors[4],self.cornerColors[1]), // green -> cyan
        
        (self.cornerColors[2],self.cornerColors[4]), // blue -> cyan
        (self.cornerColors[2],self.cornerColors[5]), // blue -> purple
        
        (self.cornerColors[6],self.cornerColors[3]), // yellow -> white
        (self.cornerColors[4],self.cornerColors[6]), // purple -> white
        (self.cornerColors[5],self.cornerColors[6]), // purple -> white
        
    ]
              
    func colorGrid(exec:((_ rgb:float3)->Void)) {
        for r in 0..<resolution {
            for g in 0..<resolution {
                for b in 0..<resolution {                    
                    exec(float3(Float(r),Float(g),Float(b))/float3(Float(resolution-1)))
                }                
            }
        }
    }
    
    lazy var meshGrid:[IMPSCNRgbPoint] = {
        var grid = [IMPSCNRgbPoint] ()
        colorGrid{ rgb in
            let rgba = float4(rgb.r,rgb.g,rgb.b,1)
            let n = IMPSCNRgbPoint(color: NSColor(color:rgba), radius: 0.02, type: .sphere)
            grid.append(n)
        }
        return grid
    }() 
        
    var facetCornerNodes = [IMPSCNRgbPoint]()
    
    let program:SCNProgram = {
        let p = SCNProgram()
        p.vertexFunctionName   = "projectionVertex"
        p.fragmentFunctionName = "materialFragment"
        p.isOpaque = false;
        return p
    }()
    
    
    /// Создаем материал с текстурой логотипа
    lazy var material:SCNMaterial = {
        let m = SCNMaterial()
        m.program = self.program
        return m
    }()
}
