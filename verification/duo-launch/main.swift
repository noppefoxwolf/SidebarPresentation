import UIKit
import AlternativeSidebar

@MainActor
var traceLines: [String] = []

@MainActor
func trace(_ message: String) {
    traceLines.append(message)
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("state.txt")
    try? traceLines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
}

@MainActor
func flag(_ name: String) -> Bool {
    ProcessInfo.processInfo.arguments.contains(name)
}

final class Tabs: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        trace("Tabs.viewDidLoad bounds=\(view.bounds) sizeClass=\(traitCollection.horizontalSizeClass.rawValue)")
        mode = flag("tabbar") ? .tabBar : .tabSidebar
        let home = UITab(title: "Home", image: UIImage(systemName: "house"), identifier: "home") { _ in
            let controller = UIViewController()
            controller.view.backgroundColor = .systemBackground
            return controller
        }
        let notice = UITab(title: "Notifications", image: UIImage(systemName: "bell"), identifier: "notice") { _ in
            UIViewController()
        }
        let search = UISearchTab { _ in UIViewController() }
        compactTabIdentifiers = [home.identifier, notice.identifier, search.identifier]
        if !flag("no-prominent") {
            prominentTabIdentifier = search.identifier
        }
        setTabs(flag("no-search") ? [home, notice] : [home, notice, search], animated: false)
        view.backgroundColor = .systemBackground
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        trace("Tabs.viewIsAppearing bounds=\(view.bounds) sizeClass=\(traitCollection.horizontalSizeClass.rawValue)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trace("Tabs.viewDidAppear bounds=\(view.bounds) bar=\(tabBar.frame)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            trace("FINAL bounds=\(view.bounds) bar=\(tabBar.frame) hidden=\(isTabBarHidden)")
            var ancestor: UIView? = tabBar
            while let current = ancestor {
                trace("BAR ANCESTOR \(type(of: current)): frame=\(current.frame) bounds=\(current.bounds) hidden=\(current.isHidden) interaction=\(current.isUserInteractionEnabled) clips=\(current.clipsToBounds)")
                ancestor = current.superview
            }
        }
    }
}

final class Scene: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        let window = UIWindow(windowScene: scene as! UIWindowScene)
        self.window = window
        func makeRoot() -> UIViewController { AlternativeSidebarController(tabBarController: Tabs()) }
        if flag("immediate") {
            window.rootViewController = makeRoot()
        } else {
            window.rootViewController = UIViewController()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                trace("Replacing root window.bounds=\(window.bounds)")
                window.rootViewController = makeRoot()
            }
        }
        window.makeKeyAndVisible()
    }
}
final class App: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: session.role)
        configuration.delegateClass = Scene.self
        return configuration
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
