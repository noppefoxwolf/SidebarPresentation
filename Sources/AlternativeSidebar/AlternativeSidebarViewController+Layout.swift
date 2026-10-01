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
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill
        contentStackView.addArrangedSubview(collectionView)
        contentStackView.addArrangedSubview(bottomViewContainer)
        materialBackgroundView.contentView.addSubview(contentStackView)

        bottomViewContainer.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 12,
            bottom: 8,
            trailing: 12
        )

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomViewContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(
                equalTo: materialBackgroundView.contentView.topAnchor
            ),
            contentStackView.leadingAnchor.constraint(
                equalTo: materialBackgroundView.contentView.leadingAnchor
            ),
            contentStackView.trailingAnchor.constraint(
                equalTo: materialBackgroundView.contentView.trailingAnchor
            ),
            contentStackView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ),
        ])
        bottomViewContainer.isHidden = true

        if #available(iOS 26.0, *) {
            let interaction = UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = collectionView
            interaction.edge = .bottom
            bottomViewContainer.addInteraction(interaction)
        }
    }

    func updateBottomViewLayout() {
        bottomViewConstraints.forEach { $0.isActive = false }
        bottomViewConstraints.removeAll()
        bottomViewContainer.subviews.forEach { $0.removeFromSuperview() }

        guard let bottomView else {
            bottomViewContainer.isHidden = true
            return
        }

        bottomViewContainer.isHidden = false
        bottomViewContainer.addSubview(bottomView)
        bottomView.translatesAutoresizingMaskIntoConstraints = false

        bottomViewConstraints = [
            bottomView.topAnchor.constraint(
                equalTo: bottomViewContainer.layoutMarginsGuide.topAnchor
            ),
            bottomView.leadingAnchor.constraint(
                equalTo: bottomViewContainer.layoutMarginsGuide.leadingAnchor
            ),
            bottomView.bottomAnchor.constraint(
                equalTo: bottomViewContainer.layoutMarginsGuide.bottomAnchor
            ),
            bottomView.trailingAnchor.constraint(
                equalTo: bottomViewContainer.layoutMarginsGuide.trailingAnchor
            ),
        ]
        NSLayoutConstraint.activate(bottomViewConstraints)
    }

    func updateBottomView() {
        guard isViewLoaded else { return }
        updateBottomViewLayout()
    }
}
