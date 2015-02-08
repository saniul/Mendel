//
//  ViewController.swift
//  genetic
//
//  Created by Saniul Ahmed on 22/12/2014.
//  Copyright (c) 2014 Saniul Ahmed. All rights reserved.
//

import UIKit

class ImageMatchingViewController: UIViewController {
    
    @IBOutlet var referenceImageView: UIImageView!
    @IBOutlet var bestIndividualImageView: UIImageView!
    @IBOutlet weak var iterationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var lab = ImageMatchingLab()
    
    let url = NSBundle.mainBundle().URLForResource("mona-lisa", withExtension: "jpg")!
    
    let image = UIImage(named: "mona-lisa.jpg")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.referenceImageView.image = image
    }
    
    @IBAction func start(sender: UIButton) {
        self.lab.stop()
        
        self.lab = ImageMatchingLab()
        
        self.lab.referenceImageURL = url
        self.lab.outputImageSize = image?.size
        
        self.lab.output = { image, iter in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.bestIndividualImageView.image = UIImage(CGImage: image)
                self.iterationLabel.text = "\(iter)"
                self.iterationLabel.text = "\(iter)"
            }
        }
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) { () -> Void in
            self.lab.doScience()
        }
    }
    
    
}

