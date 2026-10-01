import SidebarPresentation
import AlternativeSidebar
import SwiftUI

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea()
        }
    }
}

struct ContentView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let tabBarController = ExampleTabBarController()
        let container = AlternativeSidebarController(
            tabBarController: tabBarController
        )
        return container
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}
