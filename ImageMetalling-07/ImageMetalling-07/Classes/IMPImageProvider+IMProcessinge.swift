//
//  IMPImageProvider+IMPImage.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Foundation
import Metal

extension IMPImageProvider{
    
    convenience init(context: IMPContext, image: IMPImage, maxSize: Float = 0) {
        self.init(context: context)
        self.update(image)
    }
    
    func update(image:IMPImage){
        self.texture = image.newTexture(self.context)
    }
}