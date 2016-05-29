//
//  ViewController.swift
//  ImageMetalling-11
//
//  Created by denis svinarchuk on 29.05.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import UIKit
import IMProcessing
import ScalePicker
import SnapKit
import ImageIO


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    let animateDuration:NSTimeInterval = UIApplication.sharedApplication().statusBarOrientationAnimationDuration
    
    var context = IMPContext()
    
    lazy var imageView:IMPView = {
        let v = IMPView(context: (self.filter.context)!,  frame: CGRectMake( 0, 20,
            self.view.bounds.size.width,
            self.view.bounds.size.height*3/4
            ))
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panHandler(_:)))
        v.addGestureRecognizer(pan)
        
        return v
    }()
    
    lazy var filter:IMPFilter = {
        return IMPFilter(context:self.context)
    }()
    
    lazy var transformFilter:IMPPhotoPlateFilter = {
        let f = IMPPhotoPlateFilter(context:self.context)
        f.backgroundColor = IMPColor.blackColor()
        return f
    }()
    
    lazy var cropFilter: IMPCropFilter = {
        return IMPCropFilter(context:self.context)
    }()

    var currentScaleFactor:Float {
        return IMPPlate(aspect: transformFilter.aspect).scaleFactorFor(model: transformFilter.model)
    }
    
    var currentCropRegion:IMPRegion {
        let offset = (1 - currentScaleFactor * transformFilter.scale.x ) / 2
        return IMPRegion(left: offset+currentCrop.left, right: offset+currentCrop.right, top: offset+currentCrop.top, bottom: offset+currentCrop.bottom)
    }
    
    var currentTranslationTimer:IMPDisplayTimer? {
        willSet {
            if let t = currentTranslationTimer {
                t.invalidate()
            }
        }
    }
    
    func animateTranslation(offset:float2)  {
        
        let start = transformFilter.translation
        let final = start + offset
        
        currentTranslationTimer = IMPDisplayTimer.execute(
            duration: animateDuration,
            options: .EaseIn,
            update: { (atTime) in
                self.transformFilter.translation = start.lerp(final: final, t: atTime.float)
        })
    }
    
    var outOfBounds:float2 {
        get {
            let aspect   = transformFilter.aspect
            let model    = transformFilter.model
            
            print(" outOfBounds, aspect = \(aspect)")
            
            //
            // Model of Cropped Quad
            //
            let cropQuad = IMPQuad(region:currentCropRegion, aspect: aspect)
            
            //
            // Model of transformed Quad
            // Transformation matrix of the model can be the same which transformation filter has or it can be computed independently
            //
            let transformedQuad = IMPPlate(aspect: aspect).quad(model: model)
            
            //
            // Offset for transformed quad which should contain inscribed croped quad
            //
            // NOTE:
            // 1. quads should be rectangle
            // 2. scale of transformed quad should be great then or equal scaleFactorFor for the transformed model:
            //    IMPPlate(aspect: transformFilter.aspect).scaleFactorFor(model: model)
            //
            return transformedQuad.translation(quad: cropQuad)
        }
    }
    
    ///  Check bounds of inscribed Rectangular
    func checkBounds() {
        animateTranslation(-outOfBounds)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        filter.addFilter(transformFilter)
        filter.addFilter(cropFilter)

        imageView.filter = filter
        
        cropAngleScaleView.valueFormatter = {(value: CGFloat) -> NSAttributedString in
            let attrs = [NSForegroundColorAttributeName: UIColor.whiteColor(),
                         NSFontAttributeName: UIFont.systemFontOfSize(12.0)]
            
            let updatedValue = value * 9.0
            let sign = updatedValue > 0 ? "+" : ""
            let text = sign + String(format: "%.2f°", updatedValue)
            
            return NSMutableAttributedString(string: text, attributes: attrs)
        }
        
        cropAngleScaleView.valueChangeHandler = {[unowned self] (value: CGFloat) -> Void in
            self.didChangeAngle(((value.float * 9) % 360).radians)
        }
        
        self.view.insertSubview(imageView, atIndex: 0)
        
        IMPMotionManager.sharedInstance.addRotationObserver { (orientation) in
            self.imageView.setOrientation(orientation, animate: true)
        }
        
        cunfigureUI()
    }
    
    var timer:NSTimer? = nil
    func didChangeAngle(value:Float) {
        
        transformFilter.angle.z = value
        cropFilter.region = currentCropRegion
        
        if timer != nil {
            timer?.invalidate()
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(0.03, target: self, selector: #selector(self.checkBounds), userInfo: nil, repeats: false)
    }
    
    func reset(sender:UIButton){
        cropAngleScaleView.reset()
        currentCrop = IMPRegion()
        cropFilter.region = currentCrop
    }
    
    var finger_point_offset = NSPoint()
    var finger_point_before = NSPoint()
    
    var finger_point = NSPoint() {
        didSet{
            finger_point_before = oldValue
            finger_point_offset = finger_point_before - finger_point
        }
    }
    
    func panHandler(gesture:UIPanGestureRecognizer)  {
        if gesture.state == .Began {
            tapDown(gesture)
        }
        else if gesture.state == .Changed {
            translateImage(gesture)
        }
        else if gesture.state == .Ended{
            tapUp(gesture)
        }
    }
    
    func  convertOrientation(point:NSPoint) -> NSPoint {
        
        let o = imageView.orientation
        
        if o == .Portrait {
            return point
        }
        
        //
        // adjust absolute coordinates to relative
        //
        var new_point = point
        
        let w = imageView.bounds.size.width.float
        let h = imageView.bounds.size.height.float
        
        new_point.x = new_point.x/w.cgfloat * 2 - 1
        new_point.y = new_point.y/h.cgfloat * 2 - 1
        
        // make relative point
        var p = float4(new_point.x.float,new_point.y.float,0,1)
        
        // make idenity transformation
        var identity = IMPMatrixModel.identity
        
        if o == .PortraitUpsideDown {
            //
            // rotate up-side-down
            //
            identity.rotateAround(vector: IMPMatrixModel.degrees180)
            
            // transform point
            p  =  float4x4(identity.transform) * p
            
            // back to absolute coords
            new_point.x = (p.x.cgfloat+1)/2 * w
            new_point.y = (p.y.cgfloat+1)/2 * h
        }
        else {
            if o == .LandscapeLeft {
                identity.rotateAround(vector: IMPMatrixModel.right)
                
            }else if o == .LandscapeRight {
                identity.rotateAround(vector: IMPMatrixModel.left)
            }
            p  =  float4x4(identity.transform) * p
            
            new_point.x = (p.x.cgfloat+1)/2 * h
            new_point.y = (p.y.cgfloat+1)/2 * w
        }
        
        return new_point
    }
    
    func tapDown(gesture:UIPanGestureRecognizer) {
        finger_point = convertOrientation(gesture.locationInView(imageView))
        finger_point_before = finger_point
        finger_point_offset = NSPoint(x: 0,y: 0)
    }
    
    func tapUp(gesture:UIPanGestureRecognizer) {
        
        //
        // Bound limits
        //
        let plate           = IMPPlate(aspect: transformFilter.aspect)
        var transformedQuad = plate.quad(model: transformFilter.model)
        transformedQuad.crop(region: IMPRegion(left: 0.1, right: 0.1, top: 0.1, bottom: 0.1))
        
        
        //
        // Decelerating timer execution example
        //
        
        let velocity = gesture.velocityInView(imageView)
        
        let v            = float2((velocity.x/imageView.bounds.size.width).float,
                                  (velocity.y/imageView.bounds.size.width).float)
        //
        // Convert view port velocity direction to right direction + control velocity scale factor
        //
        let directionConverter = float2(-0.1,0.1)
        let dist = (directionConverter*abs(lastDistance))*v
        let offset = -(lastDistance+dist)
        
        //
        // For example...
        //
        let duration = animateDuration * NSTimeInterval(abs(transformFilter.scale.x))
        
        currentTranslationTimer = IMPDisplayTimer.execute(duration: duration, options: .Decelerate, update: { (atTime) in
            
            let translation = self.transformFilter.translation + offset * atTime.float
            
            if transformedQuad.contains(point: translation) {
                self.transformFilter.translation = translation
            }
            
            }, complete: { (flag) in
                if flag {
                    self.checkBounds()
                }
        })
    }
    
    func panningDistance() -> float2 {
        
        if currentTranslationTimer != nil {
            currentTranslationTimer = nil
        }
        
        let w = self.imageView.frame.size.width.float
        let h = self.imageView.frame.size.height.float
        
        let x = 1/w * finger_point_offset.x.float
        let y = -1/h * finger_point_offset.y.float
        
        let f = IMPPlate(aspect: transformFilter.aspect).scaleFactorFor(model: transformFilter.model)
        
        return float2(x,y) * f * transformFilter.scale.x
    }
    
    var lastDistance = float2(0)
    
    func translateImage(gesture:UIPanGestureRecognizer)  {
        finger_point = convertOrientation(gesture.locationInView(imageView))
        lastDistance  = panningDistance()
        transformFilter.translation -= lastDistance * (float2(1)-abs(outOfBounds))
    }
    
    var currentCrop = IMPRegion()
    
    func crop(sender:UIButton)  {
        var ucropOffset:Float = 1
        var scropOffset:Float = 1
        
        if let t = filter.source?.texture {
            
            let aspect = t.width.float/t.height.float
            var isPortrate = false
            if aspect < 1 {
                isPortrate = true
            }
            
            switch sender.tag {
            case 11:
                if isPortrate {
                    scropOffset =  aspect
                }
                else {
                    ucropOffset =  1/aspect
                }
            case 32:
                if isPortrate {
                    ucropOffset =   (2/3) / aspect
                }
                else {
                    scropOffset =  aspect / (3/2)
                }
            case 169:
                if isPortrate {
                    ucropOffset =  (9/16) / aspect
                }
                else {
                    scropOffset =  aspect / (16/9)
                }
            case 43:
                if isPortrate{
                    ucropOffset =  (3/4) / aspect
                }
                else {
                    scropOffset =  aspect / (4/3)
                }
            default:
                scropOffset = 1
                ucropOffset = 1
            }
            
            let soffset = (1-scropOffset)/2
            let uoffset = (1-ucropOffset)/2
            
            print("aspect = \(aspect)  soffset = \(soffset) uoffset =\(uoffset)")
            
            currentCrop = IMPRegion(left: uoffset, right: uoffset, top: soffset, bottom: soffset)
            
            cropFilter.region = currentCropRegion
            
            checkBounds()
        }
    }
    
    private let cropAngleScaleContainer = UIView(frame: CGRect(x: 0, y: Config.ScreenHeight - Config.AppTabBarHeight - 52,
        width: Config.ScreenWidth, height: 52.0))
    
    private let cropAngleScaleView = ScalePicker(frame: CGRect(x: 0, y: 20,
        width: Config.ScreenWidth, height: 52.0))
    
    func cunfigureUI() {
        
        view.backgroundColor = UIColor.blackColor()
        
        view.addSubview(cropAngleScaleContainer)
        cropAngleScaleContainer.addSubview(cropAngleScaleView)
        
        cropAngleScaleView.minValue = -5.0
        cropAngleScaleView.maxValue = 5.0
        cropAngleScaleView.numberOfTicksBetweenValues = 2
        cropAngleScaleView.spaceBetweenTicks = 20.0
        cropAngleScaleView.showTickLabels = false
        cropAngleScaleView.gradientMaskEnabled = true
        cropAngleScaleView.sidePadding = 20.0
        cropAngleScaleView.pickerPadding = 0.0
        cropAngleScaleView.showCurrentValue = true
        cropAngleScaleView.tickColor = UIColor.whiteColor()
        
        cropAngleScaleView.reset()
        
        let albumButton = UIButton(type: .System)
        
        albumButton.backgroundColor = IMPColor.clearColor()
        albumButton.tintColor = IMPColor.whiteColor()
        albumButton.setImage(IMPImage(named: "select-photos"), forState: .Normal)
        albumButton.addTarget(self, action: #selector(self.openAlbum(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(albumButton)
        
        albumButton.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(view).offset(-20)
            make.left.equalTo(view).offset(40)
        }
        
        let resetButton = UIButton(type: .System)
        
        resetButton.setTitle("Reset", forState: .Normal)
        resetButton.backgroundColor = IMPColor.clearColor()
        resetButton.tintColor = IMPColor.whiteColor()
        resetButton.addTarget(self, action: #selector(self.reset(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(resetButton)
        
        resetButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(albumButton.snp_centerY).offset(0)
            make.right.equalTo(view).offset(-20)
        }

        let crop11Button = UIButton(type: .System)
        
        crop11Button.backgroundColor = IMPColor.clearColor()
        crop11Button.tag       = 11
        crop11Button.tintColor = IMPColor.whiteColor()
        crop11Button.setImage(IMPImage(named: "crop1x1"), forState: .Normal)
        crop11Button.addTarget(self, action: #selector(self.crop(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(crop11Button)
        
        crop11Button.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(albumButton.snp_centerY).offset(0)
            make.right.equalTo(resetButton.snp_left).offset(-15)
        }
        
        let crop169Button = UIButton(type: .System)
        
        crop169Button.backgroundColor = IMPColor.clearColor()
        crop169Button.tag       = 169
        crop169Button.tintColor = IMPColor.whiteColor()
        crop169Button.setImage(IMPImage(named: "crop16x9"), forState: .Normal)
        crop169Button.addTarget(self, action: #selector(self.crop(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(crop169Button)
        
        crop169Button.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(albumButton.snp_centerY).offset(0)
            make.right.equalTo(crop11Button.snp_left).offset(-10)
        }

        let crop32Button = UIButton(type: .System)
        
        crop32Button.backgroundColor = IMPColor.clearColor()
        crop32Button.tag       = 32
        crop32Button.tintColor = IMPColor.whiteColor()
        crop32Button.setImage(IMPImage(named: "crop3x2"), forState: .Normal)
        crop32Button.addTarget(self, action: #selector(self.crop(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(crop32Button)
        
        crop32Button.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(albumButton.snp_centerY).offset(0)
            make.right.equalTo(crop169Button.snp_left).offset(-10)
        }
        

        let crop43Button = UIButton(type: .System)
        
        crop43Button.backgroundColor = IMPColor.clearColor()
        crop43Button.tag       = 43
        crop43Button.tintColor = IMPColor.whiteColor()
        crop43Button.setImage(IMPImage(named: "crop4x3"), forState: .Normal)
        crop43Button.addTarget(self, action: #selector(self.crop(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(crop43Button)
        
        crop43Button.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(albumButton.snp_centerY).offset(0)
            make.right.equalTo(crop32Button.snp_left).offset(-10)
        }
    }
    
    func openAlbum(sender:UIButton){
        imagePicker = UIImagePickerController()
    }
    
    var imagePicker:UIImagePickerController!{
        didSet{
            self.imagePicker.delegate = self
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            if let actualPicker = self.imagePicker{
                self.presentViewController(actualPicker, animated:true, completion:nil)
            }
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        let chosenImage:UIImage? = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        if let actualImage = chosenImage{
            cropAngleScaleView.reset()
            imageView.filter?.source = IMPImageProvider(context: context, image: actualImage, maxSize: 1200)
        }
    }
    
}

