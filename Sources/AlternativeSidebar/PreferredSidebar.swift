import UIKit

@MainActor
public final class PreferredSidebar {
    private weak var tabBarController: UITabBarController?

    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }

    public var isHidden: Bool {
        get {
            guard let tabBarController else { return true }

            if #available(iOS 27.0, *), tabBarController.sidebar.isAvailable {
                return tabBarController.sidebar.isHidden
            }

            return tabBarController.alternativeSidebar?.isHidden ?? true
        }
        set {
            guard let tabBarController else { return }

            if #available(iOS 27.0, *), tabBarController.sidebar.isAvailable {
                tabBarController.sidebar.isHidden = newValue
            } else {
                tabBarController.alternativeSidebar?.isHidden = newValue
            }
        }
    }
}

@MainActor
public extension AlternativeSidebarController {
    var preferredSidebar: PreferredSidebar {
        PreferredSidebar(tabBarController: contentTabBarController)
    }
}

@MainActor
public extension UITabBarController {
    var preferredSidebar: PreferredSidebar {
        PreferredSidebar(tabBarController: self)
    }
}
