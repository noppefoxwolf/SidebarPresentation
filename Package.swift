// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SidebarPresentation",
    platforms: [.iOS(.v18)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SidebarPresentation",
            targets: ["SidebarPresentation"]
        ),
        .library(
            name: "AlternativeSidebar",
            targets: ["AlternativeSidebar"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "InteractiveContainerPanGestureRecognizer"
        ),
        .target(
            name: "SidebarPresentation",
            dependencies: ["InteractiveContainerPanGestureRecognizer"]
        ),
        .target(
            name: "AlternativeSidebar",
            dependencies: ["SidebarPresentation"]
        ),
        .testTarget(
            name: "SidebarPresentationTests",
            dependencies: [
                "SidebarPresentation",
                "InteractiveContainerPanGestureRecognizer",
            ]
        ),
    ]
)
