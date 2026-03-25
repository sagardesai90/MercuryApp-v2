import UIKit

class StatsViewController: UIViewController {

    // MARK: - State

    private var showTemperature = true
    private var displaySession: Session?
    private var isLive = false
    private var sessionsList: [Session] = []

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
        sc.backgroundColor = StatsTheme.card.withAlphaComponent(0.3)
        sc.selectedSegmentTintColor = StatsTheme.accentRed.withAlphaComponent(0.85)
        sc.setTitleTextAttributes(
            [.foregroundColor: StatsTheme.secondaryText,
             .font: UIFont.systemFont(ofSize: 11, weight: .semibold)],
            for: .normal)
        sc.setTitleTextAttributes(
            [.foregroundColor: UIColor.white,
             .font: UIFont.systemFont(ofSize: 11, weight: .semibold)],
            for: .selected)
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return sc
    }()

    private lazy var chartContainer: UIView = {
        return StatsTheme.makeGlassCard(cornerRadius: 12)
    }()

    private lazy var chartView: LineChartView = {
        let cv = LineChartView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.isOpaque = false
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
        view.backgroundColor = StatsTheme.background
        title = "STATISTICS"
        setupNavBar()
        buildLayout()
        configureAccessibility()
    }

    private func configureAccessibility() {
        segmentControl.accessibilityLabel = "Chart data type"
        segmentControl.accessibilityHint = "Switch between temperature and heating data"
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
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ]

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = StatsTheme.background.withAlphaComponent(0.7)
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
            ]
            appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialDark)
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
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
        contentView.addSubview(chartContainer)
        chartContainer.addSubview(chartView)
        chartContainer.addSubview(lastUpdateLabel)
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

            chartContainer.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 10),
            chartContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chartContainer.heightAnchor.constraint(equalToConstant: 250),

            chartView.topAnchor.constraint(equalTo: chartContainer.topAnchor),
            chartView.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor),
            chartView.bottomAnchor.constraint(equalTo: chartContainer.bottomAnchor),

            legendStack.topAnchor.constraint(equalTo: chartContainer.bottomAnchor, constant: 10),
            legendStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            historyHeader.topAnchor.constraint(equalTo: legendStack.bottomAnchor, constant: 28),
            historyHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            historyStack.topAnchor.constraint(equalTo: historyHeader.bottomAnchor, constant: 10),
            historyStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            historyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            historyStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),

            lastUpdateLabel.topAnchor.constraint(equalTo: chartContainer.topAnchor, constant: 7),
            lastUpdateLabel.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor, constant: -10)
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

    private func liveUpdate() {
        let logger = SessionLogger.shared
        if let live = logger.currentSessionForDisplay(), !live.dataPoints.isEmpty {
            displaySession = live
        }
        renderSessionCard()
        renderChart()

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        lastUpdateLabel.text = "↑ \(fmt.string(from: Date()))"
        lastUpdateLabel.isHidden = false

        let pulse = CABasicAnimation(keyPath: "borderColor")
        pulse.fromValue = StatsTheme.liveGreen.cgColor
        pulse.toValue   = StatsTheme.border.cgColor
        pulse.duration  = 1.2
        pulse.timingFunction = CAMediaTimingFunction(name: .easeOut)
        chartContainer.layer.add(pulse, forKey: "liveFlash")
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

    private var sessionCardContent: UIView? {
        sessionCard.viewWithTag(StatsTheme.glassContentTag)
    }

    private func renderSessionCard() {
        let host = sessionCardContent ?? sessionCard
        host.subviews.forEach { $0.removeFromSuperview() }

        guard let session = displaySession else {
            let lbl = makeLabel("No sessions recorded yet",
                                size: 13, weight: .regular, color: StatsTheme.secondaryText)
            lbl.textAlignment = .center
            host.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: host.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: host.centerYAnchor)
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
        host.addSubview(statsRow)

        NSLayoutConstraint.activate([
            statsRow.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 16),
            statsRow.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -16),
            statsRow.topAnchor.constraint(equalTo: host.topAnchor, constant: 14),
            statsRow.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -14)
        ])

        let items: [(String, String, UIColor)] = [
            ("DURATION",   formatDuration(session.duration),                               StatsTheme.primaryText),
            ("AVG POWER",  String(format: "%.1f / 10", session.averagePower0to10),         StatsTheme.accentRed),
            ("TEMP DELTA", deltaStr,                                                        StatsTheme.accentBlue)
        ]
        items.forEach { statsRow.addArrangedSubview(makeStatCell(title: $0.0, value: $0.1, color: $0.2)) }

        if session.isActive {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = StatsTheme.liveGreen
            dot.layer.cornerRadius = 4
            host.addSubview(dot)

            let liveLbl = makeLabel("LIVE", size: 9, weight: .bold, color: StatsTheme.liveGreen)
            host.addSubview(liveLbl)

            NSLayoutConstraint.activate([
                dot.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -14),
                dot.topAnchor.constraint(equalTo: host.topAnchor, constant: 10),
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
                LineChartView.Series(label: "Jacket",  color: StatsTheme.accentRed,  points: jacketYs),
                LineChartView.Series(label: "Outside", color: StatsTheme.accentBlue, points: ambientYs)
            ]
        } else {
            let hasPowerOutput = pts.contains { $0.powerOutputWatts != nil }

            if hasPowerOutput {
                let wattsYs   = pts.map { CGFloat($0.powerOutputWatts ?? 0) }
                let levelYs   = pts.map { CGFloat($0.powerLevel0to10 * 4.5) }
                let maxWatts  = max(wattsYs.max() ?? 10, 10)
                chartView.yMin  = 0
                chartView.yMax  = maxWatts + (maxWatts * 0.1)
                chartView.yUnit = "W"
                chartView.seriesData = [
                    LineChartView.Series(label: "Output (W)", color: StatsTheme.accentRed,  points: wattsYs),
                    LineChartView.Series(label: "Set level",  color: UIColor(white: 0.4, alpha: 1), points: levelYs)
                ]
            } else {
                let powerYs = pts.map { CGFloat($0.powerLevel0to10) }
                chartView.yMin  = 0
                chartView.yMax  = 10
                chartView.yUnit = ""
                chartView.seriesData = [
                    LineChartView.Series(label: "Level", color: StatsTheme.accentRed, points: powerYs)
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
            ? [("Power Output (W)", StatsTheme.accentRed), ("Set Level", UIColor(white: 0.4, alpha: 1))]
            : [("Heating Level (0–10)", StatsTheme.accentRed)]
        let items: [(String, UIColor)] = showTemperature
            ? [("Jacket Temp", StatsTheme.accentRed), ("Outside Temp", StatsTheme.accentBlue)]
            : heatingItems

        for (label, color) in items {
            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false

            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = color
            dot.layer.cornerRadius = 4
            row.addSubview(dot)

            let lbl = makeLabel(label, size: 11, weight: .regular, color: StatsTheme.secondaryText)
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
                                size: 13, weight: .regular, color: StatsTheme.secondaryText)
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
        return StatsTheme.makeGlassCard(cornerRadius: 12)
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.attributedText = NSAttributedString(string: text, attributes: [
            .kern: CGFloat(2.0),
            .foregroundColor: StatsTheme.secondaryText,
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

        let titleLbl = makeLabel(title, size: 9, weight: .medium, color: StatsTheme.secondaryText)
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
        let host = card.viewWithTag(StatsTheme.glassContentTag) ?? card

        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .short

        let dateLbl     = makeLabel(dateFmt.string(from: session.startDate),
                                    size: 13, weight: .medium, color: StatsTheme.primaryText)
        let durationLbl = makeLabel(formatDuration(session.duration),
                                    size: 12, weight: .regular, color: StatsTheme.secondaryText)
        let powerLbl    = makeLabel(String(format: "%.1f / 10", session.averagePower0to10),
                                    size: 14, weight: .bold, color: StatsTheme.accentRed)
        powerLbl.textAlignment = .right

        let powerTitle  = makeLabel("AVG POWER", size: 9, weight: .medium, color: StatsTheme.secondaryText)
        powerTitle.textAlignment = .right

        let energyLbl   = makeLabel(String(format: "~%.1f Wh", session.estimatedEnergyWh),
                                    size: 11, weight: .regular, color: StatsTheme.secondaryText)
        energyLbl.textAlignment = .right

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.tintColor = StatsTheme.secondaryText
        chevron.contentMode = .scaleAspectFit

        for v in [dateLbl, durationLbl, powerLbl, powerTitle, energyLbl, chevron] { host.addSubview(v) }

        NSLayoutConstraint.activate([
            dateLbl.topAnchor.constraint(equalTo: host.topAnchor, constant: 12),
            dateLbl.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 16),
            dateLbl.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

            durationLbl.topAnchor.constraint(equalTo: dateLbl.bottomAnchor, constant: 4),
            durationLbl.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 16),

            powerLbl.topAnchor.constraint(equalTo: host.topAnchor, constant: 12),
            powerLbl.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),

            powerTitle.topAnchor.constraint(equalTo: powerLbl.bottomAnchor, constant: 2),
            powerTitle.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),

            energyLbl.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -10),
            energyLbl.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),

            chevron.centerYAnchor.constraint(equalTo: host.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -14),
            chevron.widthAnchor.constraint(equalToConstant: 10),
            chevron.heightAnchor.constraint(equalToConstant: 16)
        ])

        let tapBtn = UIButton(type: .system)
        tapBtn.translatesAutoresizingMaskIntoConstraints = false
        tapBtn.tag = index
        tapBtn.addTarget(self, action: #selector(sessionRowTapped(_:)), for: .touchUpInside)
        host.addSubview(tapBtn)
        NSLayoutConstraint.activate([
            tapBtn.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            tapBtn.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            tapBtn.topAnchor.constraint(equalTo: host.topAnchor),
            tapBtn.bottomAnchor.constraint(equalTo: host.bottomAnchor)
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
