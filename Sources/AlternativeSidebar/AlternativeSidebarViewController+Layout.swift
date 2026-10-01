import UIKit

@MainActor
extension AlternativeSidebarViewController {
    func makeBackgroundEffectView() -> UIVisualEffectView {
        if #available(iOS 26.0, *) {
            UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        } else {
            UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        }
    }

    func configureLayout() {
        materialBackgroundView.contentView.addSubview(contentContainerView)
        contentContainerView.addSubview(collectionView)
        contentContainerView.addSubview(bottomBarViewContainer)

        bottomBarViewContainer.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 12,
            bottom: 0,
            trailing: 12
        )

        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        bottomBarViewContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentContainerView.topAnchor.constraint(
                equalTo: materialBackgroundView.contentView.topAnchor
            ),
            contentContainerView.leadingAnchor.constraint(
                equalTo: materialBackgroundView.contentView.leadingAnchor
            ),
            contentContainerView.trailingAnchor.constraint(
                equalTo: materialBackgroundView.contentView.trailingAnchor
            ),
            contentContainerView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
            collectionView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            bottomBarViewContainer.leadingAnchor.constraint(
                equalTo: contentContainerView.leadingAnchor
            ),
            bottomBarViewContainer.trailingAnchor.constraint(
                equalTo: contentContainerView.trailingAnchor
            ),
            bottomBarViewContainer.bottomAnchor.constraint(
                equalTo: contentContainerView.safeAreaLayoutGuide.bottomAnchor
            ),
        ])
        bottomBarViewContainer.isHidden = true

        if #available(iOS 26.0, *) {
            let interaction = UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = collectionView
            interaction.edge = .bottom
            bottomBarViewContainer.addInteraction(interaction)
        }
    }

    func updateBottomBarViewLayout() {
        bottomBarViewConstraints.forEach { $0.isActive = false }
        bottomBarViewConstraints.removeAll()
        bottomBarViewContainer.subviews.forEach { $0.removeFromSuperview() }

        guard let bottomBarView else {
            bottomBarViewContainer.isHidden = true
            return
        }

        bottomBarViewContainer.isHidden = false
        bottomBarViewContainer.addSubview(bottomBarView)
        bottomBarView.translatesAutoresizingMaskIntoConstraints = false

        bottomBarViewConstraints = [
            bottomBarView.topAnchor.constraint(
                equalTo: bottomBarViewContainer.layoutMarginsGuide.topAnchor
            ),
            bottomBarView.leadingAnchor.constraint(
                equalTo: bottomBarViewContainer.layoutMarginsGuide.leadingAnchor
            ),
            bottomBarView.bottomAnchor.constraint(
                equalTo: bottomBarViewContainer.layoutMarginsGuide.bottomAnchor
            ),
            bottomBarView.trailingAnchor.constraint(
                equalTo: bottomBarViewContainer.layoutMarginsGuide.trailingAnchor
            ),
        ]
        NSLayoutConstraint.activate(bottomBarViewConstraints)
    }

    func updateBottomBarView() {
        guard isViewLoaded else { return }
        updateBottomBarViewLayout()
        updateCollectionViewInsetsForBottomBar()
        view.setNeedsLayout()
    }
}
