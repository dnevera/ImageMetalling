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


public func * (left:CGPoint, right:CGPoint) -> CGPoint {
    return CGPoint(x: left.x*right.x, y: left.y*right.y)
}

public func / (left:CGPoint, right:CGPoint) -> CGPoint {
    return CGPoint(x: left.x/right.x, y: left.y/right.y)
}

public func * (left:CGPoint, right:Float) -> CGPoint {
    return CGPoint(x: left.x*right, y: left.y*right)
}

public func / (left:CGPoint, right:Float) -> CGPoint {
    return CGPoint(x: left.x/right, y: left.y/right)
}

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

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.scaleHandler(_:)))
        v.addGestureRecognizer(pinch)

        return v
    }()
    
    lazy var filter:IMPFilter = {
        return IMPFilter(context:self.context)
    }()
    
    lazy var photoEditor:IMPPhotoEditor = {
        let f = IMPPhotoEditor(context:self.context)
        f.backgroundColor = IMPColor.blackColor()
        f.addDestinationObserver(destination: { (destination) in
            f.viewPort = self.imageView.layer.bounds
        })
        return f
    }()
    
    
    lazy var animator:UIDynamicAnimator = UIDynamicAnimator(referenceView: self.imageView)
    var deceleration:UIDynamicItemBehavior?
    var spring:UIAttachmentBehavior?
    
    func updateBounds(){
        
        guard let anchor = photoEditor.anchor else { return }
        
        let spring = UIAttachmentBehavior(item: photoEditor, attachedToAnchor: anchor)
        
        if photoEditor.scale <= 1 {
            let offset = abs(photoEditor.outOfBounds)
            
            if offset.x < 0.1 * photoEditor.aspect && offset.y < 0.1 {
                //
                // remove oscilations
                //
                self.animator.removeAllBehaviors()
                
                let start = self.photoEditor.translation
                let final = start - self.photoEditor.outOfBounds
                IMPDisplayTimer.execute(duration: animateDuration, options: .EaseOut, update: { (atTime) in
                    self.photoEditor.translation = start.lerp(final: final, t: atTime.float)
                    }, complete: { (flag) in
                })
                
                return
            }
        }
        
        spring.length    = 0
        spring.damping   = 0.5
        spring.frequency = 1
        
        animator.addBehavior(spring)
        self.spring = spring
    }
    
    func decelerateToBonds(gesture:UIPanGestureRecognizer? = nil) {
        
        var velocity = CGPoint()
        
        if let g = gesture {
            velocity = g.velocityInView(imageView)
            velocity = CGPoint(x: velocity.x,y: -velocity.y)
        }
        
        let decelerate = UIDynamicItemBehavior(items: [photoEditor])
        decelerate.addLinearVelocity(velocity, forItem: photoEditor)
        decelerate.resistance = 10
        
        decelerate.action = {
            self.updateBounds()
        }
        self.animator.addBehavior(decelerate)
        self.deceleration = decelerate
    }
    
 
    func checkBounds() {
        animator.removeAllBehaviors()
        let start = self.photoEditor.translation
        let final = start - self.photoEditor.outOfBounds
        IMPDisplayTimer.execute(duration: animateDuration, options: .EaseOut, update: { (atTime) in
            self.photoEditor.translation = start.lerp(final: final, t: atTime.float)
            }, complete: { (flag) in
        })
    }
    
    
    lazy var angleChangeHandler:((value: CGFloat) -> Void) = {[unowned self] (value: CGFloat) -> Void in
        self.didChangeAngle(((value.float * 9) % 360).radians)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        filter.addFilter(photoEditor)

        imageView.filter = filter
        
        cropAngleScaleView.valueFormatter = {(value: CGFloat) -> NSAttributedString in
            let attrs = [NSForegroundColorAttributeName: UIColor.whiteColor(),
                         NSFontAttributeName: UIFont.systemFontOfSize(12.0)]
            
            let updatedValue = value * 9.0
            let sign = updatedValue > 0 ? "+" : ""
            let text = sign + String(format: "%.2f°", updatedValue)
            
            return NSMutableAttributedString(string: text, attributes: attrs)
        }
        
        cropAngleScaleView.valueChangeHandler = angleChangeHandler
        
        self.view.insertSubview(imageView, atIndex: 0)
        
        IMPMotionManager.sharedInstance.addRotationObserver { (orientation) in
            self.imageView.setOrientation(orientation, animate: true)
        }
        
        cunfigureUI()
    }
    
    func rotate(angle:Float) {
        photoEditor.angle.z = angle
    }
    
    func didChangeAngle(value:Float) {
        rotate(value)
        checkBounds()
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
    
    var initialScale:Float = 1
    
    func scaleHandler(gesture:UIPinchGestureRecognizer)  {
        
        if gesture.state == .Began {
            animator.removeAllBehaviors()
            initialScale = photoEditor.scale
        }
        else if gesture.state == .Changed {
            
            var factor = initialScale * gesture.scale.float
            
            if factor<1{
                factor = pow(factor, 1/4)
            }
            
            photoEditor.scale = factor
            checkBounds()
        }
        else if gesture.state == .Ended{
            if photoEditor.scale < 1 || photoEditor.scale > 4 {
                
                let start = photoEditor.scale
                let final:Float =  photoEditor.scale > 4 ? 4 : 1
                
                IMPDisplayTimer.execute(duration: animateDuration, options: .EaseOut, update: { (atTime) in
                    self.photoEditor.scale = start.lerp(final: final, t: atTime.float)
                    }, complete: { (flag) in
                        self.checkBounds()
                })
            }
            else {
                self.checkBounds()
            }
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
        animator.removeAllBehaviors()
    }
    
    func tapUp(gesture:UIPanGestureRecognizer) {
        decelerateToBonds(gesture)
    }
    
    func panningDistance() -> float2 {
        
        let w = self.imageView.frame.size.width.float
        let h = self.imageView.frame.size.height.float
        
        let x = 1/w * finger_point_offset.x.float
        let y = -1/h * finger_point_offset.y.float
        
        let friction:Float = 0.1
        let sx =  springBand(friction, offset: finger_point_offset.x.float, dimension: w)/w
        let sy = -springBand(friction, offset: finger_point_offset.y.float, dimension: h)/h
        
        return float2(x+sx,y+sy) * photoEditor.cropedFactor
    }
    
    var lastDistance = float2(0)
    
    func springBand(friction:Float, offset:Float, dimension:Float) -> Float {
        let result = (friction * abs(offset) * dimension) / (dimension + friction * abs(offset))
        return offset < 0.0 ? -result : result;
    }

    func translateImage(gesture:UIPanGestureRecognizer)  {
        finger_point = convertOrientation(gesture.locationInView(imageView))
        lastDistance  = panningDistance()
        photoEditor.translation -= lastDistance * (float2(1)-abs(photoEditor.outOfBounds))
    }
    
    func crop(sender:UIButton)  {
        var ucropOffset:Float = 0
        var scropOffset:Float = 0
        
        if let t = filter.source?.texture {
            
            let aspect    = t.width.float/t.height.float
            var newAspect = aspect
            
            switch sender.tag {
            case 11:
                newAspect = 1
            case 32:
                newAspect = 3/2
            case 169:
                newAspect = 16/9
            case 43:
                newAspect = 4/3
            default:
                newAspect = aspect
            }
            
            if aspect < 1 { // portrait
                newAspect = 1/newAspect
            }
            
            let ratio = aspect / newAspect
            
            if ratio <= 1 {
                scropOffset = (1 - aspect / newAspect)/2
            }
            else {
                ucropOffset = (1 - newAspect / aspect )/2
            }
            
            let start = photoEditor.crop
            let final = IMPRegion(left: ucropOffset, right: ucropOffset, top: scropOffset, bottom: scropOffset)
            
            IMPDisplayTimer.execute(duration: animateDuration, options: .EaseOut, update: { (atTime) in
                self.photoEditor.crop = start.lerp(final: final, t: atTime.float)
                }, complete: { (flag) in
                    self.checkBounds()
            })
        }
    }
    
    func reset(sender:UIButton){
        animator.removeAllBehaviors()
        
        self.cropAngleScaleView.valueChangeHandler = {_ in }
        self.cropAngleScaleView.reset()
        
        let startScale = photoEditor.scale
        let startTranslation = photoEditor.translation
        let startAngle = photoEditor.angle.z
        
        let startCrop = photoEditor.crop
        let finalCrop = IMPRegion()
        
        IMPDisplayTimer.execute(duration: animateDuration, options: .EaseOut, update: { (atTime) in
            self.photoEditor.translation = startTranslation.lerp(final: float2(0), t: atTime.float)
            self.photoEditor.scale = startScale.lerp(final: 1, t: atTime.float)
            self.rotate(startAngle.lerp(final: 0, t: atTime.float))
            self.photoEditor.crop = startCrop.lerp(final: finalCrop, t: atTime.float)
        }) { (flag) in
            self.cropAngleScaleView.valueChangeHandler = self.angleChangeHandler
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
    
    var aflag = true
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if aflag {
            imagePicker = UIImagePickerController()
            aflag = false
        }
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

