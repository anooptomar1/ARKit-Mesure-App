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
    @IBOutlet weak var trackingState: UILabel!
    
    // @IBOutlet weak var textEfView: UIVisualEffectView!
    
    private var startNode: SCNNode?
    private var endNode: SCNNode?
    private var lineNode: SCNNode?
    
    @IBAction func restartButtonTap(_ sender: UIButton) {
        resetTracking()
        resetObjects()
        setupFocusSquare()
        setupUIControls()
    }
    
    @objc func timerAction() {

    }
    
    var WorldConf: ARWorldTrackingConfiguration {
        return ARWorldTrackingConfiguration()
    }
    
    var focusSquare = FocusSquare()
    
    func setupFocusSquare() {
        focusSquare.unhide()
        focusSquare.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(focusSquare)
    }
    
    func setupUIControls() {
        // Set appearance of message output panel
        labelT.layer.cornerRadius = 3
        labelT.clipsToBounds = true
        labelT.isHidden = true
        labelT.backgroundColor = UIColor.white
        labelT.sizeToFit()
        labelT.text = ""
        //textEfView.sizeToFit()
    }
    
    func setupTracking() {
        trackingState.text = ""
        trackingState.sizeToFit()
        trackingState.layer.cornerRadius = 3
        trackingState.clipsToBounds = true
    }
    
    func updateFocusSquare() {
        let (worldPosition, planeAnchor, _) = worldPositionFromScreenPosition(view.center, objectPos: focusSquare.position)
        if let worldPosition = worldPosition {
            focusSquare.update(for: worldPosition, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
       // sceneView.session.delegate = self as! ARSessionDelegate
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTapGesture))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Set up scene content.
        setupCamera()
        resetTracking()
        resetObjects()
        setupFocusSquare()
        setupUIControls()
        setupTracking()
    }
    
    @objc func handleTapGesture(sender: UITapGestureRecognizer) {
        if sender.state != .ended {
            return
        }
        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }
        
        if let endNode = endNode {
            // Reset
            startNode?.removeFromParentNode()
            self.startNode = nil
            endNode.removeFromParentNode()
            self.endNode = nil
          //  resetTracking()
            resetObjects()
            setupUIControls()
            return
        }
        
        let planeHitTestResults = sceneView.hitTest(view.center, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            let hitPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let sphere = SCNSphere(radius: 0.0005)
            sphere.firstMaterial?.diffuse.contents = UIColor.white
            sphere.firstMaterial?.lightingModel = .constant
            sphere.firstMaterial?.isDoubleSided = true
            let node = SCNNode(geometry: sphere)
            node.position = hitPosition
            sceneView.scene.rootNode.addChildNode(node)
            
            if let startNode = startNode {
                endNode = node
                let vector = startNode.position - node.position
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.roundingMode = .ceiling
                formatter.maximumFractionDigits = 2
                // Scene units map to meters in ARKit.
                labelT.text = " Distance: " + formatter.string(from: NSNumber(value: vector.length()))! + "m "
                labelT.isHidden = false
                labelT.sizeToFit()
                
            }
            else {
                startNode = node
            }
        }
        else {
            // Create a transform with a translation of 0.1 meters (10 cm) in front of the camera
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.1
            
            // Add a node to the session
            let sphere = SCNSphere(radius: 0.0005)
            sphere.firstMaterial?.diffuse.contents = UIColor.white
            
            sphere.firstMaterial?.lightingModel = .constant
            sphere.firstMaterial?.isDoubleSided = true
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.simdTransform = simd_mul(currentFrame.camera.transform, translation)
            sceneView.scene.rootNode.addChildNode(sphereNode)
            
            if let startNode = startNode {
                endNode = sphereNode
                labelT.text = " Distance: " + String(format: "%.2f", distance(startNode: startNode, endNode: sphereNode)) + "m "
                labelT.isHidden = false
                labelT.sizeToFit()
            }
            else {
                startNode = sphereNode
            }
        }
        if let start = startNode, let end = endNode {
            let line = lineFrom(vector: start.position, toVector: end.position)
            lineNode = SCNNode(geometry: line)
            lineNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sceneView.scene.rootNode.addChildNode(lineNode!)
        }
    }
    
    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
        
    }
    
    func distance(startNode: SCNNode, endNode: SCNNode) -> Float {
        let vector = SCNVector3Make(startNode.position.x - endNode.position.x, startNode.position.y - endNode.position.y, startNode.position.z - endNode.position.z)
        // Scene units map to meters in ARKit.
        return sqrtf(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    }
    
    var dragOnInfinitePlanesEnabled = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
    }
    
    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func resetObjects() {
        
        startNode?.removeFromParentNode()
        endNode?.removeFromParentNode()
        lineNode?.removeFromParentNode()
        startNode = nil
        endNode = nil
        lineNode = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        resetTracking()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
        }
    }
    
    func createBall(position: SCNVector3) {
        let ballShape = SCNSphere(radius: 0.01)
        let ballNode = SCNNode(geometry: ballShape)
        ballNode.position = position
        sceneView.scene.rootNode.addChildNode(ballNode)
        objects.append(ballNode)
    }
    
    var session: ARSession {
        return sceneView.session
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
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            trackingState.text = " Not available "
            trackingState.isHidden = false
            trackingState.backgroundColor = .red
        case .normal:
            trackingState.text = " Normal "
            trackingState.isHidden = false
            trackingState.backgroundColor = .green
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                trackingState.text = " Excessive motion "
            case .insufficientFeatures:
                trackingState.text = " Insufficient features "
            case .initializing:
                trackingState.text = " Initializing "
                
            }
            trackingState.backgroundColor = .yellow
            
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {

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


extension ViewController {
    
    // Code from Apple PlacingObjects demo: https://developer.apple.com/sample-code/wwdc/2017/PlacingObjects.zip
    
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).
        
        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
}
