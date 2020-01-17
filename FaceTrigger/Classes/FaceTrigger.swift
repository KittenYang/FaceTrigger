//
//  FaceTrigger.swift
//  FaceTrigger
//
//  Created by Michael Peterson on 12/26/17.
//  Copyright © 2017 Blinkloop. All rights reserved.
//

import UIKit
import ARKit

public enum FeatureSide:Equatable {
    case unknown
    case both(_ changed:Bool,_ triggerd:Bool,_ value: Float, _ blendShapes: ARFaceAnchor.BlendShapeLocation)
    case left(_ changed:Bool,_ triggerd:Bool,_ value: Float)
    case right(_ changed:Bool,_ triggerd:Bool,_ value: Float)
    
    var sideDescription: String {
        switch self {
        case .both(_):
            return ""
        case .left(_):
            return "左边left"
        case .right(_):
            return "右边right"
        default:
            return "未知"
        }
    }
    
    #if swift(>=4.1)
    #else
    func ==(lhs: FeatureSide, rhs: FeatureSide) -> Bool {
        switch (lhs, rhs) {
        case (let .both(_), let .both(_)):
            return true
        case (let .left(_), let .left(_)):
            return true
        case (let .right(_), let .right(_)):
            return true
        case (let .unknown, let .unknown):
            return true
        default:
            return false
        }
    }
    #endif
}

public protocol FaceTriggerDelegate: ARSCNViewDelegate {
    
    func faceTrackingDidChange(isTracked: Bool)
    //转动脖子
    func onFaceRotateWith(eulerAngles: SCNVector3)
    
    // --- Single ----
    //鼓腮
    func onCheekPuffDidChange(side: FeatureSide)
    
    //嘟嘴
    func onMouthPuckerDidChange(side: FeatureSide)
    
    //张嘴
    func onJawOpenDidChange(side: FeatureSide)
    
    //挑眉
    func onBrowUpDidChange(side: FeatureSide)
    
    //吐舌头
    func onTongueOutDidChange(side: FeatureSide)
    
    
    // --- Both ----
    //微笑
    func onSmileDidChange(sides: [FeatureSide])
    
    //眨眼
    func onBlinkDidChange(sides: [FeatureSide])
    
    //下巴移动
    func onJawMoveDidChange(sides: [FeatureSide])
    
    //皱眉
    func onBrowDownDidChange(sides: [FeatureSide])

    // 眯眼
    func onSquintDidChange(sides: [FeatureSide])
}

extension FaceTriggerDelegate {
    func faceTrackingDidChange(isTracked: Bool) {
    }
    //转动脖子
    func onFaceRotateWith(eulerAngles: SCNVector3) {        
    }
    
    // --- Single ----
    //鼓腮
    func onCheekPuffDidChange(side: FeatureSide) {
    }
    
    //嘟嘴
    func onMouthPuckerDidChange(side: FeatureSide) {
    }
    
    //张嘴
    func onJawOpenDidChange(side: FeatureSide) {
    }
    
    //挑眉
    func onBrowUpDidChange(side: FeatureSide) {
    }
    
    //吐舌头
    func onTongueOutDidChange(side: FeatureSide){
    }
    
    // --- Both ----
    //微笑
    func onSmileDidChange(sides: [FeatureSide]) {
    }
    
    //眨眼
    func onBlinkDidChange(sides: [FeatureSide]) {
    }
    
    //下巴移动
    func onJawMoveDidChange(sides: [FeatureSide]) {
    }
    
    //皱眉
    func onBrowDownDidChange(sides: [FeatureSide]) {
    }

    // 眯眼
    func onSquintDidChange(sides: [FeatureSide]) {
    }
}

public class FaceTrigger: NSObject {
    
    func resetFaceToUnTracked() {
        self.faceTracked = false
    }
    
    var sceneView: ARSCNView?
    private let sceneViewSessionOptions: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
    private let hostView: UIView
    private weak var delegate: FaceTriggerDelegate?
    private var evaluators = [FaceTriggerEvaluatorProtocol]()
    private var faceTracked:Bool = false
    
    public var smileThreshold: Float = 0.4
    public var blinkThreshold: Float = 0.7
    public var browDownThreshold: Float = 0.2
    public var browUpThreshold: Float = 0.6
    public var cheekPuffThreshold: Float = 0.2
    public var mouthPuckerThreshold: Float = 0.7
    public var jawOpenThreshold: Float = 0.6
    public var tongueOutThreshold: Float = 0.6
    
    public var hidePreview: Bool = false
    
    public init(hostView: UIView, delegate: FaceTriggerDelegate) {

        self.hostView = hostView
        self.delegate = delegate
    }
    
    static public var isSupported: Bool {
        return ARFaceTrackingConfiguration.isSupported
    }
    
    public func addAllEvaluators() {
        // evaluators
        evaluators.append(SmileEvaluator(threshold: smileThreshold))
        evaluators.append(BlinkEvaluator(threshold: blinkThreshold))
        evaluators.append(BrowDownEvaluator(threshold: browDownThreshold))
        evaluators.append(BrowUpEvaluator(threshold: browUpThreshold))
        evaluators.append(CheekPuffEvaluator(threshold: cheekPuffThreshold))
        evaluators.append(MouthPuckerEvaluator(threshold: mouthPuckerThreshold))
        evaluators.append(JawOpenEvaluator(threshold: jawOpenThreshold))
        if #available(iOS 12.0, *) {
            evaluators.append(TongueOutEvaluator(threshold: tongueOutThreshold))
        }
    }
    
    public func start() {
        
        guard FaceTrigger.isSupported else {
            NSLog("FaceTrigger is not supported.")
            return
        }
        
        addAllEvaluators()
        
        // ARSCNView
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        sceneView = ARSCNView(frame: hostView.bounds)
        sceneView!.automaticallyUpdatesLighting = true
        sceneView!.session.run(configuration, options: sceneViewSessionOptions)
        sceneView!.isHidden = hidePreview
        sceneView!.delegate = self
        
        hostView.addSubview(sceneView!)
    }
    
    public func stop() {
        
        pause()
        sceneView?.removeFromSuperview()
    }
    
    public func pause() {
        
        sceneView?.session.pause()
    }
    
    public func unpause() {
        
        if let configuration = sceneView?.session.configuration {
            sceneView?.session.run(configuration, options: sceneViewSessionOptions)
        }
    }
    
}

extension FaceTrigger: ARSCNViewDelegate {
    fileprivate func detectFaceNode(face: ARFaceAnchor) {
        if face.isTracked != faceTracked {
            DispatchQueue.main.async {
                self.delegate?.faceTrackingDidChange(isTracked: face.isTracked)
            }
        }
        faceTracked = face.isTracked
    }
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor, let `delegate` = delegate else {
            return
        }
        detectFaceNode(face:faceAnchor)
        DispatchQueue.main.async {
            delegate.onFaceRotateWith(eulerAngles: self.calculateEulerAngles(faceAnchor))
        }
        let blendShapes = faceAnchor.blendShapes
        evaluators.forEach {
            $0.evaluate(blendShapes, forDelegate: delegate)
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        debugPrint("FaceTrigger:Detect face the first time!")
    }
    
}

extension FaceTrigger {
    fileprivate func calculateEulerAngles(_ faceAnchor: ARFaceAnchor) -> SCNVector3 {
        // Based on StackOverflow answer https://stackoverflow.com/a/53434356/3599895
        let projectionMatrix = self.sceneView?.session.currentFrame?.camera.projectionMatrix(for: .portrait, viewportSize: self.sceneView!.bounds.size, zNear: 0.001, zFar: 1000)
        let viewMatrix = self.sceneView?.session.currentFrame?.camera.viewMatrix(for: .portrait)
        let projectionViewMatrix = simd_mul(projectionMatrix!, viewMatrix!)
        let modelMatrix = faceAnchor.transform
        let mvpMatrix = simd_mul(projectionViewMatrix, modelMatrix)
        // This allows me to just get a .x .y .z rotation from the matrix, without having to do crazy calculations
        let newFaceMatrix = SCNMatrix4.init(mvpMatrix)
        let faceNode = SCNNode()
        faceNode.transform = newFaceMatrix
        let rotation = vector_float3(faceNode.worldOrientation.x, faceNode.worldOrientation.y, faceNode.worldOrientation.z)
        let yaw = (rotation.y*3)
        let pitch = (rotation.x*3)
        let roll = (rotation.z*1.5)
        let absoluteEulerAngle = SCNVector3(pitch, yaw, roll)
        return absoluteEulerAngle
    }
}





