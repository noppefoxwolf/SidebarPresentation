import UIKit

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
}
