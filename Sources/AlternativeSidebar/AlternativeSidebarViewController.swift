import UIKit

@MainActor
public protocol AlternativeSidebarViewControllerDelegate: AnyObject {
    func alternativeSidebarViewController(
        _ viewController: AlternativeSidebarViewController,
        didSelect tab: UITab
    )
}

@MainActor
public final class AlternativeSidebarViewController: UIViewController {
    internal let tabs: [UITab]
    internal var onDismissRequested: (() -> Void)?

    public weak var delegate: (any AlternativeSidebarViewControllerDelegate)?

    public var selectedTab: UITab? {
        didSet {
            updateSelection(animated: false)
        }
    }

    public var headerContentConfiguration: UIContentConfiguration? {
        didSet {
            if isViewLoaded {
                collectionView.reloadData()
            }
        }
    }

    public var footerContentConfiguration: UIContentConfiguration? {
        didSet {
            if isViewLoaded {
                collectionView.reloadData()
            }
        }
    }

    public var bottomBarView: UIView? {
        didSet {
            updateBottomBarView()
        }
    }

    internal var materialBackgroundView: UIVisualEffectView {
        view as! UIVisualEffectView
    }

    internal let bottomBarViewContainer = UIView()
    internal var bottomBarViewConstraints: [NSLayoutConstraint] = []
    internal let contentContainerView = UIView()

    internal let collectionView: UICollectionView

    internal lazy var cellRegistration = makeCellRegistration()
    internal lazy var headerRegistration = makeHeaderRegistration()
    internal lazy var footerRegistration = makeFooterRegistration()
    internal var dataSource: UICollectionViewDiffableDataSource<Int, Int>!

    public init(
        tabs: [UITab],
        selectedTab: UITab? = nil,
        headerContentConfiguration: UIContentConfiguration? = nil,
        footerContentConfiguration: UIContentConfiguration? = nil,
        bottomBarView: UIView? = nil
    ) {
        self.tabs = tabs.filter { !$0.isHidden }
        self.selectedTab = selectedTab
        self.headerContentConfiguration = headerContentConfiguration
        self.footerContentConfiguration = footerContentConfiguration
        self.bottomBarView = bottomBarView

        var layoutConfiguration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        layoutConfiguration.showsSeparators = false
        layoutConfiguration.backgroundColor = .clear
        layoutConfiguration.headerMode = .supplementary
        layoutConfiguration.footerMode = .supplementary

        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewCompositionalLayout.list(
                using: layoutConfiguration
            )
        )

        super.init(nibName: nil, bundle: nil)
    }

    // `UIVerticalBarBehavior` was added to the UIKit module in the iOS 27.1 SDK.
    // Xcode 27.0 also uses Swift 6.4, so a compiler-version check cannot
    // distinguish the two SDKs here.
    #if canImport(UIKit, _version: 9127.0.85)
    @available(iOS 27.1, *)
    public override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
        .disabled
    }
    #endif

    /// Creates a sidebar using the tab and sidebar configuration from a tab bar controller.
    public convenience init(tabBarController: UITabBarController) {
        self.init(
            tabs: tabBarController.tabs,
            selectedTab: tabBarController.selectedTab,
            headerContentConfiguration: tabBarController.sidebar.headerContentConfiguration,
            footerContentConfiguration: tabBarController.sidebar.footerContentConfiguration,
            bottomBarView: tabBarController.sidebar.bottomBarView
        )
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        bottomBarView?.removeFromSuperview()
    }

    public override func loadView() {
        super.loadView()
        view = makeBackgroundEffectView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        configureCloseButton()
        configureCollectionView()
        configureLayout()
        setContentScrollView(collectionView, for: .bottom)
        applySnapshot()
        updateBottomBarView()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateCollectionViewInsetsForBottomBar()
    }

    func updateCollectionViewInsetsForBottomBar() {
        let bottomBarInset = bottomBarViewContainer.isHidden
            ? 0
            : max(
                bottomBarViewContainer.bounds.height,
                bottomBarViewContainer.systemLayoutSizeFitting(
                    UIView.layoutFittingCompressedSize
                ).height
            )
        guard abs(collectionView.contentInset.bottom - bottomBarInset) > 0.5
            || abs(collectionView.verticalScrollIndicatorInsets.bottom - bottomBarInset) > 0.5
        else {
            return
        }

        var contentInsets = collectionView.contentInset
        contentInsets.bottom = bottomBarInset
        collectionView.contentInset = contentInsets

        var indicatorInsets = collectionView.verticalScrollIndicatorInsets
        indicatorInsets.bottom = bottomBarInset
        collectionView.verticalScrollIndicatorInsets = indicatorInsets
    }

    private func configureCloseButton() {
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "platter.filled.bottom.iphone"),
            style: .plain,
            target: nil,
            action: nil
        )
        closeButton.accessibilityLabel = "Close Sidebar"
        closeButton.primaryAction = UIAction { [weak self] _ in
            self?.onDismissRequested?()
        }
        navigationItem.rightBarButtonItem = closeButton
    }
}
