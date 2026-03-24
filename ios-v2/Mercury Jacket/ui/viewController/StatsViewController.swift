import UIKit

// MARK: - Shared theme (used by StatsViewController and SessionDetailViewController)

fileprivate enum Theme {
    static let background    = UIColor(white: 0.05, alpha: 1)
    static let card          = UIColor(white: 0.10, alpha: 1)
    static let border        = UIColor(white: 0.15, alpha: 1)
    static let primaryText   = UIColor.white
    static let secondaryText = UIColor(white: 0.50, alpha: 1)
    static let accentRed     = UIColor(red: 0.878, green: 0.337, blue: 0.337, alpha: 1)
    static let accentBlue    = UIColor(red: 0.310, green: 0.765, blue: 0.973, alpha: 1)
    static let liveGreen     = UIColor(red: 0.20, green: 0.85, blue: 0.20, alpha: 1)
}

// MARK: - StatsViewController

class StatsViewController: UIViewController {

    // MARK: - State

    private var showTemperature = true
    private var displaySession: Session?
    private var isLive = false
    private var sessionsList: [Session] = []   // backing store for tappable history rows

    // MARK: - Views

    private lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.showsVerticalScrollIndicator = false
        return v
    }()

    private lazy var contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var sessionCard: UIView = makeCard()

    private lazy var segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["TEMPERATURE", "HEATING"])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentIndex = 0
        sc.backgroundColor = Theme.card
        sc.selectedSegmentTintColor = Theme.accentRed
        sc.setTitleTextAttributes(
            [.foregroundColor: Theme.secondaryText,
             .font: UIFont.systemFont(ofSize: 11, weight: .semibold)],
            for: .normal)
        sc.setTitleTextAttributes(
            [.foregroundColor: UIColor.white,
             .font: UIFont.systemFont(ofSize: 11, weight: .semibold)],
            for: .selected)
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return sc
    }()

    private lazy var chartView: LineChartView = {
        let cv = LineChartView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = Theme.card
        cv.layer.cornerRadius = 12
        cv.layer.borderWidth = 1
        cv.layer.borderColor = Theme.border.cgColor
        cv.clipsToBounds = true
        return cv
    }()

    private lazy var legendStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.spacing = 20
        sv.alignment = .center
        return sv
    }()

    private lazy var historyStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 8
        return sv
    }()

    /// Overlaid on the chart; shows the time of the most recent live data point.
    private lazy var lastUpdateLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = UIFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular)
        lbl.textColor = UIColor(white: 0.38, alpha: 1)
        lbl.isHidden = true
        return lbl
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        title = "STATISTICS"
        setupNavBar()
        buildLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refresh()
        startLiveUpdates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        stopLiveUpdates()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Navigation bar

    private func setupNavBar() {
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = Theme.background
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ]
    }

    // MARK: - Layout

    private func buildLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        let sessionHeader  = makeSectionLabel("LATEST SESSION")
        let historyHeader  = makeSectionLabel("PAST SESSIONS")

        contentView.addSubview(sessionHeader)
        contentView.addSubview(sessionCard)
        contentView.addSubview(segmentControl)
        contentView.addSubview(chartView)
        chartView.addSubview(lastUpdateLabel)
        contentView.addSubview(legendStack)
        contentView.addSubview(historyHeader)
        contentView.addSubview(historyStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            sessionHeader.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            sessionHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            sessionCard.topAnchor.constraint(equalTo: sessionHeader.bottomAnchor, constant: 10),
            sessionCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sessionCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sessionCard.heightAnchor.constraint(equalToConstant: 90),

            segmentControl.topAnchor.constraint(equalTo: sessionCard.bottomAnchor, constant: 24),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),

            chartView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 10),
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalToConstant: 250),

            legendStack.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 10),
            legendStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            historyHeader.topAnchor.constraint(equalTo: legendStack.bottomAnchor, constant: 28),
            historyHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            historyStack.topAnchor.constraint(equalTo: historyHeader.bottomAnchor, constant: 10),
            historyStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            historyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            historyStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),

            lastUpdateLabel.topAnchor.constraint(equalTo: chartView.topAnchor, constant: 7),
            lastUpdateLabel.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: -10)
        ])
    }

    // MARK: - Live updates

    private func startLiveUpdates() {
        let bt = BluetoothController.getInstance()
        guard bt.isConnected() else { return }
        isLive = true
        bt.listenTo(id: "StatsViewController", eventName: BluetoothController.Events.ON_UPDATE_CHARACTERISTIC) { [weak self] _ in
            DispatchQueue.main.async { self?.liveUpdate() }
        }
        bt.listenTo(id: "StatsViewController", eventName: BluetoothController.Events.ON_DEVICE_DISCONNECTED) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isLive = false
                self?.refresh()
            }
        }
    }

    private func stopLiveUpdates() {
        BluetoothController.getInstance().removeListeners(id: "StatsViewController", eventNameToRemoveOrNil: nil)
        isLive = false
    }

    /// Lightweight refresh: updates chart + session card using the latest live
    /// BLE readings without rebuilding the history section.
    private func liveUpdate() {
        let logger = SessionLogger.shared
        if let live = logger.currentSessionForDisplay(), !live.dataPoints.isEmpty {
            displaySession = live
        }
        renderSessionCard()
        renderChart()

        // Update "last synced" timestamp overlay
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        lastUpdateLabel.text = "↑ \(fmt.string(from: Date()))"
        lastUpdateLabel.isHidden = false

        // Brief green border flash to signal new data arrived
        let pulse = CABasicAnimation(keyPath: "borderColor")
        pulse.fromValue = Theme.liveGreen.cgColor
        pulse.toValue   = Theme.border.cgColor
        pulse.duration  = 1.2
        pulse.timingFunction = CAMediaTimingFunction(name: .easeOut)
        chartView.layer.add(pulse, forKey: "liveFlash")
    }

    // MARK: - Data

    private func refresh() {
        let logger   = SessionLogger.shared
        let sessions = logger.allSessions()

        if let live = logger.currentSessionForDisplay(), !live.dataPoints.isEmpty {
            displaySession = live
            isLive = true
        } else {
            displaySession = sessions.first
            isLive = false
        }

        renderSessionCard()
        renderChart()
        renderLegend()
        renderHistory(sessions: sessions)
    }

    // MARK: - Render helpers

    private func renderSessionCard() {
        sessionCard.subviews.forEach { $0.removeFromSuperview() }

        guard let session = displaySession else {
            let lbl = makeLabel("No sessions recorded yet",
                                size: 13, weight: .regular, color: Theme.secondaryText)
            lbl.textAlignment = .center
            sessionCard.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: sessionCard.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: sessionCard.centerYAnchor)
            ])
            return
        }

        let useFahrenheit = AppController.getTemperatureMeasure() == AppController.FAHRENHEIT
        let deltaC = session.tempDeltaCelsius
        let deltaStr = useFahrenheit
            ? String(format: "+%.1f°F", deltaC * 9.0 / 5.0)
            : String(format: "+%.1f°C", deltaC)

        let statsRow = UIStackView()
        statsRow.translatesAutoresizingMaskIntoConstraints = false
        statsRow.axis = .horizontal
        statsRow.distribution = .fillEqually
        sessionCard.addSubview(statsRow)

        NSLayoutConstraint.activate([
            statsRow.leadingAnchor.constraint(equalTo: sessionCard.leadingAnchor, constant: 16),
            statsRow.trailingAnchor.constraint(equalTo: sessionCard.trailingAnchor, constant: -16),
            statsRow.topAnchor.constraint(equalTo: sessionCard.topAnchor, constant: 14),
            statsRow.bottomAnchor.constraint(equalTo: sessionCard.bottomAnchor, constant: -14)
        ])

        let items: [(String, String, UIColor)] = [
            ("DURATION",   formatDuration(session.duration),                               Theme.primaryText),
            ("AVG POWER",  String(format: "%.1f / 10", session.averagePower0to10),         Theme.accentRed),
            ("TEMP DELTA", deltaStr,                                                        Theme.accentBlue)
        ]
        items.forEach { statsRow.addArrangedSubview(makeStatCell(title: $0.0, value: $0.1, color: $0.2)) }

        if session.isActive {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = Theme.liveGreen
            dot.layer.cornerRadius = 4
            sessionCard.addSubview(dot)

            let liveLbl = makeLabel("LIVE", size: 9, weight: .bold, color: Theme.liveGreen)
            sessionCard.addSubview(liveLbl)

            NSLayoutConstraint.activate([
                dot.trailingAnchor.constraint(equalTo: sessionCard.trailingAnchor, constant: -14),
                dot.topAnchor.constraint(equalTo: sessionCard.topAnchor, constant: 10),
                dot.widthAnchor.constraint(equalToConstant: 7),
                dot.heightAnchor.constraint(equalToConstant: 7),
                liveLbl.trailingAnchor.constraint(equalTo: dot.leadingAnchor, constant: -4),
                liveLbl.centerYAnchor.constraint(equalTo: dot.centerYAnchor)
            ])
        }
    }

    private func renderChart() {
        guard let session = displaySession, session.dataPoints.count >= 2 else {
            chartView.seriesData = []
            chartView.noDataMessage = "Connect your jacket to start recording"
            return
        }

        let pts = session.dataPoints
        let useFahrenheit = AppController.getTemperatureMeasure() == AppController.FAHRENHEIT

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        let midIdx = pts.count / 2
        chartView.xLabels = [
            fmt.string(from: pts.first!.timestamp),
            fmt.string(from: pts[midIdx].timestamp),
            fmt.string(from: pts.last!.timestamp)
        ]

        if showTemperature {
            let convert: (Float) -> CGFloat = {
                CGFloat(useFahrenheit ? AppController.celsiusToFahrenheit(value: $0) : $0)
            }
            let jacketYs  = pts.map { convert($0.jacketTempCelsius) }
            let ambientYs = pts.map { convert($0.ambientTempCelsius) }
            let allY = jacketYs + ambientYs
            chartView.yMin  = (allY.min() ?? 0) - 2
            chartView.yMax  = (allY.max() ?? 30) + 2
            chartView.yUnit = useFahrenheit ? "°F" : "°C"
            chartView.seriesData = [
                LineChartView.Series(label: "Jacket",  color: Theme.accentRed,  points: jacketYs),
                LineChartView.Series(label: "Outside", color: Theme.accentBlue, points: ambientYs)
            ]
        } else {
            // Show actual power output (W) if the characteristic has data,
            // otherwise fall back to the 0-10 heating level.
            let hasPowerOutput = pts.contains { $0.powerOutputWatts != nil }

            if hasPowerOutput {
                let wattsYs   = pts.map { CGFloat($0.powerOutputWatts ?? 0) }
                let levelYs   = pts.map { CGFloat($0.powerLevel0to10 * 4.5) } // scale level to ~W for overlay
                let maxWatts  = max(wattsYs.max() ?? 10, 10)
                chartView.yMin  = 0
                chartView.yMax  = maxWatts + (maxWatts * 0.1)
                chartView.yUnit = "W"
                chartView.seriesData = [
                    LineChartView.Series(label: "Output (W)", color: Theme.accentRed,  points: wattsYs),
                    LineChartView.Series(label: "Set level",  color: UIColor(white: 0.4, alpha: 1), points: levelYs)
                ]
            } else {
                let powerYs = pts.map { CGFloat($0.powerLevel0to10) }
                chartView.yMin  = 0
                chartView.yMax  = 10
                chartView.yUnit = ""
                chartView.seriesData = [
                    LineChartView.Series(label: "Level", color: Theme.accentRed, points: powerYs)
                ]
            }
        }
    }

    private func renderLegend() {
        legendStack.arrangedSubviews.forEach {
            legendStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let hasPowerOutput = displaySession?.dataPoints.contains { $0.powerOutputWatts != nil } ?? false
        let heatingItems: [(String, UIColor)] = hasPowerOutput
            ? [("Power Output (W)", Theme.accentRed), ("Set Level", UIColor(white: 0.4, alpha: 1))]
            : [("Heating Level (0–10)", Theme.accentRed)]
        let items: [(String, UIColor)] = showTemperature
            ? [("Jacket Temp", Theme.accentRed), ("Outside Temp", Theme.accentBlue)]
            : heatingItems

        for (label, color) in items {
            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false

            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = color
            dot.layer.cornerRadius = 4
            row.addSubview(dot)

            let lbl = makeLabel(label, size: 11, weight: .regular, color: Theme.secondaryText)
            row.addSubview(lbl)

            NSLayoutConstraint.activate([
                dot.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                dot.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                dot.widthAnchor.constraint(equalToConstant: 8),
                dot.heightAnchor.constraint(equalToConstant: 8),
                lbl.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 5),
                lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                lbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                row.heightAnchor.constraint(equalToConstant: 20)
            ])

            legendStack.addArrangedSubview(row)
        }
    }

    private func renderHistory(sessions: [Session]) {
        historyStack.arrangedSubviews.forEach {
            historyStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        sessionsList = Array(sessions.prefix(20))

        if sessionsList.isEmpty {
            let placeholder = UIView()
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            placeholder.heightAnchor.constraint(equalToConstant: 70).isActive = true

            let lbl = makeLabel("Connect your jacket to start\nrecording session data.",
                                size: 13, weight: .regular, color: Theme.secondaryText)
            lbl.textAlignment = .center
            lbl.numberOfLines = 0
            placeholder.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: placeholder.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: placeholder.centerYAnchor),
                lbl.leadingAnchor.constraint(greaterThanOrEqualTo: placeholder.leadingAnchor, constant: 20),
                lbl.trailingAnchor.constraint(lessThanOrEqualTo: placeholder.trailingAnchor, constant: -20)
            ])
            historyStack.addArrangedSubview(placeholder)
        } else {
            for (index, session) in sessionsList.enumerated() {
                historyStack.addArrangedSubview(makeSessionRow(session, index: index))
            }
        }
    }

    // MARK: - Actions

    @objc private func segmentChanged() {
        showTemperature = segmentControl.selectedSegmentIndex == 0
        renderChart()
        renderLegend()
    }

    @objc private func sessionRowTapped(_ sender: UIButton) {
        guard sender.tag < sessionsList.count else { return }
        let detail = SessionDetailViewController()
        detail.session = sessionsList[sender.tag]
        navigationController?.pushViewController(detail, animated: true)
    }

    // MARK: - View factories

    private func makeCard() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = Theme.card
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        v.layer.borderColor = Theme.border.cgColor
        return v
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.attributedText = NSAttributedString(string: text, attributes: [
            .kern: CGFloat(2.0),
            .foregroundColor: Theme.secondaryText,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ])
        return lbl
    }

    private func makeLabel(_ text: String, size: CGFloat,
                           weight: UIFont.Weight, color: UIColor) -> UILabel {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: size, weight: weight)
        lbl.textColor = color
        return lbl
    }

    private func makeStatCell(title: String, value: String, color: UIColor) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = makeLabel(title, size: 9, weight: .medium, color: Theme.secondaryText)
        titleLbl.textAlignment = .center

        let valueLbl = makeLabel(value, size: 17, weight: .bold, color: color)
        valueLbl.textAlignment = .center
        valueLbl.adjustsFontSizeToFitWidth = true
        valueLbl.minimumScaleFactor = 0.65
        valueLbl.numberOfLines = 1

        container.addSubview(titleLbl)
        container.addSubview(valueLbl)

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: container.topAnchor),
            titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            valueLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 5),
            valueLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            valueLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLbl.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func makeSessionRow(_ session: Session, index: Int) -> UIView {
        let card = makeCard()
        card.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .short

        let dateLbl     = makeLabel(dateFmt.string(from: session.startDate),
                                    size: 13, weight: .medium, color: Theme.primaryText)
        let durationLbl = makeLabel(formatDuration(session.duration),
                                    size: 12, weight: .regular, color: Theme.secondaryText)
        let powerLbl    = makeLabel(String(format: "%.1f / 10", session.averagePower0to10),
                                    size: 14, weight: .bold, color: Theme.accentRed)
        powerLbl.textAlignment = .right

        let powerTitle  = makeLabel("AVG POWER", size: 9, weight: .medium, color: Theme.secondaryText)
        powerTitle.textAlignment = .right

        let energyLbl   = makeLabel(String(format: "~%.1f Wh", session.estimatedEnergyWh),
                                    size: 11, weight: .regular, color: Theme.secondaryText)
        energyLbl.textAlignment = .right

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.tintColor = Theme.secondaryText
        chevron.contentMode = .scaleAspectFit

        for v in [dateLbl, durationLbl, powerLbl, powerTitle, energyLbl, chevron] { card.addSubview(v) }

        NSLayoutConstraint.activate([
            dateLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            dateLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            dateLbl.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

            durationLbl.topAnchor.constraint(equalTo: dateLbl.bottomAnchor, constant: 4),
            durationLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            powerLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            powerLbl.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),

            powerTitle.topAnchor.constraint(equalTo: powerLbl.bottomAnchor, constant: 2),
            powerTitle.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),

            energyLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            energyLbl.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),

            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            chevron.widthAnchor.constraint(equalToConstant: 10),
            chevron.heightAnchor.constraint(equalToConstant: 16)
        ])

        // Full-card tap button (invisible overlay)
        let tapBtn = UIButton(type: .system)
        tapBtn.translatesAutoresizingMaskIntoConstraints = false
        tapBtn.tag = index
        tapBtn.addTarget(self, action: #selector(sessionRowTapped(_:)), for: .touchUpInside)
        card.addSubview(tapBtn)
        NSLayoutConstraint.activate([
            tapBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            tapBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            tapBtn.topAnchor.constraint(equalTo: card.topAnchor),
            tapBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        return card
    }

    // MARK: - Utility

    private func formatDuration(_ duration: TimeInterval) -> String {
        let s = Int(duration)
        let h = s / 3600
        let m = (s % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "< 1m"
    }
}

// MARK: - SessionDetailViewController

class SessionDetailViewController: UIViewController {

    // MARK: - Input

    var session: Session!

    // MARK: - State

    private var showTemperature = true

    // MARK: - Views

    private lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.showsVerticalScrollIndicator = false
        return v
    }()

    private lazy var contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var statsCard: UIView = makeCard()

    private lazy var segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["TEMPERATURE", "HEATING"])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentIndex = 0
        sc.backgroundColor = Theme.card
        sc.selectedSegmentTintColor = Theme.accentRed
        sc.setTitleTextAttributes(
            [.foregroundColor: Theme.secondaryText,
             .font: UIFont.systemFont(ofSize: 11, weight: .semibold)],
            for: .normal)
        sc.setTitleTextAttributes(
            [.foregroundColor: UIColor.white,
             .font: UIFont.systemFont(ofSize: 11, weight: .semibold)],
            for: .selected)
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return sc
    }()

    private lazy var chartView: LineChartView = {
        let cv = LineChartView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = Theme.card
        cv.layer.cornerRadius = 12
        cv.layer.borderWidth = 1
        cv.layer.borderColor = Theme.border.cgColor
        cv.clipsToBounds = true
        return cv
    }()

    private lazy var legendStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.spacing = 20
        sv.alignment = .center
        return sv
    }()

    private lazy var extraStatsCard: UIView = makeCard()

    /// Overlaid on chartView; shows last sync time when session is live.
    private lazy var lastUpdateLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = UIFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular)
        lbl.textColor = UIColor(white: 0.38, alpha: 1)
        lbl.isHidden = true
        return lbl
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background

        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .short
        title = dateFmt.string(from: session.startDate)

        setupNavBar()
        buildLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        renderAll()
        if session.isActive { startLiveUpdates() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopLiveUpdates()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Nav bar

    private func setupNavBar() {
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = Theme.background
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ]
    }

    // MARK: - Layout

    private func buildLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        let statsHeader = makeSectionLabel("SESSION STATS")
        let chartHeader = makeSectionLabel("DATA")

        contentView.addSubview(statsHeader)
        contentView.addSubview(statsCard)
        contentView.addSubview(chartHeader)
        contentView.addSubview(segmentControl)
        contentView.addSubview(chartView)
        chartView.addSubview(lastUpdateLabel)
        contentView.addSubview(legendStack)
        contentView.addSubview(extraStatsCard)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            statsHeader.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            statsHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            statsCard.topAnchor.constraint(equalTo: statsHeader.bottomAnchor, constant: 10),
            statsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsCard.heightAnchor.constraint(equalToConstant: 90),

            chartHeader.topAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: 28),
            chartHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            segmentControl.topAnchor.constraint(equalTo: chartHeader.bottomAnchor, constant: 10),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),

            chartView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 10),
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalToConstant: 250),

            lastUpdateLabel.topAnchor.constraint(equalTo: chartView.topAnchor, constant: 7),
            lastUpdateLabel.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: -10),

            legendStack.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 10),
            legendStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            extraStatsCard.topAnchor.constraint(equalTo: legendStack.bottomAnchor, constant: 20),
            extraStatsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            extraStatsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            extraStatsCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }

    // MARK: - Live updates (active sessions only)

    private func startLiveUpdates() {
        let bt = BluetoothController.getInstance()
        guard bt.isConnected() else { return }

        bt.listenTo(id: "SessionDetailViewController",
                    eventName: BluetoothController.Events.ON_UPDATE_CHARACTERISTIC) { [weak self] _ in
            DispatchQueue.main.async { self?.liveRefresh() }
        }
        bt.listenTo(id: "SessionDetailViewController",
                    eventName: BluetoothController.Events.ON_DEVICE_DISCONNECTED) { [weak self] _ in
            DispatchQueue.main.async { self?.stopLiveUpdates(); self?.renderAll() }
        }
    }

    private func stopLiveUpdates() {
        BluetoothController.getInstance()
            .removeListeners(id: "SessionDetailViewController", eventNameToRemoveOrNil: nil)
    }

    private func liveRefresh() {
        if let live = SessionLogger.shared.currentSessionForDisplay(), !live.dataPoints.isEmpty {
            session = live
        }
        renderStatsCard()
        renderChart()

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        lastUpdateLabel.text = "↑ \(fmt.string(from: Date()))"
        lastUpdateLabel.isHidden = false

        let pulse = CABasicAnimation(keyPath: "borderColor")
        pulse.fromValue = Theme.liveGreen.cgColor
        pulse.toValue   = Theme.border.cgColor
        pulse.duration  = 1.2
        pulse.timingFunction = CAMediaTimingFunction(name: .easeOut)
        chartView.layer.add(pulse, forKey: "liveFlash")
    }

    // MARK: - Render

    private func renderAll() {
        renderStatsCard()
        renderChart()
        renderLegend()
        renderExtraStats()
    }

    private func renderStatsCard() {
        statsCard.subviews.forEach { $0.removeFromSuperview() }

        let useFahrenheit = AppController.getTemperatureMeasure() == AppController.FAHRENHEIT
        let deltaC = session.tempDeltaCelsius
        let deltaStr = useFahrenheit
            ? String(format: "+%.1f°F", deltaC * 9.0 / 5.0)
            : String(format: "+%.1f°C", deltaC)
        let avgJacket = useFahrenheit
            ? AppController.celsiusToFahrenheit(value: session.averageJacketTempCelsius)
            : session.averageJacketTempCelsius
        let tempUnit = useFahrenheit ? "°F" : "°C"

        let statsRow = UIStackView()
        statsRow.translatesAutoresizingMaskIntoConstraints = false
        statsRow.axis = .horizontal
        statsRow.distribution = .fillEqually
        statsCard.addSubview(statsRow)

        NSLayoutConstraint.activate([
            statsRow.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 16),
            statsRow.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -16),
            statsRow.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 14),
            statsRow.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -14)
        ])

        let items: [(String, String, UIColor)] = [
            ("DURATION",    formatDuration(session.duration),                             Theme.primaryText),
            ("AVG POWER",   String(format: "%.1f / 10", session.averagePower0to10),       Theme.accentRed),
            ("TEMP DELTA",  deltaStr,                                                      Theme.accentBlue),
            ("AVG JACKET",  String(format: "%.1f%@", avgJacket, tempUnit),                Theme.primaryText)
        ]
        items.forEach { statsRow.addArrangedSubview(makeStatCell(title: $0.0, value: $0.1, color: $0.2)) }

        if session.isActive {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = Theme.liveGreen
            dot.layer.cornerRadius = 4
            statsCard.addSubview(dot)
            let liveLbl = makeLabel("LIVE", size: 9, weight: .bold, color: Theme.liveGreen)
            statsCard.addSubview(liveLbl)
            NSLayoutConstraint.activate([
                dot.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -14),
                dot.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 10),
                dot.widthAnchor.constraint(equalToConstant: 7),
                dot.heightAnchor.constraint(equalToConstant: 7),
                liveLbl.trailingAnchor.constraint(equalTo: dot.leadingAnchor, constant: -4),
                liveLbl.centerYAnchor.constraint(equalTo: dot.centerYAnchor)
            ])
        }
    }

    private func renderChart() {
        guard session.dataPoints.count >= 2 else {
            chartView.seriesData = []
            chartView.noDataMessage = "Not enough data points yet"
            return
        }

        let pts = session.dataPoints
        let useFahrenheit = AppController.getTemperatureMeasure() == AppController.FAHRENHEIT

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        let midIdx = pts.count / 2
        chartView.xLabels = [
            fmt.string(from: pts.first!.timestamp),
            fmt.string(from: pts[midIdx].timestamp),
            fmt.string(from: pts.last!.timestamp)
        ]

        if showTemperature {
            let convert: (Float) -> CGFloat = {
                CGFloat(useFahrenheit ? AppController.celsiusToFahrenheit(value: $0) : $0)
            }
            let jacketYs  = pts.map { convert($0.jacketTempCelsius) }
            let ambientYs = pts.map { convert($0.ambientTempCelsius) }
            let allY = jacketYs + ambientYs
            chartView.yMin  = (allY.min() ?? 0) - 2
            chartView.yMax  = (allY.max() ?? 30) + 2
            chartView.yUnit = useFahrenheit ? "°F" : "°C"
            chartView.seriesData = [
                LineChartView.Series(label: "Jacket",  color: Theme.accentRed,  points: jacketYs),
                LineChartView.Series(label: "Outside", color: Theme.accentBlue, points: ambientYs)
            ]
        } else {
            let hasPowerOutput = pts.contains { $0.powerOutputWatts != nil }
            if hasPowerOutput {
                let wattsYs  = pts.map { CGFloat($0.powerOutputWatts ?? 0) }
                let levelYs  = pts.map { CGFloat($0.powerLevel0to10 * 4.5) }
                let maxWatts = max(wattsYs.max() ?? 10, 10)
                chartView.yMin  = 0
                chartView.yMax  = maxWatts + (maxWatts * 0.1)
                chartView.yUnit = "W"
                chartView.seriesData = [
                    LineChartView.Series(label: "Output (W)", color: Theme.accentRed, points: wattsYs),
                    LineChartView.Series(label: "Set level",  color: UIColor(white: 0.4, alpha: 1), points: levelYs)
                ]
            } else {
                let powerYs = pts.map { CGFloat($0.powerLevel0to10) }
                chartView.yMin  = 0
                chartView.yMax  = 10
                chartView.yUnit = ""
                chartView.seriesData = [
                    LineChartView.Series(label: "Level", color: Theme.accentRed, points: powerYs)
                ]
            }
        }
    }

    private func renderLegend() {
        legendStack.arrangedSubviews.forEach { legendStack.removeArrangedSubview($0); $0.removeFromSuperview() }

        let hasPowerOutput = session.dataPoints.contains { $0.powerOutputWatts != nil }
        let heatingItems: [(String, UIColor)] = hasPowerOutput
            ? [("Power Output (W)", Theme.accentRed), ("Set Level", UIColor(white: 0.4, alpha: 1))]
            : [("Heating Level (0–10)", Theme.accentRed)]
        let items: [(String, UIColor)] = showTemperature
            ? [("Jacket Temp", Theme.accentRed), ("Outside Temp", Theme.accentBlue)]
            : heatingItems

        for (label, color) in items {
            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = color
            dot.layer.cornerRadius = 4
            row.addSubview(dot)
            let lbl = makeLabel(label, size: 11, weight: .regular, color: Theme.secondaryText)
            row.addSubview(lbl)
            NSLayoutConstraint.activate([
                dot.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                dot.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                dot.widthAnchor.constraint(equalToConstant: 8),
                dot.heightAnchor.constraint(equalToConstant: 8),
                lbl.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 5),
                lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                lbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                row.heightAnchor.constraint(equalToConstant: 20)
            ])
            legendStack.addArrangedSubview(row)
        }
    }

    private func renderExtraStats() {
        extraStatsCard.subviews.forEach { $0.removeFromSuperview() }

        let useFahrenheit = AppController.getTemperatureMeasure() == AppController.FAHRENHEIT
        let tempUnit = useFahrenheit ? "°F" : "°C"

        func convertTemp(_ c: Float) -> Float {
            useFahrenheit ? AppController.celsiusToFahrenheit(value: c) : c
        }

        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .none
        dateFmt.timeStyle = .medium

        let rows: [(String, String)] = [
            ("Start time",        dateFmt.string(from: session.startDate)),
            ("End time",          session.endDate.map { dateFmt.string(from: $0) } ?? "Active"),
            ("Data points",       "\(session.dataPoints.count)"),
            ("Avg jacket temp",   String(format: "%.1f%@", convertTemp(session.averageJacketTempCelsius), tempUnit)),
            ("Avg ambient temp",  String(format: "%.1f%@", convertTemp(session.averageAmbientTempCelsius), tempUnit)),
            ("Est. energy used",  String(format: "~%.1f Wh", session.estimatedEnergyWh))
        ]

        var prevAnchor = extraStatsCard.topAnchor
        var prevConstant: CGFloat = 14

        for (i, (key, val)) in rows.enumerated() {
            let keyLbl = makeLabel(key, size: 12, weight: .regular, color: Theme.secondaryText)
            let valLbl = makeLabel(val, size: 12, weight: .medium, color: Theme.primaryText)
            valLbl.textAlignment = .right

            extraStatsCard.addSubview(keyLbl)
            extraStatsCard.addSubview(valLbl)

            NSLayoutConstraint.activate([
                keyLbl.topAnchor.constraint(equalTo: prevAnchor, constant: prevConstant),
                keyLbl.leadingAnchor.constraint(equalTo: extraStatsCard.leadingAnchor, constant: 16),

                valLbl.centerYAnchor.constraint(equalTo: keyLbl.centerYAnchor),
                valLbl.trailingAnchor.constraint(equalTo: extraStatsCard.trailingAnchor, constant: -16),
                valLbl.leadingAnchor.constraint(greaterThanOrEqualTo: keyLbl.trailingAnchor, constant: 8)
            ])

            if i == rows.count - 1 {
                keyLbl.bottomAnchor.constraint(equalTo: extraStatsCard.bottomAnchor, constant: -14).isActive = true
            }

            prevAnchor = keyLbl.bottomAnchor
            prevConstant = 12
        }
    }

    // MARK: - Actions

    @objc private func segmentChanged() {
        showTemperature = segmentControl.selectedSegmentIndex == 0
        renderChart()
        renderLegend()
    }

    // MARK: - Helpers

    private func makeCard() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = Theme.card
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        v.layer.borderColor = Theme.border.cgColor
        return v
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.attributedText = NSAttributedString(string: text, attributes: [
            .kern: CGFloat(2.0),
            .foregroundColor: Theme.secondaryText,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ])
        return lbl
    }

    private func makeLabel(_ text: String, size: CGFloat,
                           weight: UIFont.Weight, color: UIColor) -> UILabel {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: size, weight: weight)
        lbl.textColor = color
        return lbl
    }

    private func makeStatCell(title: String, value: String, color: UIColor) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = makeLabel(title, size: 9, weight: .medium, color: Theme.secondaryText)
        titleLbl.textAlignment = .center

        let valueLbl = makeLabel(value, size: 14, weight: .bold, color: color)
        valueLbl.textAlignment = .center
        valueLbl.adjustsFontSizeToFitWidth = true
        valueLbl.minimumScaleFactor = 0.6
        valueLbl.numberOfLines = 1

        container.addSubview(titleLbl)
        container.addSubview(valueLbl)

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: container.topAnchor),
            titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            valueLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 5),
            valueLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            valueLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLbl.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let s = Int(duration)
        let h = s / 3600
        let m = (s % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "< 1m"
    }
}

// MARK: - LineChartView

class LineChartView: UIView {

    struct Series {
        let label: String
        let color: UIColor
        let points: [CGFloat]  // y values; x is evenly spaced
    }

    var seriesData: [Series] = [] { didSet { setNeedsDisplay() } }
    var yMin: CGFloat = 0
    var yMax: CGFloat = 10
    var xLabels: [String] = []
    var yUnit: String = ""
    var noDataMessage: String = "No data yet"

    private let insets = UIEdgeInsets(top: 16, left: 48, bottom: 30, right: 16)

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let chartRect = CGRect(
            x: bounds.minX + insets.left,
            y: bounds.minY + insets.top,
            width: bounds.width  - insets.left - insets.right,
            height: bounds.height - insets.top  - insets.bottom
        )

        if !seriesData.contains(where: { !$0.points.isEmpty }) {
            drawNoData()
            return
        }

        drawGrid(chartRect: chartRect)
        drawYLabels(chartRect: chartRect)
        drawXLabels(chartRect: chartRect)
        seriesData.forEach { drawSeries($0, in: chartRect, ctx: ctx) }
    }

    private func drawNoData() {
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(white: 0.35, alpha: 1),
            .font: UIFont.systemFont(ofSize: 12)
        ]
        let str = noDataMessage as NSString
        let sz  = str.size(withAttributes: attrs)
        str.draw(at: CGPoint(x: bounds.midX - sz.width / 2,
                             y: bounds.midY - sz.height / 2),
                 withAttributes: attrs)
    }

    private func drawGrid(chartRect: CGRect) {
        UIColor(white: 0.18, alpha: 1).setStroke()
        for i in 0...4 {
            let y = chartRect.minY + chartRect.height * CGFloat(i) / 4
            let p = UIBezierPath()
            p.move(to: CGPoint(x: chartRect.minX, y: y))
            p.addLine(to: CGPoint(x: chartRect.maxX, y: y))
            p.lineWidth = 0.5
            p.stroke()
        }
    }

    private func drawYLabels(chartRect: CGRect) {
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(white: 0.42, alpha: 1),
            .font: UIFont.systemFont(ofSize: 9)
        ]
        for i in 0...4 {
            let frac  = CGFloat(4 - i) / 4
            let y     = chartRect.minY + chartRect.height * CGFloat(i) / 4
            let value = yMin + (yMax - yMin) * frac
            let str   = "\(Int(round(value)))\(yUnit)" as NSString
            let sz    = str.size(withAttributes: attrs)
            str.draw(at: CGPoint(x: chartRect.minX - sz.width - 4,
                                 y: y - sz.height / 2),
                     withAttributes: attrs)
        }
    }

    private func drawXLabels(chartRect: CGRect) {
        guard xLabels.count >= 2 else { return }
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(white: 0.42, alpha: 1),
            .font: UIFont.systemFont(ofSize: 9)
        ]
        let positions: [CGFloat] = [0, 0.5, 1.0]
        let labels = xLabels.count >= 3
            ? Array(xLabels.prefix(3))
            : [xLabels[0], "", xLabels.last ?? ""]

        for (i, label) in labels.enumerated() {
            guard !label.isEmpty else { continue }
            let x  = chartRect.minX + chartRect.width * positions[i]
            let s  = label as NSString
            let sz = s.size(withAttributes: attrs)
            s.draw(at: CGPoint(x: x - sz.width / 2, y: chartRect.maxY + 5),
                   withAttributes: attrs)
        }
    }

    private func drawSeries(_ series: Series, in chartRect: CGRect, ctx: CGContext) {
        guard series.points.count >= 2 else { return }

        let pts: [CGPoint] = series.points.enumerated().map { idx, val in
            CGPoint(
                x: chartRect.minX + chartRect.width * CGFloat(idx) / CGFloat(series.points.count - 1),
                y: yToChart(val, in: chartRect)
            )
        }

        // Gradient fill under the line
        let fillPath = smoothCurve(pts)
        fillPath.addLine(to: CGPoint(x: pts.last!.x, y: chartRect.maxY))
        fillPath.addLine(to: CGPoint(x: pts.first!.x, y: chartRect.maxY))
        fillPath.close()

        ctx.saveGState()
        fillPath.addClip()
        let colors = [series.color.withAlphaComponent(0.25).cgColor,
                      series.color.withAlphaComponent(0.0).cgColor] as CFArray
        if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: colors, locations: [0, 1]) {
            ctx.drawLinearGradient(grad,
                                   start: CGPoint(x: 0, y: chartRect.minY),
                                   end:   CGPoint(x: 0, y: chartRect.maxY),
                                   options: [])
        }
        ctx.restoreGState()

        // Smooth line stroke
        let line = smoothCurve(pts)
        series.color.setStroke()
        line.lineWidth = 2
        line.lineCapStyle = .round
        line.lineJoinStyle = .round
        line.stroke()
    }

    // MARK: - Helpers

    private func yToChart(_ value: CGFloat, in rect: CGRect) -> CGFloat {
        let range = yMax - yMin
        guard range > 0 else { return rect.midY }
        return rect.maxY - ((value - yMin) / range) * rect.height
    }

    private func smoothCurve(_ points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        guard !points.isEmpty else { return path }
        path.move(to: points[0])
        guard points.count > 1 else { return path }
        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let pp   = i > 1 ? points[i - 2] : prev
            let next = i + 1 < points.count ? points[i + 1] : curr
            let cp1  = CGPoint(x: prev.x + (curr.x - pp.x)   / 6,
                               y: prev.y + (curr.y - pp.y)   / 6)
            let cp2  = CGPoint(x: curr.x - (next.x - prev.x) / 6,
                               y: curr.y - (next.y - prev.y) / 6)
            path.addCurve(to: curr, controlPoint1: cp1, controlPoint2: cp2)
        }
        return path
    }
}
