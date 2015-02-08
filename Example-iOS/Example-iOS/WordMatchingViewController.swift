//
//  ViewController.swift
//  genetic
//
//  Created by Saniul Ahmed on 22/12/2014.
//  Copyright (c) 2014 Saniul Ahmed. All rights reserved.
//

import UIKit

class WordMatchingViewController: UIViewController {
    @IBOutlet weak var targetTextField: UITextField!
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var bestCandidateLabel: UILabel!
    @IBOutlet weak var iterationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var lab = WordMatchingLab()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.targetTextField.text = "Simplicity is hard work But theres a huge payoff"
    }
    
    @IBAction func start(sender: UIButton) {
//        self.lab.stop()
        
        self.lab.output = { data in
            dispatch_async(dispatch_get_main_queue()) {
                self.targetLabel.text = self.lab.targetWord
                self.bestCandidateLabel.text = data.bestCandidate
                self.distanceLabel.text = "\(data.bestCandidateFitness)"
                self.iterationLabel.text = "\(data.iterationNum)"
            }
        }
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) { () -> Void in
            self.lab.doScience(self.targetTextField.text)
        }
    }
    
    
}


