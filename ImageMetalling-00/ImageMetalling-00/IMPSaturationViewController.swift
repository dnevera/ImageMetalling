//
//  ViewController.swift
//  ImageMetalling-00
//
//  Created by denis svinarchuk on 27.10.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

import UIKit

/**
 * ViewController для небольшой манипуляции картинкой и параметрами фильтра.
 */
class IMPSaturationViewController: UIViewController {

    /**
     * Контрол степени десатурации
     */
    @IBOutlet weak var saturationSlider: UISlider!
    
    /**
     * И представление и фильтр в одном флаконе.
     */
    @IBOutlet weak var renderingView: IMPSaturationView!
    
    /**
     * Ловим события от слайдера
     */
    @IBAction func valueChanged(sender: UISlider) {
        self.renderingView.saturation = sender.value;
    }
    
    /**
     * Срежем углы и сделаем по быстрому простое ручное обвноление параметра фильра.
     */
    func updateViewWith(saturation:Float){
    }
    
    //
    // ... как обычно ...
    //
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //
        // картинуку берем прям из ресурсов проекта
        //
        renderingView.loadImage("IMG_6295_1.JPG")

        //
        // инициализируем слайдер
        //
        self.saturationSlider.value = 1
        
        //
        // выставляем занчение нассыщенности
        //
        self.renderingView.saturation = self.saturationSlider.value;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

