import UIKit

@MainActor
final class TapActionInteraction: NSObject, UIInteraction {
    weak var view: UIView?
    let action: @MainActor @Sendable () -> Void
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))

    var isEnabled: Bool = true {
        didSet {
            tapGesture.isEnabled = isEnabled
        }
    }

    init(action: @MainActor @escaping @Sendable () -> Void) {
        self.action = action
        super.init()
    }

    func willMove(to view: UIView?) {
        self.view?.removeGestureRecognizer(tapGesture)
    }

    func didMove(to view: UIView?) {
        self.view = view
        tapGesture.isEnabled = isEnabled
        view?.addGestureRecognizer(tapGesture)
    }

    @objc
    func onTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        action()
    }
}
