//
//  FaceTriggerEvaluators.swift
//  FaceTrigger
//
//  Created by Mike Peterson on 12/27/17.
//  Copyright © 2017 Blinkloop. All rights reserved.
//

import ARKit

protocol FaceTriggerEvaluatorProtocol {
    var threshold: Float { get set }
    var keys: [ARFaceAnchor.BlendShapeLocation] { get set }
    
    init(threshold: Float)
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate)
}

class SingleEvaluator: FaceTriggerEvaluatorProtocol {
    var threshold: Float = 0.0
    var keys: [ARFaceAnchor.BlendShapeLocation] = []

    private var oldValue: Bool = false
    
    required init(threshold: Float) {
        self.threshold = threshold
    }
    
    func onSingle(_ delegate: FaceTriggerDelegate, _ side: FeatureSide) {
    }
    
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        if let singleKey = keys.first, let browInnerUp = blendShapes[singleKey] {
            let newValue = browInnerUp.floatValue >= threshold
            let side = FeatureSide.both(newValue != self.oldValue, newValue, browInnerUp.floatValue, singleKey)
            DispatchQueue.main.async {
                self.onSingle(delegate, side)
            }
            oldValue = newValue
        }
    }
}


// MARK: BrowUpEvaluator
class BrowUpEvaluator: SingleEvaluator {
    required init(threshold: Float) {
        super.init(threshold: threshold)
        self.keys = [.browInnerUp]
    }
    override func onSingle(_ delegate: FaceTriggerDelegate, _ side: FeatureSide) {
        delegate.onBrowUpDidChange(side: side)
    }
}


// MARK: CheekPuffEvaluator
class CheekPuffEvaluator: SingleEvaluator {
    required init(threshold: Float) {
        super.init(threshold: threshold)
        self.keys = [.cheekPuff]
    }
    override func onSingle(_ delegate: FaceTriggerDelegate, _ side: FeatureSide) {
        delegate.onCheekPuffDidChange(side: side)
    }
    
}

// MARK: MouthPuckerEvaluator
class MouthPuckerEvaluator: SingleEvaluator {
    required init(threshold: Float) {
        super.init(threshold: threshold)
        self.keys = [.mouthPucker]
    }
    override func onSingle(_ delegate: FaceTriggerDelegate, _ side: FeatureSide) {
        delegate.onMouthPuckerDidChange(side: side)
    }
}

// MARK: JawOpenEvaluator
class JawOpenEvaluator: SingleEvaluator {
    required init(threshold: Float) {
        super.init(threshold: threshold)
        self.keys = [.jawOpen]
    }
    override func onSingle(_ delegate: FaceTriggerDelegate, _ side: FeatureSide) {
        delegate.onJawOpenDidChange(side: side)
    }
}

// MARK: TongueOutEvaluator
@available(iOS 12.0, *)
class TongueOutEvaluator: SingleEvaluator {
    required init(threshold: Float) {
        super.init(threshold: threshold)
        self.keys = [.tongueOut]
    }
    override func onSingle(_ delegate: FaceTriggerDelegate, _ side: FeatureSide) {
        delegate.onTongueOutDidChange(side: side)
    }
}


// ------------------------------------------------------------------------

// MARK: ---- Both -----
class BothEvaluator: FaceTriggerEvaluatorProtocol {
    var threshold: Float = 0.0
    var keys: [ARFaceAnchor.BlendShapeLocation] = []

    private var oldLeft  = false
    private var oldRight  = false
    private var oldBoth  = false
    
    required init(threshold: Float) {
        self.threshold = threshold
    }
    
    func onBoth(_ delegate: FaceTriggerDelegate, _ sides: [FeatureSide]) {
    }
    
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        // note that "left" and "right" blend shapes are mirrored so they are opposite from what a user would consider "left" or "right"
        guard let leftKey = keys.first, let rightKey = keys.last else {
            return
        }
        let left = blendShapes[rightKey]
        let right = blendShapes[leftKey]
        
        var newLeft = false
        if let left = left {
            newLeft = left.floatValue >= threshold
        }

        var newRight = false
        if let right = right {
            newRight = right.floatValue >= threshold
        }
        let newBoth = newLeft && newRight

        let bothSide = FeatureSide.both(newBoth != oldBoth,
                                     newBoth,
                                     ((left?.floatValue ?? 0.0) + (right?.floatValue ?? 0.0)) / 2, leftKey)
        let leftSide = FeatureSide.left(newLeft != oldLeft,
                                     newLeft,
                                     (left?.floatValue ?? 0.0))
        let rightSide = FeatureSide.right(newRight != oldRight,
                                       newRight,
                                       (right?.floatValue ?? 0.0))
        
        let sides = [bothSide,leftSide,rightSide]
        DispatchQueue.main.async {
            self.onBoth(delegate, sides)
        }
        
        oldBoth = newBoth
        oldLeft = newLeft
        oldRight = newRight
    }
}

// MARK: SmileEvaluator
class SmileEvaluator: BothEvaluator {
    required init(threshold: Float) {
        super.init(threshold: threshold)
        self.keys = [.mouthSmileLeft,.mouthSmileRight]
    }
    override func onBoth(_ delegate: FaceTriggerDelegate, _ sides: [FeatureSide]) {
        delegate.onSmileDidChange(sides: sides)
    }
}


// MARK: BlinkEvaluator
class BlinkEvaluator: BothEvaluator {
    required init(threshold: Float) {
        super.init(threshold: threshold)
        self.keys = [.eyeBlinkLeft,.eyeBlinkRight]
    }
    override func onBoth(_ delegate: FaceTriggerDelegate, _ sides: [FeatureSide]) {
        delegate.onBlinkDidChange(sides: sides)
    }
}

// MARK: BrowDownEvaluator
class BrowDownEvaluator: BothEvaluator {
    required init(threshold: Float) {
        super.init(threshold: threshold)
        self.keys = [.browDownLeft,.browDownRight]
    }
    override func onBoth(_ delegate: FaceTriggerDelegate, _ sides: [FeatureSide]) {
        delegate.onBrowDownDidChange(sides: sides)
    }
}

// MARK: SquintEvaluator
class SquintEvaluator: BothEvaluator {
    required init(threshold: Float) {
        super.init(threshold: threshold)
        self.keys = [.eyeSquintLeft,.eyeSquintRight]
    }
    override func onBoth(_ delegate: FaceTriggerDelegate, _ sides: [FeatureSide]) {
        delegate.onSquintDidChange(sides: sides)
    }
}


// MARK: JawMoveEvaluator
class JawMoveEvaluator: BothEvaluator {

    required init(threshold: Float) {
        super.init(threshold: threshold)
        self.keys = [.jawLeft,.jawRight]
    }
    override func onBoth(_ delegate: FaceTriggerDelegate, _ sides: [FeatureSide]) {
        delegate.onJawMoveDidChange(sides: sides)
    }
}



