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
    
    var patchColorHandler:((_ color:float3)->Void)? = nil
    
    
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
            // прочитаных семплов цветов
            //             
            self.patchColorHandler?(f.colors[0])            
          
        })        
        return f
    }()
    
    private lazy var clickGesture:NSClickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(clickHandler(recognizer:)))

    @objc private func clickHandler(recognizer:NSPanGestureRecognizer)  {
        let position:NSPoint = recognizer.location(in: imageView.processingView)
        
        let size = imageView.processingView.bounds.size
        let point =  float2((position.x / size.width).float, 1-(position.y / size.height).float)
        
        patchColors.centers = [point]
    }
}
