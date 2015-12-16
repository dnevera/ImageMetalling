//
//  IMPTexturePovider.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Foundation
import Metal

protocol IMPTextureProvider{
    var texture:MTLTexture?{ get set }
    init(context:IMPContext)
}