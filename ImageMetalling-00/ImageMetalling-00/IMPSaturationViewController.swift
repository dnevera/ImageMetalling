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
    
    @IBAction func valueChanged(sender: UISlider) {
        NSLog(" *** value changed", sender.value)
        self.updateViewWith(sender.value)
    }
    
    /**
     * Срежем углы и сделаем по быстрому простое ручное обвноление параметра фильра.
     */
    func updateViewWith(saturation:Float){
        self.renderingView.saturation = saturation
        self.renderingView.refresh()
    }
    
    //
    // ... как обычно ...
    //
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        renderingView.loadImage("IMG_6295_1.JPG")

        self.saturationSlider.value = 1
        self.updateViewWith(1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

