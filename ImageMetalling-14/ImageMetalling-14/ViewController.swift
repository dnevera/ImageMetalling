//
//  ViewController.swift
//  ImageMetalling-14
//
//  Created by denis svinarchuk on 16.05.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Cocoa
import SpriteKit
import IMProcessing
import IMProcessingUI
import SnapKit


///
/// Основной констроллер, в котором будем указывать квадратную область картинки, 
/// читать цвета всех пикселов внутри и вычислять средний цвет это области
///
class ViewController: NSViewController {
        
    ///
    /// Патч который экспонируем поверх картинки для получения области считывания 
    /// пикселей текстуры
    ///
    lazy var patch:PatchNode = PatchNode(size: CGFloat(self.patchColors.regionSize))
    
    /// Контекст процессинга
    var context = IMPContext()
    
    
    /// 
    /// Путь к изображению 
    ///
    var imagePath:String? {
        didSet{
            guard  let path = imagePath else {
                return
            }            
            
            // Читаем изображение
            let image = IMPImage(context: context, path: path)
            
            // Исходная текстура изображения для анализа
            patchColors.source = image
            
            // Она же для отображения
            targetView.processingView.image = IMPImage(context: context, path: path)
            
            let size  = image.size ?? NSSize(width: 700, height: 500)
            
            // Просто магия для адоптации размеров изображения к viewport окна
            self.targetView.processingView.fitViewSize(size: size, to: self.targetView.bounds.size, moveCenter: false)
            self.targetView.sizeFit()
            
            patch.position.x = targetView.processingView.frame.size.width/2
            patch.position.y = targetView.processingView.frame.size.height/2
            
            scene.size = self.targetView.processingView.bounds.size
        }
    }
    
    /// Создаем фильтр обзёрвера цветов текстуры 
    private lazy var patchColors:ColorObserver = {
        let f = ColorObserver(context: self.context)
        //
        // Размер прямоугольной (квадратной) области по которой мы интерполируем 
        // (на самом деле усредняем) цвет текстуры
        //
        f.regionSize = 20
        
        //
        // Добавляем к фильтру обработку событий пересчета целевой тектстуры,
        // которая на самом деле не пересчитывается и читает в шейдере в буфер её RGB-смеплы
        //
        f.addObserver(destinationUpdated: { (destination) in
          
            // 
            // Поскольку мы читаем только одну область то берем первый элемент массива 
            // прочитаных семполов цветов
            // 
            var rgb = f.colors[0]
            
            // представление [0-1] в NSColor
            let color = NSColor(color: float4(rgb.r,rgb.g,rgb.b,1))
            
            // инвертируем цвет
            let inverted_rgb = float3(1) - rgb 
            let inverted_color = NSColor(color: float4(inverted_rgb.r,inverted_rgb.g,inverted_rgb.b,1))
            
            // для отображения в textfield переведем в 8-битное представление
            rgb = rgb * float3(255)
            
            DispatchQueue.main.async {
                // просто рисуем 
                self.patch.strokeColor = inverted_color                
                self.colorLabel.backgroundColor = color
                self.colorLabel.stringValue = String(format: "%3.0f, %3.0f, %3.0f", rgb.r, rgb.g, rgb.b)
            }
        })        
        return f
    }()
    
    /// Все как обычно
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(targetView)
        
        targetView.autoresizingMask = [.height, .width] 
        targetView.frame = view.bounds 
        
        targetView.processingView.addSubview(skview)
        
        scene.scaleMode       = .resizeFill
        scene.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.0)
        scene.addChild(patch)
        
        patch.position.x = targetView.processingView.frame.size.width/2
        patch.position.y = targetView.processingView.frame.size.height/2
        
        skview.addGestureRecognizer(panGesture)
        
        view.addSubview(colorLabel)
        colorLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        
        defer {
            skview.autoresizingMask = [.height, .width]
            skview.frame = targetView.processingView.bounds
            skview.allowsTransparency = true
            skview.presentScene(scene)
        }
    }
    
    
    /// Тут просто рисуем картинку с возможностью скрола и зума
    public lazy var targetView:TargetView = {
        let v = TargetView(frame: self.view.bounds)
        return v
    }()
    
    private lazy var skview:SKView = SKView(frame: self.view.bounds)
    private lazy var scene:SKScene = SKScene(size: self.skview.bounds.size)
    private lazy var panGesture:NSPanGestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(panHandler(recognizer:)))
    
    
    /// Возим патч по окну мышкой    
    @objc private func panHandler(recognizer:NSPanGestureRecognizer)  {
        let position:NSPoint = recognizer.location(in: skview)
        patch.position = position
        
        let size = skview.bounds.size
        let point =  float2((position.x / size.width).float, 1-(position.y / size.height).float)
        
        patchColors.centers = [point]
    }
    
    /// Отобрахаем то, что прочитали в текстуре 
    private lazy var colorLabel:NSTextField = {
        let label = NSTextField(frame:self.view.frame)
        label.alignment = .center
        label.cell?.lineBreakMode = .byTruncatingMiddle
        label.backgroundColor = NSColor.clear
        label.isEditable = false        
        label.isBezeled = false
        label.font =  NSFont(name: "Courier New", size: 12)
        return label        
    }()            
}

