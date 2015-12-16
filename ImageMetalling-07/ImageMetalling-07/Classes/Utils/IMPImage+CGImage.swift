//
//  IMPImage+CGImage.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

extension IMPImage {
    var CGImage:CGImageRef?{
        get {
            var imageRect:CGRect = CGRectMake(0, 0, self.size.width, self.size.height)
            return self.CGImageForProposedRect(&imageRect, context: nil, hints: nil)
        }
    }
}
