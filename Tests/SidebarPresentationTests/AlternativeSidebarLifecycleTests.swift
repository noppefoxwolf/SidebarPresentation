import AlternativeSidebar
import Testing
import UIKit

@MainActor
struct AlternativeSidebarLifecycleTests {
    @Test("Configuring the sidebar does not load the container or its tabs")
    func configurationBeforeLoading() throws {
        let tabs = UITabBarController()
        // UITabBarController eagerly creates its view on some OS versions.
        tabs.view = nil
        try #require(tabs.viewIfLoaded == nil)
        let container = AlternativeSidebarController(tabBarController: tabs)

        container.alternativeSidebar.isEnabled = false
        container.alternativeSidebar.headerContentConfiguration =
            UIListContentConfiguration.header()
        container.alternativeSidebar.isEnabled = true

        #expect(container.viewIfLoaded == nil)
        #expect(tabs.viewIfLoaded == nil)
    }
}
