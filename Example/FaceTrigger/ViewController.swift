//
//  ViewController.swift
//  FaceTrigger
//
//  Created by kittenyang@icloud.com on 01/18/2020.
//  Copyright (c) 2020 kittenyang@icloud.com. All rights reserved.
//

import UIKit
import ARFaceTrigger
import ARKit

class ViewController: UIViewController {

    var faceTrigger: ARFaceTrigger?
    @IBOutlet weak var debugLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !ARFaceTrigger.isSupported {
            assert(false, "当前设备不支持脸部识别")
            return
        }
        faceTriggerEnable()
    }
    

}

// MARK: private methods
extension ViewController: ARFaceTriggerDelegate {
    func faceTrackingDidChange(isTracked: Bool) {
        let message = isTracked ? "成功识别" : "失去识别"
        debugLabel.text = message
    }
    
    func onFaceRotateWith(eulerAngles: SCNVector3) {
    }
    
    func onCheekPuffDidChange(side: FeatureSide) {
        switch side {
        case .both(let changed, let triggerd, _,_):
            if changed && triggerd {
                debugLabel.text = "鼓腮"
            }
        default: break
        }
    }
    
    func onMouthPuckerDidChange(side: FeatureSide) {
        switch side {
        case .both(let changed, let triggerd, _, _):
            if changed && triggerd {
                debugLabel.text = "嘟嘴"
            }
        default: break
        }
    }
    
    func onBlinkDidChange(sides: [FeatureSide]) {
        sides.forEach { (side) in
            switch side {
            case .both(let changed, let triggerd, _,_):
                if changed {
                    if triggerd {
                        debugLabel.text = "眨眼"
                    }
                }
            case .left(let changed, let triggerd, _):
                if changed && triggerd {
                    print("左眼眨了")
                }
            case .right(let changed, let triggerd, _):
                if changed && triggerd {
                    print("右眼眨了")
                }
            default: break
            }
        }
    }
    
    func onJawOpenDidChange(side: FeatureSide) {
    }
    
    func onBrowUpDidChange(side: FeatureSide) {
    }
    
    func onTongueOutDidChange(side: FeatureSide) {
    }
    
    func onSmileDidChange(sides: [FeatureSide]) {
        sides.forEach { (side) in
            switch side {
            case .both(let changed, let triggerd, _,_):
                if changed {
                    if triggerd {
                        debugLabel.text = "微笑"
                    }
                }
            default: break
            }
        }
    }
    
    func onJawMoveDidChange(sides: [FeatureSide]) {
        
    }
    
    func onBrowDownDidChange(sides: [FeatureSide]) {
    
    }
    
    func onSquintDidChange(sides: [FeatureSide]) {
    
    }
    
    
}

// MARK: private methods
extension ViewController {
    fileprivate func faceTriggerEnable() {
        NotificationCenter.default.addObserver(self, selector: #selector(pause), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unpause), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
         
        self.faceTrigger = ARFaceTrigger(hostView: self.view, delegate: self)
        self.faceTrigger?.hidePreview = false
        self.faceTrigger?.start()
        
        self.view.insertSubview(debugLabel, aboveSubview: self.faceTrigger!.sceneView!)
     }
}

// MARK: Notification
extension ViewController {
    @objc private func pause() {
        faceTrigger?.pause()
    }
    
    @objc private func unpause() {
        faceTrigger?.unpause()
    }
}

