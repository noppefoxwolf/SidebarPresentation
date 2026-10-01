//
//  InteractiveContainerPanGestureRecognizer.swift
//  GestureSample
//

import UIKit

/// A full-screen pan recognizer whose policies are supplied through `behavior`.
@MainActor
package final class InteractiveContainerPanGestureRecognizer: UIPanGestureRecognizer,
    UIGestureRecognizerDelegate
{

    enum Direction {
        case left
        case right
        case up
        case down
    }

    var behavior: [Behavior] = [.pageViewController, .scrollView, .popInteraction]
    var direction: Direction = .right
    var isDebugLoggingEnabled = false
    package var shouldBeginHandler: (() -> Bool)?

    weak var trackedTouchView: UIView?

    package override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        delegate = self
    }

    required convenience init?(coder: NSCoder) {
        self.init(target: nil, action: nil)
    }

    package override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
        if isDebugLoggingEnabled {
            print(
                "[GestureDebug] canPrevent "
                    + "other=\(type(of: preventedGestureRecognizer))#\(ObjectIdentifier(preventedGestureRecognizer)) -> false"
            )
        }
        return false
    }

    package override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer)
        -> Bool
    {
        if isDebugLoggingEnabled {
            print(
                "[GestureDebug] canBePrevented "
                    + "by=\(type(of: preventingGestureRecognizer))#\(ObjectIdentifier(preventingGestureRecognizer)) -> true"
            )
        }
        return true
    }
}
