//
//  ViewController.swift
//  ImageMetalling-03
//
//  Created by denis svinarchuk on 04.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var liveView: UIView!
    
    @IBOutlet weak var opacitySlider: UISlider!
    
    @IBOutlet weak var filter1ViewImage: UIImageView!
    
    @IBOutlet weak var filter2ViewImage: UIImageView!
    
    @IBOutlet weak var filter3ViewImage: UIImageView!
    
    
    @IBAction func changeSliderValue(sender: UISlider) {
        let filter:DPCLUTFilter = camera.liveViewFilter as! DPCLUTFilter
        filter.adjustment.blending.opacity=sender.value
    }
    
    
    private let context   = DPContext.newContext()
    
    private var filter1:DPCLUTFilter!
    private var filter2:DPCLUTFilter!
    private var filter3:DPCLUTFilter!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        camera.start()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated);
        do{
            
            var lut = try DPCubeLUTFileProvider.newLUTNamed("filter1", context: context)
            
            filter1 = DPCLUTFilter(context: context, lut: lut, type: lut.type)
            
            lut = try DPCubeLUTFileProvider.newLUTNamed("filter2", context: context)
            
            filter2 = DPCLUTFilter(context: context, lut: lut, type: lut.type)
            
            lut = try DPCubeLUTFileProvider.newLUTNamed("filter3", context: context)
            
            filter3 = DPCLUTFilter(context: context, lut: lut, type: lut.type)
            
            let image = UIImage(named: "template.jpg")
            
            filter1.source = DPUIImageProvider.newWithImage(image, context: context)
            filter2.source = DPUIImageProvider.newWithImage(image, context: context)
            filter3.source = DPUIImageProvider.newWithImage(image, context: context)
            
            filter1ViewImage.image=UIImage(imageProvider: filter1.destination)
            filter2ViewImage.image=UIImage(imageProvider: filter2.destination)
            filter3ViewImage.image=UIImage(imageProvider: filter3.destination)
            
            UIView.animateWithDuration(UIApplication.sharedApplication().statusBarOrientationAnimationDuration,
                animations: {
                    self.filter1ViewImage.alpha = 1.0
                    self.filter2ViewImage.alpha = 0.5
                    self.filter3ViewImage.alpha = 0.5
                }
            )
        }
        catch let error as NSError{
            NSLog(" *** %@", error);
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        camera.stop()
    }
    
    
    private var camera:DPCameraManager!
    
    private let contextLive   = DPContext.newContext()

    private var filter1Live:DPCLUTFilter!
    private var filter2Live:DPCLUTFilter!
    private var filter3Live:DPCLUTFilter!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        opacitySlider.value=1
        
        filter1ViewImage.contentMode = .ScaleAspectFit
        filter2ViewImage.contentMode = .ScaleAspectFit
        filter3ViewImage.contentMode = .ScaleAspectFit
        
        filter1ViewImage.alpha = 0.0
        filter2ViewImage.alpha = 0.0
        filter3ViewImage.alpha = 0.0

        filter1ViewImage.userInteractionEnabled = true;
        filter2ViewImage.userInteractionEnabled = true;
        filter3ViewImage.userInteractionEnabled = true;
        
        var tapGesture = UITapGestureRecognizer(target: self, action: "tapHandler:")

        filter1ViewImage.addGestureRecognizer(tapGesture)

        tapGesture = UITapGestureRecognizer(target: self, action: "tapHandler:")
        filter2ViewImage.addGestureRecognizer(tapGesture)

        tapGesture = UITapGestureRecognizer(target: self, action: "tapHandler:")
        filter3ViewImage.addGestureRecognizer(tapGesture)

        liveView = UIView(frame: CGRectMake( 0, 20,
            self.view.bounds.size.width,
            self.view.bounds.size.height*3/4
            ))
        liveView.backgroundColor = UIColor.clearColor()
        self.view.insertSubview(liveView, atIndex: 0)
        
        camera = DPCameraManager(outputContainerPreview: self.liveView)
        
        do{
            var lut = try DPCubeLUTFileProvider.newLUTNamed("filter1", context: contextLive)
            filter1Live = DPCLUTFilter(context: self.contextLive, lut: lut, type: lut.type);

            lut = try DPCubeLUTFileProvider.newLUTNamed("filter2", context: contextLive)
            filter2Live = DPCLUTFilter(context: self.contextLive, lut: lut, type: lut.type);

            lut = try DPCubeLUTFileProvider.newLUTNamed("filter3", context: contextLive)
            filter3Live = DPCLUTFilter(context: self.contextLive, lut: lut, type: lut.type);

            self.camera.liveViewFilter = filter1Live
        }
        catch let error as NSError{
            NSLog(" *** %@", error);
        }
    }

    func tapHandler(gesture:UITapGestureRecognizer){
        
        filter1ViewImage.alpha = 0.5
        filter2ViewImage.alpha = 0.5
        filter3ViewImage.alpha = 0.5
        
        if gesture.view == self.filter1ViewImage {
            camera.liveViewFilter = filter1Live
            filter1ViewImage.alpha = 1.0
        }
        else if gesture.view == self.filter2ViewImage {
            camera.liveViewFilter = filter2Live
            filter2ViewImage.alpha = 1.0
        }
        else if gesture.view == self.filter3ViewImage {
            camera.liveViewFilter = filter3Live
            filter3ViewImage.alpha = 1.0
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

