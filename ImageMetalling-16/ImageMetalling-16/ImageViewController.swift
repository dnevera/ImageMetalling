//
//  ImageViewController.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 23.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import AppKit
import IMProcessing
import IMProcessingUI
import SnapKit

class ImageViewController: NSViewController {
    
    public lazy var filter:IMPCLutFilter = IMPCLutFilter(context: IMPContext()) 
        
    public lazy var imageView:TargetView = {
        let v = TargetView(frame: self.view.bounds)
        v.processingView.debug = true
        v.processingView.name = "Image View"
        v.processingView.filter = self.filter                
        return v
    }()
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().offset(5)
        }
        
        clickGesture.numberOfTouchesRequired = 1
        imageView.addGestureRecognizer(clickGesture)
        
        filter.addObserver(destinationUpdated: { dest in
            self.patchColors.source = dest
        })
    }
    
    /// Создаем фильтр обзёрвера цветов текстуры 
    private lazy var patchColors:IMPColorObserver = {
        let f = IMPColorObserver(context: self.filter.context)
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
                
                Swift.print("color = \(f.colors)")
                // просто рисуем 
                //self.patch.strokeColor = inverted_color                
                //self.colorLabel.backgroundColor = color
                //self.colorLabel.stringValue = String(format: "%3.0f, %3.0f, %3.0f", rgb.r, rgb.g, rgb.b)
            }
        })        
        return f
    }()
    
    private lazy var clickGesture:NSClickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(clickHandler(recognizer:)))

    @objc private func clickHandler(recognizer:NSPanGestureRecognizer)  {
        let position:NSPoint = recognizer.location(in: imageView)
        //patch.position = position
        
        let size = imageView.bounds.size
        let point =  float2((position.x / size.width).float, 1-(position.y / size.height).float)
        
        patchColors.centers = [point]
    }
}
