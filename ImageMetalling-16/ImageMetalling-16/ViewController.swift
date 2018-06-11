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
    
    override func viewDidLoad() {
        super.viewDidLoad()   
        view.addSubview(gridView)
        gridView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

