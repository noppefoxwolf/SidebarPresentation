import SidebarPresentation
import UIKit

@MainActor
final class AlternativeSidebarInteraction: SidebarInteraction {
    private static let nativeSidebarWidth: CGFloat = 280

    private final class DelegateProxy: NSObject, SidebarInteractionDelegate,
        AlternativeSidebarViewControllerDelegate
    {
        weak var owner: AlternativeSidebarInteraction?

        func sidebarInteraction(
            _ interaction: SidebarInteraction,
            widthForSidebar sidebarViewController: UIViewController
        ) -> CGFloat {
            AlternativeSidebarInteraction.nativeSidebarWidth
        }

        func sidebarInteraction(
            _ interaction: SidebarInteraction,
            presentingViewControllerFor viewController: UIViewController
        ) -> UIViewController? {
            owner?.makeSidebarViewController()
        }

        func viewController(for interaction: SidebarInteraction) -> UIViewController {
            owner?.containerViewController ?? UIViewController()
        }

        func alternativeSidebarViewController(
            _ viewController: AlternativeSidebarViewController,
            didSelect tab: UITab
        ) {
            owner?.didSelect(tab: tab)
        }
    }

    private let delegateProxy: DelegateProxy
    private weak var containerViewController: AlternativeSidebarController?
    private weak var tabBarController: UITabBarController?
    private weak var presentedSidebarViewController: AlternativeSidebarViewController?
    private var traitChangeRegistration: (any UITraitChangeRegistration)?
    private var userIsEnabled = true
    private var isAvailableForInteraction = false

    override var isEnabled: Bool {
        get {
            userIsEnabled && isAvailableForInteraction
        }
        set {
            userIsEnabled = newValue
            super.isEnabled = userIsEnabled && isAvailableForInteraction
        }
    }

    var headerContentConfiguration: UIContentConfiguration? {
        didSet {
            presentedSidebarViewController?.headerConfiguration = headerContentConfiguration
        }
    }

    var footerContentConfiguration: UIContentConfiguration? {
        didSet {
            presentedSidebarViewController?.footerConfiguration = footerContentConfiguration
        }
    }

    var bottomBarView: UIView? {
        didSet {
            presentedSidebarViewController?.bottomView = bottomBarView
        }
    }

    var isHidden: Bool {
        get {
            !presentation.isVisible
        }
        set {
            if newValue {
                dismiss()
            } else {
                present()
            }
        }
    }

    init(containerViewController: AlternativeSidebarController) {
        let delegateProxy = DelegateProxy()
        self.delegateProxy = delegateProxy
        self.containerViewController = containerViewController
        tabBarController = containerViewController.contentTabBarController
        super.init(delegate: delegateProxy, presentation: .embedded)
        delegateProxy.owner = self

        traitChangeRegistration = containerViewController.registerForTraitChanges(
            [UITraitHorizontalSizeClass.self],
            target: self,
            action: #selector(updateAvailability)
        )
    }

    isolated deinit {
        if let traitChangeRegistration, let containerViewController {
            containerViewController.unregisterForTraitChanges(traitChangeRegistration)
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
        viewController.onDismissRequested = { [weak self] in
            self?.dismiss()
        }
        let navigationController = UINavigationController(rootViewController: viewController)
        presentedSidebarViewController = viewController
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
