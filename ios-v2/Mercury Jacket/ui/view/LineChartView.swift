import UIKit

class LineChartView: UIView {

    struct Series {
        let label: String
        let color: UIColor
        let points: [CGFloat]
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
