import SidebarPresentation
import UIKit

@MainActor
public final class AlternativeSidebar: SidebarInteraction {
    private static let nativeSidebarWidth: CGFloat = 280

    private final class DelegateProxy: NSObject, SidebarInteractionDelegate,
        AlternativeSidebarViewControllerDelegate
    {
        weak var owner: AlternativeSidebar?

        func sidebarInteraction(
            _ interaction: SidebarInteraction,
            widthForSidebar sidebarViewController: UIViewController
        ) -> CGFloat {
            return AlternativeSidebar.nativeSidebarWidth
        }

        func sidebarInteraction(
            _ interaction: SidebarInteraction,
            presentingViewControllerFor viewController: UIViewController
        ) -> UIViewController? {
            owner?.makeSidebarViewController()
        }

        func viewController(for interaction: SidebarInteraction) -> UIViewController {
            owner?.tabBarController ?? UIViewController()
        }

        func alternativeSidebarViewController(
            _ viewController: AlternativeSidebarViewController,
            didSelect tab: UITab
        ) {
            owner?.didSelect(tab: tab)
        }
    }

    private let delegateProxy: DelegateProxy
    private weak var tabBarController: UITabBarController?
    private weak var presentedSidebarViewController: AlternativeSidebarViewController?
    private weak var presentedSidebarContainerViewController: UIViewController?
    private var traitChangeRegistration: (any UITraitChangeRegistration)?
    private var userIsEnabled = true
    private var isAvailableForInteraction = false

    public override var isEnabled: Bool {
        get {
            userIsEnabled && isAvailableForInteraction
        }
        set {
            userIsEnabled = newValue
            super.isEnabled = userIsEnabled && isAvailableForInteraction
        }
    }

    public var headerContentConfiguration: UIContentConfiguration? {
        didSet {
            presentedSidebarViewController?.headerConfiguration = headerContentConfiguration
        }
    }

    public var footerContentConfiguration: UIContentConfiguration? {
        didSet {
            presentedSidebarViewController?.footerConfiguration = footerContentConfiguration
        }
    }

    public var bottomBarView: UIView? {
        didSet {
            presentedSidebarViewController?.bottomView = bottomBarView
        }
    }

    public var isHidden: Bool {
        get {
            presentedSidebarContainerViewController?.presentingViewController == nil
        }
        set {
            if newValue {
                dismiss()
            } else {
                present()
            }
        }
    }

    init(tabBarController: UITabBarController) {
        let delegateProxy = DelegateProxy()
        self.delegateProxy = delegateProxy
        self.tabBarController = tabBarController
        super.init(delegate: delegateProxy)
        delegateProxy.owner = self

        updateAvailability()
        traitChangeRegistration = tabBarController.registerForTraitChanges(
            [UITraitHorizontalSizeClass.self],
            target: self,
            action: #selector(updateAvailability)
        )
    }

    isolated deinit {
        if let traitChangeRegistration, let tabBarController {
            tabBarController.unregisterForTraitChanges(traitChangeRegistration)
        }
    }

    @objc
    func updateAvailability() {
        guard let tabBarController else {
            isEnabled = false
            return
        }

        let shouldEnable: Bool
        if #available(iOS 27.0, *) {
            shouldEnable = !tabBarController.sidebar.isAvailable
        } else {
            shouldEnable = tabBarController.traitCollection.horizontalSizeClass == .compact
        }

        isAvailableForInteraction = shouldEnable
        super.isEnabled = userIsEnabled && shouldEnable
        if !shouldEnable, !isHidden {
            dismiss()
        }
    }

    private func makeSidebarViewController() -> UIViewController? {
        guard let tabBarController else { return nil }

        let viewController = AlternativeSidebarViewController(
            tabs: tabBarController.tabs,
            selectedTab: tabBarController.selectedTab,
            headerConfiguration: headerContentConfiguration,
            footerConfiguration: footerContentConfiguration,
            bottomView: bottomBarView
        )
        viewController.delegate = delegateProxy
        let navigationController = UINavigationController(rootViewController: viewController)
        presentedSidebarViewController = viewController
        presentedSidebarContainerViewController = navigationController
        return navigationController
    }

    private func didSelect(tab: UITab) {
        // Workaround: Thread 1: "Attempting to select a view controller that isn't a child! (null)"
        if let viewController = tab.viewController, viewController.parent == nil {
            tabBarController?.addChild(viewController)
        }
        
        tabBarController?.selectedTab = tab
        dismiss()
    }
}

@MainActor
public extension UITabBarController {
    var alternativeSidebar: AlternativeSidebar {
        if let interaction = view.interactions.first(where: { $0 is AlternativeSidebar })
            as? AlternativeSidebar
        {
            interaction.updateAvailability()
            return interaction
        }

        let interaction = AlternativeSidebar(tabBarController: self)
        view.addInteraction(interaction)
        return interaction
    }
}
