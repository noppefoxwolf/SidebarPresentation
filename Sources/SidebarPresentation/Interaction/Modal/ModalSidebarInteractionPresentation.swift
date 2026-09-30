import UIKit

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
}
