//
//  AnnotationViewController.swift
//  InSync
//
//  Created by Olivia Gregory on 8/1/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Gecco

class AnnotationViewController: SpotlightViewController {

    @IBOutlet var annotationViews: [UIView]!
    
    var stepIndex: Int = 0
    
    @IBOutlet weak var label22: UILabel!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var label4: UILabel!
    @IBOutlet weak var label5: UILabel!
    @IBOutlet weak var label6: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
    }
    
    func next(labelAnimated: Bool) {
        updateAnnotationView(labelAnimated)
        
        let screenSize = UIScreen.mainScreen().bounds.size
        switch stepIndex {
        //Welcome to party
        case 0:
            print("case 0")
            spotlightView.appear(Spotlight.RoundedRect(center: CGPointMake(129 + 59, 54 + 15.5), size: CGSizeMake(300, 31), cornerRadius: 6))
        //Now Playing
        case 1:
            spotlightView.move(Spotlight.Oval(center: CGPointMake(16 + 171, 145 + 171), diameter: 343), moveType: .Disappear)
        //Litness
        case 2:
            spotlightView.move(Spotlight.Oval(center: CGPointMake(24 + 13, 625 + 13), diameter: 26))
        //Announcements
        case 3:
            spotlightView.move(Spotlight.Oval(center: CGPointMake(174 + 13, 625 + 13), diameter: 26))
        //Volume
        case 4:
             spotlightView.move(Spotlight.Oval(center: CGPointMake(333 + 13, 625 + 13), diameter: 26))
        //Swipe Left
        case 5:
            spotlightView.appear(Spotlight.RoundedRect(center: CGPointMake(5 + 102, 87 + 17), size: CGSizeMake(205, 35), cornerRadius: 6))
        //Swipe Right (case 5)
        case 6:
             spotlightView.appear(Spotlight.RoundedRect(center: CGPointMake(177 + 102, 87 + 17), size: CGSizeMake(293, 35), cornerRadius: 6))
        case 7:
             dismissViewControllerAnimated(true, completion: nil)
        default:
            break
        }
        
        stepIndex += 1
    }
    
    func updateAnnotationView(animated: Bool) {
        annotationViews.enumerate().forEach { index, view in
            UIView .animateWithDuration(animated ? 0.25 : 0) {
                view.alpha = index == self.stepIndex ? 1 : 0
            }
        }
    }
}

extension AnnotationViewController: SpotlightViewControllerDelegate {
    func spotlightViewControllerWillPresent(viewController: SpotlightViewController, animated: Bool) {
        next(false)
    }
    
    func spotlightViewControllerTapped(viewController: SpotlightViewController, isInsideSpotlight: Bool) {
        next(true)
    }
    
    func spotlightViewControllerWillDismiss(viewController: SpotlightViewController, animated: Bool) {
        spotlightView.disappear()
    }

}
