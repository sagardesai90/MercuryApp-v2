import UIKit

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

    private lazy var extraStatsCard: UIView = makeCard()

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

        let statsHeader = makeSectionLabel("SESSION STATS")
        let chartHeader = makeSectionLabel("DATA")

        contentView.addSubview(statsHeader)
        contentView.addSubview(statsCard)
        contentView.addSubview(chartHeader)
        contentView.addSubview(segmentControl)
        contentView.addSubview(chartContainer)
        chartContainer.addSubview(chartView)
        chartContainer.addSubview(lastUpdateLabel)
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

            chartContainer.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 10),
            chartContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chartContainer.heightAnchor.constraint(equalToConstant: 250),

            chartView.topAnchor.constraint(equalTo: chartContainer.topAnchor),
            chartView.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor),
            chartView.bottomAnchor.constraint(equalTo: chartContainer.bottomAnchor),

            lastUpdateLabel.topAnchor.constraint(equalTo: chartContainer.topAnchor, constant: 7),
            lastUpdateLabel.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor, constant: -10),

            legendStack.topAnchor.constraint(equalTo: chartContainer.bottomAnchor, constant: 10),
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
        pulse.fromValue = StatsTheme.liveGreen.cgColor
        pulse.toValue   = StatsTheme.border.cgColor
        pulse.duration  = 1.2
        pulse.timingFunction = CAMediaTimingFunction(name: .easeOut)
        chartContainer.layer.add(pulse, forKey: "liveFlash")
    }

    // MARK: - Render

    private func renderAll() {
        renderStatsCard()
        renderChart()
        renderLegend()
        renderExtraStats()
    }

    private var statsCardContent: UIView? {
        statsCard.viewWithTag(StatsTheme.glassContentTag)
    }

    private func renderStatsCard() {
        let host = statsCardContent ?? statsCard
        host.subviews.forEach { $0.removeFromSuperview() }

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
        host.addSubview(statsRow)

        NSLayoutConstraint.activate([
            statsRow.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 16),
            statsRow.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -16),
            statsRow.topAnchor.constraint(equalTo: host.topAnchor, constant: 14),
            statsRow.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -14)
        ])

        let items: [(String, String, UIColor)] = [
            ("DURATION",    formatDuration(session.duration),                             StatsTheme.primaryText),
            ("AVG POWER",   String(format: "%.1f / 10", session.averagePower0to10),       StatsTheme.accentRed),
            ("TEMP DELTA",  deltaStr,                                                      StatsTheme.accentBlue),
            ("AVG GARMENT",  String(format: "%.1f%@", avgJacket, tempUnit),                StatsTheme.primaryText)
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
                LineChartView.Series(label: "Garment",  color: StatsTheme.accentRed,  points: jacketYs),
                LineChartView.Series(label: "Outside", color: StatsTheme.accentBlue, points: ambientYs)
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
                    LineChartView.Series(label: "Output (W)", color: StatsTheme.accentRed, points: wattsYs),
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
        legendStack.arrangedSubviews.forEach { legendStack.removeArrangedSubview($0); $0.removeFromSuperview() }

        let hasPowerOutput = session.dataPoints.contains { $0.powerOutputWatts != nil }
        let heatingItems: [(String, UIColor)] = hasPowerOutput
            ? [("Power Output (W)", StatsTheme.accentRed), ("Set Level", UIColor(white: 0.4, alpha: 1))]
            : [("Heating Level (0–10)", StatsTheme.accentRed)]
        let items: [(String, UIColor)] = showTemperature
            ? [("Garment", StatsTheme.accentRed), ("Outside", StatsTheme.accentBlue)]
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

    private var extraStatsContent: UIView? {
        extraStatsCard.viewWithTag(StatsTheme.glassContentTag)
    }

    private func renderExtraStats() {
        let host = extraStatsContent ?? extraStatsCard
        host.subviews.forEach { $0.removeFromSuperview() }

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
            ("Avg garment temp",   String(format: "%.1f%@", convertTemp(session.averageJacketTempCelsius), tempUnit)),
            ("Avg ambient temp",  String(format: "%.1f%@", convertTemp(session.averageAmbientTempCelsius), tempUnit)),
            ("Est. energy used",  String(format: "~%.1f Wh", session.estimatedEnergyWh))
        ]

        var prevAnchor = host.topAnchor
        var prevConstant: CGFloat = 14

        for (i, (key, val)) in rows.enumerated() {
            let keyLbl = makeLabel(key, size: 12, weight: .regular, color: StatsTheme.secondaryText)
            let valLbl = makeLabel(val, size: 12, weight: .medium, color: StatsTheme.primaryText)
            valLbl.textAlignment = .right

            host.addSubview(keyLbl)
            host.addSubview(valLbl)

            NSLayoutConstraint.activate([
                keyLbl.topAnchor.constraint(equalTo: prevAnchor, constant: prevConstant),
                keyLbl.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 16),

                valLbl.centerYAnchor.constraint(equalTo: keyLbl.centerYAnchor),
                valLbl.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -16),
                valLbl.leadingAnchor.constraint(greaterThanOrEqualTo: keyLbl.trailingAnchor, constant: 8)
            ])

            if i == rows.count - 1 {
                keyLbl.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -14).isActive = true
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
