import UIKit

enum StatsTheme {
    static let background    = UIColor(white: 0.05, alpha: 1)
    static let card          = UIColor(white: 0.10, alpha: 0.55)
    static let cardSolid     = UIColor(white: 0.10, alpha: 1)
    static let border        = UIColor(white: 0.25, alpha: 0.3)
    static let primaryText   = UIColor.white
    static let secondaryText = UIColor(white: 0.55, alpha: 1)
    static let accentRed     = UIColor(red: 0.878, green: 0.337, blue: 0.337, alpha: 1)
    static let accentBlue    = UIColor(red: 0.310, green: 0.765, blue: 0.973, alpha: 1)
    static let liveGreen     = UIColor(red: 0.20, green: 0.85, blue: 0.20, alpha: 1)

    static let glassContentTag = 9999

    /// Creates a glass-backed card view for the stats screens.
    /// Content should be added to the subview tagged `glassContentTag`.
    static func makeGlassCard(cornerRadius: CGFloat = 14) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .clear
        container.layer.cornerRadius = cornerRadius
        container.clipsToBounds = true

        let glass = UIView.makeGlassBackground(
            cornerRadius: cornerRadius,
            fallbackStyle: .systemUltraThinMaterialDark)
        container.addSubview(glass)
        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: container.topAnchor),
            glass.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            glass.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let tint = UIView()
        tint.translatesAutoresizingMaskIntoConstraints = false
        tint.backgroundColor = card
        tint.isUserInteractionEnabled = false
        container.addSubview(tint)
        NSLayoutConstraint.activate([
            tint.topAnchor.constraint(equalTo: container.topAnchor),
            tint.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tint.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tint.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.tag = glassContentTag
        content.backgroundColor = .clear
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        container.layer.borderWidth = 1
        container.layer.borderColor = border.cgColor

        return container
    }
}
