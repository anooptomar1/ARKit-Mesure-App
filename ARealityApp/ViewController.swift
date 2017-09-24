//
//  ViewController.swift
//  ARealityApp
//
//  Created by Artyom on 23/09/2017.
//  Copyright © 2017 sDynamics. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var objects = [SCNNode]()
    var timer = Timer()
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var labelT: UILabel!
    
    @IBAction func restartButtonTap(_ sender: UIButton) {
        resetTracking()
        resetObjects()
   /*     timer.invalidate()
        DispatchQueue.main.async {
            self.statusLabel.text = " Resetting "
            self.statusLabel.backgroundColor = UIColor(white: 1, alpha: 0.5)
            self.timer = Timer.scheduledTimer(timeInterval: 6, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: false)
        } */
    }
    
    @objc func timerAction() {
      //  statusLabel.text = ""
      //  statusLabel.backgroundColor = UIColor.clear
    }
    
    var WorldConf: ARWorldTrackingConfiguration {
        return ARWorldTrackingConfiguration()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
       // sceneView.session.delegate = self as! ARSessionDelegate
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        setupCamera()
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Set up scene content.
        
        /*
         The `sceneView.automaticallyUpdatesLighting` option creates an
         ambient light source and modulates its intensity. This sample app
         instead modulates a global lighting environment map for use with
         physically based materials, so disable automatic lighting.
         */

    }

    
   /* func reset() {
        sceneView.session.run(configuration, options: [ARSession.RunOptions.resetTracking, ARSession.RunOptions.removeExistingAnchors])
    } */
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
      /*  DispatchQueue.main.async {
            self.statusLabel.text = " Loading "
            self.statusLabel.backgroundColor = UIColor(white: 1, alpha: 0.5)
            self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: false)
        } */
    }
    
    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func resetObjects() {
        for obj in objects {
            obj.removeFromParentNode()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        resetTracking()
    }
    
    func createBall(position: SCNVector3) {
        let ballShape = SCNSphere(radius: 0.01)
        let ballNode = SCNNode(geometry: ballShape)
        ballNode.position = position
        sceneView.scene.rootNode.addChildNode(ballNode)
        objects.append(ballNode)
        
    }
    
    /* func setupARSession() {
        
        let configuration = ARWorldTrackingConfiguration()
        //configuration.worldAlignment = .gravityAndHeading
      //  guard let session = sceneView else { print("nill")
         //   return }
        session.run(configuration, options: ARSession.RunOptions.resetTracking)
        
    } */
    
    var session: ARSession {
        return sceneView.session
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let result = sceneView.hitTest(touch.location(in: sceneView),types: [ARHitTestResult.ResultType.featurePoint])
        guard let hitResult = result.last else { return }
        let hitTransform = SCNMatrix4((hitResult.worldTransform))
        let hitVector = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
        createBall(position: hitVector)
    }
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // let currentTransform = frame.camera.transform
        let nodePos1 = objects[0].presentation.simdTransform
        let nodePos2 = frame.camera.transform
        
        let distance = nodePos1 - nodePos2
        labelT.text = "\(distance)"
        print("Hi")

    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user

    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
