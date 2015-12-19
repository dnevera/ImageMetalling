//
//  IMPMenuHandler.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

typealias IMPMenuObserver = ((item:NSMenuItem)->Void)

enum IMPMenuTag{
    case zoom100(Int) = 3005
}

class IMPMenuHandler:NSObject {
    
    private override init() {}
    private var didUpdateMenuHandlers = [IMPMenuObserver]()
    
    static let sharedInstance = IMPMenuHandler()

    var currentMenuItem:NSMenuItem?{
        didSet{
            for o in self.didUpdateMenuHandlers{
                o(item: currentMenuItem!)
            }
        }
    }
    
    func addMenuObserver(observer:IMPMenuObserver){
        didUpdateMenuHandlers.append(observer)
    }
}