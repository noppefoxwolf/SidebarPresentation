import UIKit

/// Hosts a tab bar controller and provides a separate parent view for embedded sidebar presentation.
@MainActor
public final class AlternativeSidebarController: UIViewController {
    public let contentTabBarController: UITabBarController
    private lazy var alternativeSidebarInstance = AlternativeSidebar(
        containerViewController: self
    )

    public var alternativeSidebar: AlternativeSidebar {
        alternativeSidebarInstance.interaction.updateAvailability()
        return alternativeSidebarInstance
    }

    public init(tabBarController: UITabBarController) {
        contentTabBarController = tabBarController
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addInteraction(alternativeSidebarInstance.interaction)
        addChild(contentTabBarController)
        contentTabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentTabBarController.view)
        NSLayoutConstraint.activate([
            contentTabBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentTabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentTabBarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentTabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        contentTabBarController.didMove(toParent: self)
    }

    public override func viewWillTransition(
        to size: CGSize,
        with coordinator: any UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.alternativeSidebarInstance.interaction.updateAvailability()
        }
    }
}

@MainActor
public extension UITabBarController {
    var alternativeSidebarController: AlternativeSidebarController? {
        parent as? AlternativeSidebarController
    }

    var alternativeSidebar: AlternativeSidebar? {
        alternativeSidebarController?.alternativeSidebar
    }
}
