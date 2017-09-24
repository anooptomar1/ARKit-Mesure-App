//
//  StatusViewController.swift
//  ARealityApp
//
//  Created by Artyom on 23/09/2017.
//  Copyright © 2017 sDynamics. All rights reserved.
//

import UIKit

class StatusViewController: UIViewController {
    
   var viewc = ViewController()
    
    @IBOutlet weak var restartButton: UIButton!
    
    var restartExperienceHandler: () -> Void = {
        let configuration = ViewController().WorldConf
        //ViewController().resetTracking()
        ViewController().session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   @IBAction private func restartButtonTap(_ sender: UIButton) {
        print("Hello")
         restartExperienceHandler()
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
