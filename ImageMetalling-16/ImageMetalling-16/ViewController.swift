//
//  ViewController.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 06.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Cocoa
import SnapKit

class ViewController: NSViewController {

    lazy var gridView = GridView(frame: self.view.bounds)
    
    lazy var alphaSlider = NSSlider(value: 1, minValue: 0, maxValue: 2, target: self, action: #selector(slider(sender:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()   
        
        view.addSubview(gridView)
        view.addSubview(alphaSlider)
        
        alphaSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        gridView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(alphaSlider.snp.top)
        }
    }
    
    @objc func slider(sender:NSSlider)  {
        gridView.solverAlpha = sender.floatValue
    }
}

