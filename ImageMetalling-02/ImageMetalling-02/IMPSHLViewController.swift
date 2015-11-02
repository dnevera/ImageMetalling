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
class IMPSHLViewController: UIViewController {

    /**
     * Контрол степени осветдения тени
     */
    @IBOutlet weak var levelSlider: UISlider!
    
    /**
     * Контрол тональной ширины теней
     */
    @IBOutlet weak var shadowsWidthSlider: UISlider!
    
    /**
     * Контрол наклона кривой перехода между тенью и светами
     */
    @IBOutlet weak var highlightsWidthSlider: UISlider!
    
    /**
     * И представление и фильтр в одном флаконе.
     */
    @IBOutlet weak var renderingView: IMPSHLView!
    
    /**
     * Ловим события от слайдера
     */
    @IBAction func valueChanged(sender: UISlider) {
        switch(sender){
        case levelSlider:
            self.renderingView.level = sender.value
        case shadowsWidthSlider:
            self.renderingView.shadowsWidth = sender.value;
        case highlightsWidthSlider:
            self.renderingView.highlightsWidth = sender.value;
        default:
            NSLog(" *** Unknown slider")
        }

        self.renderingView.refresh();
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        renderingView.loadImage("shadows_highlights.jpg")

        self.levelSlider.value = self.renderingView.level
        self.shadowsWidthSlider.value = self.renderingView.shadowsWidth
        self.highlightsWidthSlider.value = self.renderingView.highlightsWidth
    
        self.renderingView.refresh();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

