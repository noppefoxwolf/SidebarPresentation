import UIKit

@MainActor
final class SidebarEmbeddedViewController: UIViewController {
    let sidebarViewController: UIViewController
    let sidebarWidth: CGFloat

    var onVisibilityChanged: ((Bool) -> Void)?

    private let dimmingView = DimmingView()
    private let dismissPanGesture = UIPanGestureRecognizer()
    private let motion: SidebarPresentationMotion
    private var presentationAnimator: UIViewPropertyAnimator?
    private var animationStartProgress: CGFloat = 0
    private var animationTargetProgress: CGFloat = 0
    private var presentationProgress: CGFloat = 0

    private(set) var isVisible = false

    init(sidebarViewController: UIViewController, sidebarWidth: CGFloat) {
        self.sidebarViewController = sidebarViewController
        self.sidebarWidth = sidebarWidth
        motion = SidebarPresentationMotion(sidebarWidth: sidebarWidth)
        super.init(nibName: nil, bundle: nil)

        dismissPanGesture.addTarget(self, action: #selector(onDismissPan))
        sidebarViewController.traitOverrides.userInterfaceLevel = .elevated
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dimmingView.alpha = 0
        dimmingView.addInteraction(
            TapActionInteraction { [weak self] in
                self?.hide(animated: true)
            }
        )

        addChild(sidebarViewController)
        view.addSubview(dimmingView)
        view.addSubview(sidebarViewController.view)
        view.addGestureRecognizer(dismissPanGesture)
        sidebarViewController.didMove(toParent: self)

        updateViewForProgress()
        updateInteractionState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateViewForProgress()
    }

    func show(animated: Bool) {
        view.isUserInteractionEnabled = true
        animate(to: 1, animated: animated)
    }

    func beginInteractivePresentation() {
        stopPresentationAnimator()
        presentationProgress = 0
        isVisible = false
        view.isUserInteractionEnabled = true
        dismissPanGesture.isEnabled = false
        updateViewForProgress()
    }

    func updateInteractivePresentation(_ progress: CGFloat) {
        presentationProgress = min(max(progress, 0), 1)
        updateViewForProgress()
    }

    func finishInteractivePresentation() {
        animate(to: 1, animated: true)
    }

    func cancelInteractivePresentation() {
        animate(to: 0, animated: true)
    }

    func hide(animated: Bool) {
        animate(to: 0, animated: animated)
    }

    func detachFromParent() {
        stopPresentationAnimator()

        sidebarViewController.willMove(toParent: nil)
        sidebarViewController.view.removeFromSuperview()
        sidebarViewController.removeFromParent()

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    private var effectiveSidebarWidth: CGFloat {
        motion.sidebarWidth(in: view.bounds)
    }

    private func animate(to targetProgress: CGFloat, animated: Bool) {
        stopPresentationAnimator()

        let targetProgress = min(max(targetProgress, 0), 1)
        let startProgress = presentationProgress
        if !animated || abs(startProgress - targetProgress) < 0.001 {
            presentationProgress = targetProgress
            isVisible = targetProgress > 0.5
            updateViewForProgress()
            updateInteractionState()
            onVisibilityChanged?(isVisible)
            return
        }

        animationStartProgress = startProgress
        animationTargetProgress = targetProgress

        let animator = UIViewPropertyAnimator(
            duration: SidebarPresentationMotion.animationDuration,
            curve: SidebarPresentationMotion.animationCurve
        ) {
            [weak self] in
            guard let self else { return }
            self.presentationProgress = targetProgress
            self.updateViewForProgress()
        }
        animator.addCompletion { [weak self] _ in
            guard let self else { return }
            self.presentationProgress = targetProgress
            self.isVisible = targetProgress > 0.5
            self.presentationAnimator = nil
            self.updateViewForProgress()
            self.updateInteractionState()
            self.onVisibilityChanged?(self.isVisible)
        }

        presentationAnimator = animator
        animator.startAnimation()
    }

    private func stopPresentationAnimator() {
        guard let presentationAnimator else { return }

        if presentationAnimator.isRunning {
            let fractionComplete = CGFloat(presentationAnimator.fractionComplete)
            presentationProgress = animationStartProgress
                + (animationTargetProgress - animationStartProgress) * fractionComplete
            presentationAnimator.stopAnimation(true)
            updateViewForProgress()
        }

        self.presentationAnimator = nil
    }

    private func updateViewForProgress() {
        guard isViewLoaded else { return }

        motion.apply(
            progress: presentationProgress,
            sidebarView: sidebarViewController.view,
            dimmingView: dimmingView,
            in: view.bounds
        )
    }

    private func updateInteractionState() {
        let isPresented = presentationProgress > 0.001
        view.isUserInteractionEnabled = isPresented
        dismissPanGesture.isEnabled = isVisible
        view.accessibilityViewIsModal = isVisible
    }

    @objc
    private func onDismissPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view).x
        let fractionCompleted = SidebarGestureMetrics.dismissalProgress(
            translation: translation,
            width: effectiveSidebarWidth
        )

        switch gesture.state {
        case .began:
            stopPresentationAnimator()
            presentationProgress = 1
            updateViewForProgress()

        case .changed:
            updateInteractivePresentation(1 - fractionCompleted)

        case .ended:
            let velocity = gesture.velocity(in: view).x
            if SidebarGestureMetrics.shouldFinishDismissal(
                velocity: velocity,
                progress: fractionCompleted
            ) {
                animate(to: 0, animated: true)
            } else {
                animate(to: 1, animated: true)
            }

        case .cancelled, .failed:
            animate(to: 1, animated: true)

        default:
            break
        }
    }
}
