//
//  InteractiveContainerPanGestureRecognizer+Behavior.swift
//  GestureSample
//

import UIKit

@MainActor
extension InteractiveContainerPanGestureRecognizer {

    enum BehaviorEvent {
        case shouldReceive(touch: UITouch, scrollViews: [UIScrollView])
        case shouldBegin(location: CGPoint, velocity: CGPoint, scrollViews: [UIScrollView])
        case shouldRecognizeSimultaneously(other: UIGestureRecognizer)
        case shouldRequireFailureOf(other: UIGestureRecognizer)
        case shouldBeRequiredToFailBy(other: UIGestureRecognizer)
    }

    enum BehaviorDecision {
        case allow
        case deny
        case ignore
    }

    @MainActor
    struct Behavior {
        typealias Handler = (InteractiveContainerPanGestureRecognizer, BehaviorEvent) ->
            BehaviorDecision

        private let handler: Handler

        private init(handler: @escaping Handler) {
            self.handler = handler
        }

        /// Creates a behavior that can participate in every gesture decision.
        static func custom(_ handler: @escaping Handler) -> Behavior {
            Behavior(handler: handler)
        }

        /// Gives the custom pan priority when all ancestor scroll views are at their edges.
        static let scrollView = Behavior.custom { recognizer, event in
            switch event {
            case .shouldReceive(let touch, _):
                recognizer.requireScrollViewsToWait(for: touch.view)
                return .ignore

            case .shouldBegin(_, _, let scrollViews):
                return scrollViews.contains {
                    !recognizer.isAtBoundary(of: $0)
                } ? .deny : .ignore

            default:
                return .ignore
            }
        }

        /// Gives a scroll-style page view controller priority when a page exists in the swipe direction.
        static let pageViewController = Behavior.custom { recognizer, event in
            guard case .shouldBegin(_, let velocity, let scrollViews) = event,
                recognizer.matchesDirection(velocity),
                let scrollView = scrollViews.first,
                let pageViewController = recognizer.pageViewController(containing: scrollView),
                let currentViewController = pageViewController.viewControllers?.first,
                let dataSource = pageViewController.dataSource
            else {
                return .ignore
            }

            let adjacentViewController: UIViewController?
            switch recognizer.direction {
            case .right, .down:
                adjacentViewController = dataSource.pageViewController(
                    pageViewController,
                    viewControllerBefore: currentViewController
                )
            case .left, .up:
                adjacentViewController = dataSource.pageViewController(
                    pageViewController,
                    viewControllerAfter: currentViewController
                )
            }

            return adjacentViewController == nil ? .ignore : .deny
        }

        /// Gives the system navigation pop transition priority over the custom pan.
        static let popInteraction = Behavior.custom { recognizer, event in
            switch event {
            case .shouldRequireFailureOf(let other):
                return recognizer.isNavigationTransitionGesture(other)
                    ? .allow
                    : .ignore

            default:
                return .ignore
            }
        }

        fileprivate func evaluate(
            with recognizer: InteractiveContainerPanGestureRecognizer,
            event: BehaviorEvent
        ) -> BehaviorDecision {
            handler(recognizer, event)
        }
    }

    package func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard gestureRecognizer === self, let rootView = view else {
            return true
        }

        trackedTouchView = touch.view
        let scrollViews = ancestorScrollViews(from: touch.view)
        let event = BehaviorEvent.shouldReceive(
            touch: touch,
            scrollViews: scrollViews
        )
        let shouldReceive = !decisions(for: event).contains(where: isDenied)
        let location = touch.location(in: rootView)
        log(
            "shouldReceive touch location=\(location) "
                + "view=\(viewDescription(touch.view)) "
                + "scrollViews=[\(scrollViews.map { viewDescription($0) }.joined(separator: ", "))] "
                + "-> \(shouldReceive)"
        )
        logGestureContext(at: location)
        return shouldReceive
    }

    package func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === self, let rootView = view else {
            return true
        }
        guard shouldBeginHandler?() ?? true else {
            return false
        }

        let location = location(in: rootView)
        let velocity = velocity(in: rootView)
        return shouldBegin(
            location: location,
            velocity: velocity,
            scrollViews: ancestorScrollViews(from: trackedTouchView)
        )
    }

    /// Compatibility overload for callers that only have one scroll view.
    package func shouldBegin(
        location: CGPoint,
        velocity: CGPoint,
        scrollView: UIScrollView?
    ) -> Bool {
        shouldBegin(
            location: location,
            velocity: velocity,
            scrollViews: scrollView.map { [$0] } ?? []
        )
    }

    package func shouldBegin(
        location: CGPoint,
        velocity: CGPoint,
        scrollViews: [UIScrollView]
    ) -> Bool {
        let hasMatchingDirection = matchesDirection(velocity)
        let isAtScrollViewBoundary = scrollViews.allSatisfy {
            isAtBoundary(of: $0)
        }
        let event = BehaviorEvent.shouldBegin(
            location: location,
            velocity: velocity,
            scrollViews: scrollViews
        )
        let shouldBegin =
            hasMatchingDirection
            && !decisions(for: event).contains(where: isDenied)
        log(
            "shouldBegin "
                + "location=\(location) "
                + "velocity=\(velocity) "
                + "direction=\(direction) "
                + "atBoundary=\(isAtScrollViewBoundary) -> \(shouldBegin)"
        )
        return shouldBegin
    }

    package func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === self else {
            return false
        }

        let event = BehaviorEvent.shouldRecognizeSimultaneously(
            other: otherGestureRecognizer
        )
        let decisions = decisions(for: event)
        let shouldRecognizeSimultaneously =
            !decisions.contains(where: isDenied)
            && decisions.contains(where: isAllowed)
        log(
            "simultaneous "
                + "other=\(recognizerDescription(otherGestureRecognizer)) "
                + "-> \(shouldRecognizeSimultaneously)"
        )
        return shouldRecognizeSimultaneously
    }

    package func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === self else {
            return false
        }

        let event = BehaviorEvent.shouldRequireFailureOf(
            other: otherGestureRecognizer
        )
        let decisions = decisions(for: event)
        let shouldRequireFailure =
            !decisions.contains(where: isDenied)
            && decisions.contains(where: isAllowed)
        log(
            "shouldRequireFailureOf "
                + "other=\(recognizerDescription(otherGestureRecognizer)) "
                + "-> \(shouldRequireFailure)"
        )
        return shouldRequireFailure
    }

    package func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === self else {
            return false
        }

        let event = BehaviorEvent.shouldBeRequiredToFailBy(
            other: otherGestureRecognizer
        )
        let decisions = decisions(for: event)
        let shouldBeRequiredToFailBy =
            !decisions.contains(where: isDenied)
            && decisions.contains(where: isAllowed)
        log(
            "shouldBeRequiredToFailBy "
                + "other=\(recognizerDescription(otherGestureRecognizer)) "
                + "-> \(shouldBeRequiredToFailBy)"
        )
        return shouldBeRequiredToFailBy
    }

    private func decisions(for event: BehaviorEvent) -> [BehaviorDecision] {
        behavior.map { $0.evaluate(with: self, event: event) }
    }

    private func isDenied(_ decision: BehaviorDecision) -> Bool {
        if case .deny = decision {
            return true
        }
        return false
    }

    private func isAllowed(_ decision: BehaviorDecision) -> Bool {
        if case .allow = decision {
            return true
        }
        return false
    }

    fileprivate func isNavigationTransitionGesture(_ gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        guard
            gestureRecognizer is UIPanGestureRecognizer
                || gestureRecognizer is UIScreenEdgePanGestureRecognizer,
            let gestureView = gestureRecognizer.view,
            let navigationController = navigationController(containing: gestureView),
            navigationController.view === gestureView,
            navigationController.viewControllers.count > 1
        else {
            return false
        }

        return true
    }

    private func matchesDirection(_ velocity: CGPoint) -> Bool {
        switch direction {
        case .left:
            return velocity.x < 0 && abs(velocity.x) >= abs(velocity.y)
        case .right:
            return velocity.x > 0 && abs(velocity.x) >= abs(velocity.y)
        case .up:
            return velocity.y < 0 && abs(velocity.y) >= abs(velocity.x)
        case .down:
            return velocity.y > 0 && abs(velocity.y) >= abs(velocity.x)
        }
    }

    private func ancestorScrollViews(from view: UIView?) -> [UIScrollView] {
        var scrollViews: [UIScrollView] = []
        var currentView = view

        while let current = currentView {
            if let scrollView = current as? UIScrollView {
                scrollViews.append(scrollView)
            }
            currentView = current.superview
        }

        return scrollViews
    }

    fileprivate func pageViewController(containing view: UIView?) -> UIPageViewController? {
        var responder: UIResponder? = view

        while let currentResponder = responder {
            if let pageViewController = currentResponder as? UIPageViewController {
                return pageViewController
            }

            responder = currentResponder.next
        }

        return nil
    }

    fileprivate func requireScrollViewsToWait(for view: UIView?) {
        for scrollView in ancestorScrollViews(from: view) {
            scrollView.panGestureRecognizer.require(toFail: self)
        }
    }

    fileprivate func isAtBoundary(of scrollView: UIScrollView) -> Bool {
        let inset = scrollView.adjustedContentInset
        let tolerance: CGFloat = 1

        switch direction {
        case .left:
            let minimumOffset = -inset.left
            let maximumOffset = max(
                minimumOffset,
                scrollView.contentSize.width
                    - scrollView.bounds.width
                    + inset.right
            )
            return scrollView.contentOffset.x >= maximumOffset - tolerance

        case .right:
            let minimumOffset = -inset.left
            return scrollView.contentOffset.x <= minimumOffset + tolerance

        case .up:
            let minimumOffset = -inset.top
            let maximumOffset = max(
                minimumOffset,
                scrollView.contentSize.height
                    - scrollView.bounds.height
                    + inset.bottom
            )
            return scrollView.contentOffset.y >= maximumOffset - tolerance

        case .down:
            let minimumOffset = -inset.top
            return scrollView.contentOffset.y <= minimumOffset + tolerance
        }
    }

    private func navigationController(containing view: UIView) -> UINavigationController? {
        var responder: UIResponder? = view

        while let currentResponder = responder {
            if let navigationController = currentResponder as? UINavigationController {
                return navigationController
            }

            responder = currentResponder.next
        }

        return nil
    }

    private func logGestureContext(at location: CGPoint) {
        guard let rootView = view else {
            return
        }

        guard let hitView = rootView.hitTest(location, with: nil) else {
            log("context hitView=nil")
            return
        }

        log("context hitView=\(viewDescription(hitView))")

        var currentView: UIView? = hitView
        while let current = currentView {
            let recognizers = current.gestureRecognizers ?? []
            log(
                "context view=\(viewDescription(current)) "
                    + "recognizers=[\(recognizers.map(recognizerDescription).joined(separator: ", "))]"
            )
            currentView = current.superview
        }

        var responder: UIResponder? = hitView
        while let currentResponder = responder {
            if let navigationController = currentResponder as? UINavigationController {
                log(
                    "context navigation=\(type(of: navigationController)) "
                        + "stackCount=\(navigationController.viewControllers.count) "
                        + "interactivePop=\(recognizerDescription(navigationController.interactivePopGestureRecognizer))"
                )
            }
            responder = currentResponder.next
        }
    }

    private func log(_ message: String) {
        guard isDebugLoggingEnabled else {
            return
        }

        print("[GestureDebug] \(message)")
    }

    private func viewDescription(_ view: UIView?) -> String {
        guard let view else {
            return "nil"
        }

        return "\(type(of: view))#\(ObjectIdentifier(view))"
    }

    private func recognizerDescription(_ recognizer: UIGestureRecognizer?) -> String {
        guard let recognizer else {
            return "nil"
        }

        return "\(type(of: recognizer))#\(ObjectIdentifier(recognizer))"
            + " state=\(stateName(recognizer.state))"
            + " enabled=\(recognizer.isEnabled)"
            + " view=\(viewDescription(recognizer.view))"
    }

    private func stateName(_ state: UIGestureRecognizer.State) -> String {
        switch state {
        case .possible:
            return "possible"
        case .began:
            return "began"
        case .changed:
            return "changed"
        case .ended:
            return "ended"
        case .cancelled:
            return "cancelled"
        case .failed:
            return "failed"
        @unknown default:
            return "unknown(\(state.rawValue))"
        }
    }
}
