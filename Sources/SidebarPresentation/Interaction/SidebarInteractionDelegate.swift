import UIKit

@MainActor
public protocol SidebarInteractionDelegate: AnyObject, Sendable {
    func sidebarInteraction(
        _ interaction: SidebarInteraction,
        widthForSidebar sidebarViewController: UIViewController
    ) -> CGFloat
    func sidebarInteraction(
        _ interaction: SidebarInteraction,
        presentingViewControllerFor viewController: UIViewController
    ) -> UIViewController?
    func viewController(for interaction: SidebarInteraction) -> UIViewController
}
