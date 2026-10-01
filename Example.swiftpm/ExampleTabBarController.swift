import AlternativeSidebar
import UIKit

@MainActor
final class ExampleTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        mode = .tabSidebar

        let plainViewController = UINavigationController(
            rootViewController: PlainViewController()
        )

        let scrollViewController = UINavigationController(
            rootViewController: ScrollViewController()
        )

        let pageViewController = UINavigationController(
            rootViewController: PageViewController()
        )

        let splitViewController = ExampleSplitViewController()

        let nestedCollectionViewController = UINavigationController(
            rootViewController: NestedCollectionViewController()
        )

        let settingsViewController = UINavigationController(
            rootViewController: ExampleSettingsViewController()
        )

        tabs = [
            makeTab(
                title: "View",
                imageName: "rectangle",
                identifier: "view",
                viewController: plainViewController
            ),
            makeTab(
                title: "Scroll",
                imageName: "rectangle.split.3x1",
                identifier: "scroll",
                viewController: scrollViewController
            ),
            makeTab(
                title: "Pages",
                imageName: "square.stack.3d.forward.dottedline",
                identifier: "pages",
                viewController: pageViewController
            ),
            makeTab(
                title: "Split",
                imageName: "rectangle.split.2x1",
                identifier: "split",
                viewController: splitViewController
            ),
            makeTab(
                title: "Nested",
                imageName: "rectangle.stack",
                identifier: "nested",
                viewController: nestedCollectionViewController
            ),
            makeTab(
                title: "Settings",
                imageName: "gearshape",
                identifier: "settings",
                viewController: settingsViewController
            ),
        ]
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        configureSidebar()
    }

    private func makeTab(
        title: String,
        imageName: String,
        identifier: String,
        viewController: UIViewController
    ) -> UITab {
        UITab(
            title: title,
            image: UIImage(systemName: imageName),
            identifier: identifier
        ) { _ in
            viewController
        }
    }

    func presentSidebar() {
        updateSidebarSettings()
        preferredSidebar.isHidden.toggle()
    }

    func updateSidebarSettings() {
        self.alternativeSidebar?.isEnabled = ExampleSettings.shared.isSidebarEnabled
    }

    var sidebarHeaderConfiguration: UIContentConfiguration {
        var configuration = UIListContentConfiguration.header()
        configuration.text = "SidebarSample"
        configuration.secondaryText = "SidebarPresentation"
        configuration.image = UIImage(systemName: "sidebar.left")
        configuration.imageProperties.tintColor = UIColor.systemBlue
        return configuration
    }

    var sidebarFooterConfiguration: UIContentConfiguration {
        var configuration = UIListContentConfiguration.footer()
        configuration.text = "Swipe right to close"
        return configuration
    }

    // workaround: UITabBarControllerはinitの時点でviewDidLoadを行うので、parentが不在になるためviewIsAppearingで呼ぶこと
    private func configureSidebar() {
        sidebar.headerContentConfiguration = sidebarHeaderConfiguration
        sidebar.footerContentConfiguration = sidebarFooterConfiguration
        sidebar.bottomBarView = ExampleSidebarBottomView()
        
        alternativeSidebar!.isEnabled = ExampleSettings.shared.isSidebarEnabled
        alternativeSidebar!.headerContentConfiguration = sidebarHeaderConfiguration
        alternativeSidebar!.footerContentConfiguration = sidebarFooterConfiguration
        alternativeSidebar!.bottomBarView = ExampleSidebarBottomView()
    }

}
