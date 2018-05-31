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

///
/// Рендеринг сцены RGB-куба в SCNView в соответствии с вубранным LUT
///
class LutView: SceneView, SCNSceneRendererDelegate {

    /// Количество узловых точек грида RGB-куба в сцене
    let resolution = 16

    /// Контекст GPU
    let context = IMPContext() 

    ///
    /// Функтор интерполяции массива исходных цветов в целевые по текстуре LUT-a
    ///
    lazy var lutMapper:IMPCLutMapper = {
        let lut = IMPCLutMapper(context: self.context)
        var colors:[float3] = []
        colorGrid{ rgb in
            colors.append(rgb)
        }
        lut.reference = colors       
        return lut
    }() 
        
    var isChanged = false
    
    /// Текцщая карта грида RGB-куба в узловых точках
    var colors:[float3] = []
    
    /// 
    /// В приложении выбираем LUT из файла в одном из форматов hald-image (png),
    /// Adobe Cube: 1D, 2D, 3D
    ///
    var lut:IMPCLut? {
        didSet{
            do {
                /// всегда конвертируем в 3D
                guard let lut3d = try self.lut?.convert(to: .lut_3d, lutSize: 16) else { return }
                
                ///
                /// Интерполируем LUT в для новых узловых точек.
                /// Интерполяция запускается на GPU, в случае разрещения 16x16x16 
                /// нам нужно просчитать 4096 новых точек, что не много, но уже напряжно для CPU.                
                ///
                lutMapper.process(clut: lut3d) { (colors) in

                    self.colors = [float3](colors)
                    
                    /// после окончания расчета узловых точек выставляем лут для материала 
                    let p =  SCNMaterialProperty(contents: lut3d.texture as Any)
                    self.material.setValue(p, forKey: "lut3d")
                    
                    self.isChanged = true
                    
                    /// запускаем новый шаг рендеренг сцены принудительно
                    self.sceneView.sceneTime += 1            
                }   
            }
            catch let error {
                Swift.print("\(error)")
            }
        }
    }
    
    /// Программируем рендеринг материала в GPU на Metal
    let program:SCNProgram = {
        let p = SCNProgram()
        p.vertexFunctionName   = "projectionVertex"
        p.fragmentFunctionName = "materialFragment"
        p.isOpaque = false;                
        return p
    }()
        
    /// Создаем материал который будем рендерить в шейдерах Metal 
    lazy var material:SCNMaterial = {
        let m = SCNMaterial()
        m.program = self.program
        return m
    }()
        
    /// 
    /// Задаем геометрию "монолитного" RGB-куба
    ///
    lazy var meshGeometry:SCNGeometry = {
        ///
        /// В качестве исходной фигуры можно было бы задать объект кубической формы.
        /// Но он содержит по умолчанию всего 8 сегментов, что мало для визуально-различимого 
        /// рендеринга "дефектов" LUT. Для этого нам придется "накидать" на каждую сторону побольше разрешения:
        ///
        ///        let g = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0) 
        ///        let segments = 64
        ///        g.widthSegmentCount = segments
        ///        g.heightSegmentCount = segments
        ///        g.lengthSegmentCount = segments    
        ///
        /// Но мы выбираем сферу как более детализорованно-собранный mesh с более простой формой настройки:)
        /// А деформировать нам по сути все равно какой объект. 
        ///                
        let g = SCNSphere(radius: 2);
        
        /// Повышаем детализацию "монолита"
        g.segmentCount = 128
        
        ///
        /// Определяем материал геометрии, который будем рендерить и заодно деформировать в программе на MSL
        ///
        g.materials = [self.material]

        return g
    }()
    
    ///
    /// Создаем ноду с "монолитом" сферы
    ///
    lazy var meshNode:SCNNode = {
        let c = SCNNode(geometry: self.meshGeometry)
        reset(node: c)
        c.position = SCNVector3(x: 0, y: 0, z: 0)
        return c
    }()
    
    ///
    /// Говорим делегату рендеренга, что на новом шаге изменяем позции узловых точек RGB-куба в сцене
    /// Одновременно с этим на GPU шейдер деформирует координаты вершин нашего монолитного RGB-куба
    ///
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        guard isChanged else { return }
        
        for (i,rgb) in colors.enumerated() /*meshGrid.enumerated()*/ {
            let p = meshGrid[i]
            let rgba = float4(rgb.r,rgb.g,rgb.b,1)
            p.color = NSColor(color: rgba)
        }     
        
        self.isChanged = false
    }
    
    override func configure(frame: CGRect) {
        super.configure(frame: frame)
        
        sceneView.delegate = self
        ///
        /// Для наглядности
        ///
        sceneView.showsStatistics = true
                        
        /// Добавляем наш обект
        scene.rootNode.addChildNode(meshNode)            
        
        do {
            /// Идентити LUT
            lut = try IMPCLut(context: context, lutType: .lut_3d, lutSize: 16, format: .float)
        }
        catch let error {
            Swift.print("\(error)")
        }
        
        ///
        /// Для удабства разглядывания помечаем края RGB-куба шариками поболее
        ///
        for c in cornerColors {
            let n = IMPSCNRgbPoint(color: c, radius: 0.05, type: .sphere)
            facetCornerNodes.append(n)
            _ = n.attach(to: meshNode)
        }
        
        ///
        /// Соединяем их гранями
        ///
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
            
            /// Добавляем к сцене узловые точки RGB-куба
            for n in self.meshGrid {
                self.meshNode.addChildNode(n)                        
            }                
        }        
    }    
    
    /// Далее всякие простые настроечные штуки
    public override func constraintNode() -> SCNNode {
        return meshNode
    }          
    
    private let cornerColors:[NSColor] = [
        NSColor(red: 1, green: 0, blue: 0, alpha: 1), // 0
        NSColor(red: 0, green: 1, blue: 0, alpha: 1), // 1
        NSColor(red: 0, green: 0, blue: 1, alpha: 1), // 2
        
        NSColor(red: 1, green: 1, blue: 0, alpha: 1), // 3
        NSColor(red: 0, green: 1, blue: 1, alpha: 1), // 4
        NSColor(red: 1, green: 0, blue: 1, alpha: 1), // 5
        
        NSColor(red: 1, green: 1, blue: 1, alpha: 1), // 6
        NSColor(red: 0, green: 0, blue: 0, alpha: 1), // 7
    ]
    
    private lazy var facetColors:[(NSColor,NSColor)] = [
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
              
    private func colorGrid(exec:((_ rgb:float3)->Void)) {
        for r in 0..<resolution {
            for g in 0..<resolution {
                for b in 0..<resolution {                    
                    exec(float3(Float(r),Float(g),Float(b))/float3(Float(resolution-1)))
                }                
            }
        }
    }
    
    private lazy var meshGrid:[IMPSCNRgbPoint] = {
        var grid = [IMPSCNRgbPoint] ()
        colorGrid{ rgb in
            let rgba = float4(rgb.r,rgb.g,rgb.b,1)
            let n = IMPSCNRgbPoint(color: NSColor(color:rgba), radius: 0.02, type: .sphere)
            grid.append(n)
        }
        return grid
    }() 
        
    private var facetCornerNodes = [IMPSCNRgbPoint]()       
}
