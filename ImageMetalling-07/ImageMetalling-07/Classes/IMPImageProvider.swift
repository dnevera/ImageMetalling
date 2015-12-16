//
//  IMPImageProvider.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Foundation
import Metal

class IMPImageProvider: IMPTextureProvider,IMPContextProvider {
    
    var context:IMPContext!
    var texture:MTLTexture?
    
    required init(context: IMPContext) {
        self.context = context
    }
}
