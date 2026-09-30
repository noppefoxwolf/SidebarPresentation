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

extension SidebarInteractionPresentation {
    func sidebarWidth(
        for viewController: UIViewController,
        interaction: SidebarInteraction
    ) -> CGFloat {
        interaction.delegate?.sidebarInteraction(interaction, widthForSidebar: viewController)
            ?? SidebarTransitionController.defaultSidebarWidth
    }
}
