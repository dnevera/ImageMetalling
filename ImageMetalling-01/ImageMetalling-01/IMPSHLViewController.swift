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
    @IBOutlet weak var shadowsLevelSlider: UISlider!
    
    /**
     * Контрол тональной ширины теней
     */
    @IBOutlet weak var shadowsWidthSlider: UISlider!
    
    /**
     * Контрол наклона кривой перехода между тенью и светами
     */
    @IBOutlet weak var shadowsSlopSlider: UISlider!
    
    /**
     * И представление и фильтр в одном флаконе.
     */
    @IBOutlet weak var renderingView: IMPSHLView!
    
    /**
     * Ловим события от слайдера
     */
    @IBAction func valueChanged(sender: UISlider) {
        switch(sender){
        case shadowsLevelSlider:
            self.renderingView.shadowsLevel = sender.value
        case shadowsWidthSlider:
            self.renderingView.shadowsWidth = sender.value;
        case shadowsSlopSlider:
            self.renderingView.shadowsSlop = sender.value;
        default:
            NSLog(" *** Unknown slider")
        }
        NSLog(" *** Slider %@", sender);

        self.renderingView.refresh();
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        renderingView.loadImage("IMG_8239.JPG")

        self.shadowsLevelSlider.value = self.renderingView.shadowsLevel
        self.shadowsWidthSlider.value = self.renderingView.shadowsWidth
        self.shadowsSlopSlider.value = self.renderingView.shadowsSlop
    
        self.renderingView.refresh();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

