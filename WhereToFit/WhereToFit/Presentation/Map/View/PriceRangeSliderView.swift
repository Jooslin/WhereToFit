import UIKit

final class PriceRangeSliderView: UIControl {
    private enum Thumb {
        case minimum
        case maximum
    }

    private let binCount = 28
    private let handleRadius: CGFloat = 5
    private let touchAreaOutset: CGFloat = 18
    private let priceStep = 1_000

    private var activeThumb: Thumb?
    private var histogramValues: [CGFloat] = []

    private(set) var minimumPrice = 0
    private(set) var maximumPrice = 300_000
    private(set) var selectedMinimumPrice = 0
    private(set) var selectedMaximumPrice = 300_000

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        configure(priceSamples: [], selectedMinimumPrice: nil, selectedMaximumPrice: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(priceSamples: [Int], selectedMinimumPrice: Int?, selectedMaximumPrice: Int?) {
        minimumPrice = 0
        maximumPrice = roundedMaximumPrice(from: priceSamples)
        histogramValues = makeHistogram(from: priceSamples)
        setSelectedRange(
            minimumPrice: selectedMinimumPrice,
            maximumPrice: selectedMaximumPrice,
            sendsValueChanged: false
        )
    }

    func setSelectedRange(minimumPrice: Int?, maximumPrice: Int?, sendsValueChanged: Bool = false) {
        let nextMinimumPrice = normalize(price: minimumPrice ?? self.minimumPrice)
        let nextMaximumPrice = normalize(price: maximumPrice ?? self.maximumPrice)

        selectedMinimumPrice = min(nextMinimumPrice, nextMaximumPrice)
        selectedMaximumPrice = max(nextMinimumPrice, nextMaximumPrice)
        setNeedsDisplay()

        if sendsValueChanged {
            sendActions(for: .valueChanged)
        }
    }

    override func draw(_ rect: CGRect) {
        let graphRect = rect.insetBy(dx: handleRadius, dy: 2)
        let baselineY = graphRect.maxY - handleRadius
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: graphRect.minX, y: baselineY))
        linePath.addLine(to: CGPoint(x: graphRect.maxX, y: baselineY))
        UIColor.gray200.setStroke()
        linePath.lineWidth = 1
        linePath.stroke()

        let graphPath = makeGraphPath(in: graphRect, baselineY: baselineY)
        UIColor.gray100.setFill()
        graphPath.fill()

        let selectedMinimumX = xPosition(for: selectedMinimumPrice, in: graphRect)
        let selectedMaximumX = xPosition(for: selectedMaximumPrice, in: graphRect)

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        UIBezierPath(rect: CGRect(
            x: selectedMinimumX,
            y: graphRect.minY,
            width: selectedMaximumX - selectedMinimumX,
            height: graphRect.height
        )).addClip()
        UIColor.primary100.setFill()
        graphPath.fill()
        context.restoreGState()

        let selectedLinePath = UIBezierPath()
        selectedLinePath.move(to: CGPoint(x: selectedMinimumX, y: baselineY))
        selectedLinePath.addLine(to: CGPoint(x: selectedMaximumX, y: baselineY))
        UIColor.primary700.setStroke()
        selectedLinePath.lineWidth = 2
        selectedLinePath.lineCapStyle = .round
        selectedLinePath.stroke()

        [selectedMinimumX, selectedMaximumX].forEach { x in
            let dotPath = UIBezierPath(
                ovalIn: CGRect(
                    x: x - handleRadius,
                    y: baselineY - handleRadius,
                    width: handleRadius * 2,
                    height: handleRadius * 2
                )
            )
            UIColor.primary700.setFill()
            dotPath.fill()
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: -touchAreaOutset, dy: -touchAreaOutset).contains(point)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        activeThumb = nearestThumb(to: touch.location(in: self).x)
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard let activeThumb else { return false }

        let graphRect = bounds.insetBy(dx: handleRadius, dy: 2)
        let touchedPrice = price(forX: touch.location(in: self).x, in: graphRect)

        switch activeThumb {
        case .minimum:
            selectedMinimumPrice = min(touchedPrice, selectedMaximumPrice)
        case .maximum:
            selectedMaximumPrice = max(touchedPrice, selectedMinimumPrice)
        }

        setNeedsDisplay()
        sendActions(for: .valueChanged)
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        activeThumb = nil
    }

    override func cancelTracking(with event: UIEvent?) {
        activeThumb = nil
    }

    private func nearestThumb(to touchX: CGFloat) -> Thumb {
        let graphRect = bounds.insetBy(dx: handleRadius, dy: 2)
        let minimumThumbDistance = abs(xPosition(for: selectedMinimumPrice, in: graphRect) - touchX)
        let maximumThumbDistance = abs(xPosition(for: selectedMaximumPrice, in: graphRect) - touchX)
        return minimumThumbDistance <= maximumThumbDistance ? .minimum : .maximum
    }

    private func xPosition(for price: Int, in rect: CGRect) -> CGFloat {
        guard maximumPrice > minimumPrice else {
            return rect.minX
        }

        let progress = CGFloat(price - minimumPrice) / CGFloat(maximumPrice - minimumPrice)
        return rect.minX + rect.width * min(max(progress, 0), 1)
    }

    private func price(forX xPosition: CGFloat, in rect: CGRect) -> Int {
        guard maximumPrice > minimumPrice else {
            return minimumPrice
        }

        let progress = min(max((xPosition - rect.minX) / rect.width, 0), 1)
        let rawPrice = minimumPrice + Int(round(CGFloat(maximumPrice - minimumPrice) * progress))
        return normalize(price: rawPrice)
    }

    private func normalize(price: Int) -> Int {
        let clampedPrice = min(max(price, minimumPrice), maximumPrice)
        return (clampedPrice / priceStep) * priceStep
    }

    private func makeGraphPath(in rect: CGRect, baselineY: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX, y: baselineY))

        guard histogramValues.isEmpty == false else {
            path.addLine(to: CGPoint(x: rect.maxX, y: baselineY))
            path.addLine(to: CGPoint(x: rect.minX, y: baselineY))
            path.close()
            return path
        }

        let maxGraphHeight = max(rect.height - handleRadius - 4, 1)
        let graphPoints = histogramValues.enumerated().map { index, value in
            let progress = histogramValues.count == 1
                ? 0
                : CGFloat(index) / CGFloat(histogramValues.count - 1)
            return CGPoint(
                x: rect.minX + rect.width * progress,
                y: baselineY - maxGraphHeight * value
            )
        }

        graphPoints.enumerated().forEach { index, point in
            if index == 0 {
                path.addLine(to: point)
            } else {
                let previousPoint = graphPoints[index - 1]
                let middleX = (previousPoint.x + point.x) / 2
                path.addCurve(
                    to: point,
                    controlPoint1: CGPoint(x: middleX, y: previousPoint.y),
                    controlPoint2: CGPoint(x: middleX, y: point.y)
                )
            }
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: baselineY))
        path.addLine(to: CGPoint(x: rect.minX, y: baselineY))
        path.close()
        return path
    }

    private func makeHistogram(from prices: [Int]) -> [CGFloat] {
        let validPrices = prices.filter { $0 >= minimumPrice }

        guard validPrices.isEmpty == false else {
            return makePlaceholderHistogram()
        }

        var bins = Array(repeating: 0, count: binCount)
        validPrices.forEach { price in
            let progress = CGFloat(min(max(price, minimumPrice), maximumPrice) - minimumPrice)
                / CGFloat(max(maximumPrice - minimumPrice, 1))
            let index = min(Int((progress * CGFloat(binCount - 1)).rounded()), binCount - 1)
            bins[index] += 1
        }

        let maxCount = max(bins.max() ?? 1, 1)
        return bins.map { CGFloat($0) / CGFloat(maxCount) }
    }

    private func makePlaceholderHistogram() -> [CGFloat] {
        (0..<binCount).map { index in
            let progress = CGFloat(index) / CGFloat(binCount - 1)
            return max(0, 1 - abs(progress - 0.45) * 2.4) * 0.9
        }
    }

    private func roundedMaximumPrice(from prices: [Int]) -> Int {
        let highestPrice = prices.max() ?? maximumPrice
        let roundedPrice = Int(ceil(Double(max(highestPrice, priceStep)) / 10_000.0)) * 10_000
        return max(roundedPrice, 10_000)
    }
}
