//
//  IMPAliases.swift
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import Cocoa

#if os(iOS)
    typealias IMPImage = UIImage
    typealias IMPColor = UIColor
#else
    typealias IMPImage = NSImage
    typealias IMPColor = NSColor
#endif
