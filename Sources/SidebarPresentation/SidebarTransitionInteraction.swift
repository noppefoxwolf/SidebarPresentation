import InteractiveContainerPanGestureRecognizer
import UIKit

@MainActor
public protocol SidebarInteractionPresentation: AnyObject {
    var isVisible: Bool { get }
    func present(from interaction: SidebarInteraction, isInteractive: Bool)
    func dismiss(from interaction: SidebarInteraction, animated: Bool)
    func handlePan(_ gesture: UIPanGestureRecognizer, in interaction: SidebarInteraction)
    func detach()
}

public extension SidebarInteractionPresentation {
    var isVisible: Bool { false }
    func detach() {}
}

extension SidebarInteractionPresentation where Self == ModalSidebarInteractionPresentation {
    public static var modal: any SidebarInteractionPresentation {
        ModalSidebarInteractionPresentation()
    }
}

extension SidebarInteractionPresentation where Self == EmbeddedSidebarInteractionPresentation {
    public static var embedded: any SidebarInteractionPresentation {
        EmbeddedSidebarInteractionPresentation()
    }
}

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

    fileprivate func updatePresentGestureState() {
        presentPanGesture.isEnabled = isEnabled && !presentation.isVisible
    }
}

@MainActor
public final class ModalSidebarInteractionPresentation: SidebarInteractionPresentation {
    private var transitionController: SidebarTransitionController?
    private weak var presentedViewController: UIViewController?

    public func present(from interaction: SidebarInteraction, isInteractive: Bool) {
        guard let parent = interaction.delegate?.viewController(for: interaction) else { return }
        guard let viewController = interaction.delegate?.sidebarInteraction(
            interaction,
            presentingViewControllerFor: parent
        ) else {
            return
        }

        let controller = SidebarTransitionController(
            sidebarWidth: sidebarWidth(for: viewController, interaction: interaction)
        )
        if isInteractive {
            controller.interactiveTransition = UIPercentDrivenInteractiveTransition()
        }
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = controller
        viewController.traitOverrides.userInterfaceLevel = .elevated
        transitionController = controller
        presentedViewController = viewController
        parent.present(viewController, animated: true)
    }

    public func dismiss(from _: SidebarInteraction, animated: Bool) {
        presentedViewController?.dismiss(animated: animated)
    }

    public func handlePan(_ gesture: UIPanGestureRecognizer, in interaction: SidebarInteraction) {
        switch gesture.state {
        case .began:
            if transitionController?.interactiveTransition == nil {
                present(from: interaction, isInteractive: true)
                transitionController?.interactiveTransition?.completionCurve = .easeOut
            }

        case .changed:
            guard let interactiveTransition = transitionController?.interactiveTransition else {
                return
            }
            let progress = SidebarGestureMetrics.presentationProgress(
                translation: gesture.translation(in: gesture.view).x,
                width: transitionController?.sidebarWidth
                    ?? SidebarTransitionController.defaultSidebarWidth
            )
            interactiveTransition.update(progress)

        case .ended:
            guard let interactiveTransition = transitionController?.interactiveTransition else {
                return
            }
            let progress = SidebarGestureMetrics.presentationProgress(
                translation: gesture.translation(in: gesture.view).x,
                width: transitionController?.sidebarWidth
                    ?? SidebarTransitionController.defaultSidebarWidth
            )
            if SidebarGestureMetrics.shouldFinishPresentation(
                velocity: gesture.velocity(in: gesture.view).x,
                progress: progress
            ) {
                interactiveTransition.finish()
            } else {
                interactiveTransition.cancel()
            }

        case .cancelled, .failed:
            transitionController?.interactiveTransition?.cancel()

        default:
            break
        }
    }

    private func sidebarWidth(
        for viewController: UIViewController,
        interaction: SidebarInteraction
    ) -> CGFloat {
        interaction.delegate?.sidebarInteraction(interaction, widthForSidebar: viewController)
            ?? SidebarTransitionController.defaultSidebarWidth
    }
}

@MainActor
public final class EmbeddedSidebarInteractionPresentation: SidebarInteractionPresentation {
    private var embeddedViewController: SidebarEmbeddedViewController?

    public var isVisible: Bool {
        embeddedViewController?.isVisible == true
    }

    public func present(from interaction: SidebarInteraction, isInteractive: Bool) {
        guard let parent = interaction.delegate?.viewController(for: interaction) else { return }

        if let embeddedViewController,
            embeddedViewController.parent === parent
        {
            if isInteractive {
                embeddedViewController.beginInteractivePresentation()
            } else {
                embeddedViewController.show(animated: true)
            }
            interaction.updatePresentGestureState()
            return
        }

        detach()

        guard let viewController = interaction.delegate?.sidebarInteraction(
            interaction,
            presentingViewControllerFor: parent
        ) else {
            return
        }

        let embedded = SidebarEmbeddedViewController(
            sidebarViewController: viewController,
            sidebarWidth: sidebarWidth(for: viewController, interaction: interaction)
        )
        embedded.onVisibilityChanged = { [weak interaction] _ in
            interaction?.updatePresentGestureState()
        }

        parent.addChild(embedded)
        embedded.view.frame = parent.view.bounds
        embedded.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parent.view.addSubview(embedded.view)
        embedded.didMove(toParent: parent)
        embeddedViewController = embedded

        if isInteractive {
            embedded.beginInteractivePresentation()
        } else {
            embedded.show(animated: true)
        }
        interaction.updatePresentGestureState()
    }

    public func dismiss(from _: SidebarInteraction, animated: Bool) {
        embeddedViewController?.hide(animated: animated)
    }

    public func handlePan(_ gesture: UIPanGestureRecognizer, in interaction: SidebarInteraction) {
        guard !isVisible else { return }

        switch gesture.state {
        case .began:
            present(from: interaction, isInteractive: true)

        case .changed:
            guard let embeddedViewController else { return }
            let progress = SidebarGestureMetrics.presentationProgress(
                translation: gesture.translation(in: gesture.view).x,
                width: embeddedViewController.sidebarWidth
            )
            embeddedViewController.updateInteractivePresentation(progress)

        case .ended:
            guard let embeddedViewController else { return }
            let progress = SidebarGestureMetrics.presentationProgress(
                translation: gesture.translation(in: gesture.view).x,
                width: embeddedViewController.sidebarWidth
            )
            if SidebarGestureMetrics.shouldFinishPresentation(
                velocity: gesture.velocity(in: gesture.view).x,
                progress: progress
            ) {
                embeddedViewController.finishInteractivePresentation()
            } else {
                embeddedViewController.cancelInteractivePresentation()
            }

        case .cancelled, .failed:
            embeddedViewController?.cancelInteractivePresentation()

        default:
            break
        }
    }

    public func detach() {
        embeddedViewController?.detachFromParent()
        embeddedViewController = nil
    }

    private func sidebarWidth(
        for viewController: UIViewController,
        interaction: SidebarInteraction
    ) -> CGFloat {
        interaction.delegate?.sidebarInteraction(interaction, widthForSidebar: viewController)
            ?? SidebarTransitionController.defaultSidebarWidth
    }
}
