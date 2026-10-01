import UIKit

/// Configuration and presentation state for a tab bar controller's alternative sidebar.
@MainActor
public final class AlternativeSidebar {
    let interaction: AlternativeSidebarInteraction

    init(containerViewController: AlternativeSidebarController) {
        interaction = AlternativeSidebarInteraction(
            containerViewController: containerViewController
        )
    }

    public var isEnabled: Bool {
        get { interaction.isEnabled }
        set { interaction.isEnabled = newValue }
    }

    public var headerContentConfiguration: UIContentConfiguration? {
        get { interaction.headerContentConfiguration }
        set { interaction.headerContentConfiguration = newValue }
    }

    public var footerContentConfiguration: UIContentConfiguration? {
        get { interaction.footerContentConfiguration }
        set { interaction.footerContentConfiguration = newValue }
    }

    public var bottomBarView: UIView? {
        get { interaction.bottomBarView }
        set { interaction.bottomBarView = newValue }
    }

    public var isHidden: Bool {
        get { interaction.isHidden }
        set { interaction.isHidden = newValue }
    }
}
