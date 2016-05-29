//
//  IMPAssets.swift
//  ImageMetalling-11
//
//  Created by denis svinarchuk on 29.05.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import Foundation
import IMProcessing
import ImageIO

struct Config {
    static let ScreenRect                  = UIScreen.mainScreen().bounds
    static let ScreenWidth                 = UIScreen.mainScreen().bounds.size.width
    static let ScreenHeight                = UIScreen.mainScreen().bounds.size.height
    
    static let TableViewCellHeight:CGFloat      = 50.0
    static let AppNavigationBarHeight:CGFloat   = 44.0
    static let AppStatusBarHeight:CGFloat       = 20.0
    static let AppSystemTabBarHeight:CGFloat    = 49.0
    static let AppNavigationAndStatusBarHeight  = AppNavigationBarHeight + AppStatusBarHeight
    static let AppSpareHeight:CGFloat           = ScreenHeight - (AppNavigationBarHeight + AppTabBarHeight)
    static let AppTabBarHeight:CGFloat          = 80.0
    static let AppCustomNavBarHeight:CGFloat    = ScreenHeight > 568.0 ? 66.0 : 44.0
    static let AppButtonPadding:CGFloat         = 20.0
    
    static let AppFullVersion              = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
    static let AppShortVersion             = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! String
}

public func == (left:NSPoint, right:NSPoint) -> Bool{
    return left.x==right.x && left.y==right.y
}

public func != (left:NSPoint, right:NSPoint) -> Bool{
    return !(left==right)
}

public func - (left:NSPoint, right:NSPoint) -> NSPoint {
    return NSPoint(x: left.x-right.x, y: left.y-right.y)
}

public func + (left:NSPoint, right:NSPoint) -> NSPoint {
    return NSPoint(x: left.x+right.x, y: left.y+right.y)
}
