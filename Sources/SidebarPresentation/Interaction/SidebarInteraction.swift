import InteractiveContainerPanGestureRecognizer
import UIKit

@MainActor
open class SidebarInteraction: NSObject, UIInteraction {
    public weak var delegate: (any SidebarInteractionDelegate)? = nil

    open var isEnabled: Bool = true {
        didSet {
            updatePresentGestureState()
        }
    }

    public let presentation: any SidebarInteractionPresentation

    let presentPanGesture = InteractiveContainerPanGestureRecognizer()

    public init(
        delegate: any SidebarInteractionDelegate,
        presentation: any SidebarInteractionPresentation = .modal
    ) {
        self.delegate = delegate
        self.presentation = presentation
        super.init()
        configure()
    }

    private func configure() {
        presentPanGesture.addTarget(self, action: #selector(onPan))
    }

    public weak var view: UIView? = nil

    public func willMove(to view: UIView?) {
        self.view?.removeGestureRecognizer(presentPanGesture)
        if view == nil {
            presentation.detach()
            updatePresentGestureState()
        }
    }

    public func didMove(to view: UIView?) {
        self.view = view
        presentPanGesture.maximumNumberOfTouches = 1
        updatePresentGestureState()
        view?.addGestureRecognizer(presentPanGesture)
    }

    public func present() {
        present(isInteractiveTransitionEnabled: false)
    }

    public func dismiss(animated: Bool = true) {
        presentation.dismiss(from: self, animated: animated)
    }

    private func present(isInteractiveTransitionEnabled: Bool) {
        guard isEnabled else { return }
        presentation.present(from: self, isInteractive: isInteractiveTransitionEnabled)
    }

    @objc
    private func onPan(_ gesture: UIPanGestureRecognizer) {
        presentation.handlePan(gesture, in: self)
    }

    func updatePresentGestureState() {
        presentPanGesture.isEnabled = isEnabled && !presentation.isVisible
    }
}

