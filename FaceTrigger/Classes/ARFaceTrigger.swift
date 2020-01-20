//
//  ARFaceTrigger.swift
//  FaceTrigger
//
//  Created by Qitao Yang on 2020/1/18.
//

import UIKit
import ARKit

public enum FeatureSide:Equatable {
    case unknown
    /// changed: true if state changed. For example: eyes opened -> blink or blink -> eyes opened
    /// triggerd: current state. For example: triggerd == true means blink
    /// value: current state value
    /// blendShapes: current ARFaceAnchor.BlendShapeLocation
    case both(_ changed:Bool,_ triggerd:Bool,_ value: Float, _ blendShapes: ARFaceAnchor.BlendShapeLocation)
    case left(_ changed:Bool,_ triggerd:Bool,_ value: Float)
    case right(_ changed:Bool,_ triggerd:Bool,_ value: Float)
    
    var sideDescription: String {
        switch self {
        case .both(_):
            return ""
        case .left(_):
            return "左边,left"
        case .right(_):
            return "右边,right"
        default:
            return "unknown"
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

public protocol ARFaceTriggerDelegate: ARSCNViewDelegate {
    
    func faceTrackingDidChange(isTracked: Bool)
    /// Face rotation(转动头部)
    func onFaceRotateWith(eulerAngles: SCNVector3)
    
    // --- Single ----
    /// Cheek Puff(鼓腮)
    func onCheekPuffDidChange(side: FeatureSide)
    
    /// MouthPucker(嘟嘴)
    func onMouthPuckerDidChange(side: FeatureSide)
    
    /// JawOpen(张嘴)
    func onJawOpenDidChange(side: FeatureSide)
    
    /// BrowUp(挑眉)
    func onBrowUpDidChange(side: FeatureSide)
    
    /// TongueOut(吐舌头)
    func onTongueOutDidChange(side: FeatureSide)
    
    
    // --- Both ----
    /// Smile(微笑)
    func onSmileDidChange(sides: [FeatureSide])
    
    /// Blink(眨眼)
    func onBlinkDidChange(sides: [FeatureSide])
    
    /// JawMove(下巴移动)
    func onJawMoveDidChange(sides: [FeatureSide])
    
    /// BrowDown(皱眉)
    func onBrowDownDidChange(sides: [FeatureSide])

    /// Squint(眯眼)
    func onSquintDidChange(sides: [FeatureSide])
}

extension ARFaceTriggerDelegate {
    func faceTrackingDidChange(isTracked: Bool) {
    }
    func onFaceRotateWith(eulerAngles: SCNVector3) {
    }
    
    // --- Single ----
    func onCheekPuffDidChange(side: FeatureSide) {
    }
    
    func onMouthPuckerDidChange(side: FeatureSide) {
    }
    
    func onJawOpenDidChange(side: FeatureSide) {
    }
    
    func onBrowUpDidChange(side: FeatureSide) {
    }
    
    func onTongueOutDidChange(side: FeatureSide){
    }
    
    // --- Both ----
    func onSmileDidChange(sides: [FeatureSide]) {
    }
    
    func onBlinkDidChange(sides: [FeatureSide]) {
    }
    
    func onJawMoveDidChange(sides: [FeatureSide]) {
    }
    
    func onBrowDownDidChange(sides: [FeatureSide]) {
    }

    func onSquintDidChange(sides: [FeatureSide]) {
    }
}

public class ARFaceTrigger: NSObject {
    
    func resetFaceToUnTracked() {
        self.faceTracked = false
    }
    
    public weak var sceneView: ARSCNView?
    private let sceneViewSessionOptions: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
    private weak var hostView: UIView?
    private weak var delegate: ARFaceTriggerDelegate?
    private var evaluators = [ARFaceTriggerEvaluatorProtocol]()
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
    
    public init(hostView: UIView, delegate: ARFaceTriggerDelegate) {

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
        
        guard ARFaceTrigger.isSupported else {
            print("FaceTrigger is not supported.")
            return
        }
        
        guard let `hostView` = hostView else {
            return
        }
        
        addAllEvaluators()
        
        // ARSCNView
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        let sceneView = ARSCNView(frame: hostView.bounds)
        sceneView.automaticallyUpdatesLighting = true
        sceneView.session.run(configuration, options: sceneViewSessionOptions)
        sceneView.isHidden = hidePreview
        sceneView.delegate = self
        
        hostView.addSubview(sceneView)
        self.sceneView = sceneView
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

extension ARFaceTrigger: ARSCNViewDelegate {

    public func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let `sceneView` = sceneView, !self.hidePreview else {
            return nil
        }
        
        let faceMesh = ARSCNFaceGeometry(device: sceneView.device!)
        let node = SCNNode(geometry: faceMesh)
        node.geometry?.firstMaterial?.fillMode = .lines
        return node
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor, let `delegate` = delegate else {
            return
        }
        if let faceGeometry = node.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
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
    
}

// MARK: private
extension ARFaceTrigger {
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
    
    fileprivate func detectFaceNode(face: ARFaceAnchor) {
        if face.isTracked != faceTracked {
            DispatchQueue.main.async {
                self.delegate?.faceTrackingDidChange(isTracked: face.isTracked)
            }
        }
        faceTracked = face.isTracked
    }
}






