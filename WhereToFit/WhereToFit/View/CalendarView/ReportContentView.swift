//
//  ReportContentView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/16/26.
//

import SnapKit
import Then
import UIKit

final class ReportContentView: UIView {
    private let emptyView = EmptyReportContentView()
    private let reportView = ReportDashboardView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
        updateEmptyStateVisible(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ReportContentView {
    func updateEmptyStateVisible(_ isVisible: Bool) {
        emptyView.isHidden = !isVisible
        reportView.isHidden = isVisible
    }
}

private extension ReportContentView {
    func setLayout() {
        [
            emptyView,
            reportView
        ].forEach(addSubview)

        emptyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        reportView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

private final class EmptyReportContentView: UIView {
    let inputButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "정보 입력하러 가기"
    }

    private let emptyImageView = UIImageView().then {
        $0.image = UIImage(resource: .report)
        $0.contentMode = .scaleAspectFit
    }

    private let messageLabel = UILabel(
        text: "캘린더에서 정보를 입력하면\n리포트를 작성해드려요",
        config: .body16Medium,
        color: .gray600,
        lines: 2
    ).then {
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension EmptyReportContentView {
    func setLayout() {
        [
            emptyImageView,
            messageLabel,
            inputButton
        ].forEach(addSubview)

        emptyImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(118)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(220)
        }

        messageLabel.snp.makeConstraints {
            $0.top.equalTo(emptyImageView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        inputButton.snp.makeConstraints {
            $0.top.equalTo(messageLabel.snp.bottom).offset(28)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(48)
            $0.bottom.lessThanOrEqualToSuperview().inset(24)
        }
    }
}

private final class ReportDashboardView: UIView {
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 24
    }

    private let weightCard = ReportWeightCardView()
    private let exerciseCard = ReportExerciseCardView()
    private let conditionCard = ReportConditionCardView()
    private let summaryCard = ReportSummaryCardView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ReportDashboardView {
    func setLayout() {
        addSubview(stackView)

        [
            weightCard,
            exerciseCard,
            conditionCard,
            summaryCard
        ].forEach(stackView.addArrangedSubview)

        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(24)
        }

        weightCard.snp.makeConstraints {
            $0.height.equalTo(326)
        }

        exerciseCard.snp.makeConstraints {
            $0.height.equalTo(294)
        }

        conditionCard.snp.makeConstraints {
            $0.height.equalTo(294)
        }
    }
}

private class ReportCardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray100.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ReportWeightCardView: ReportCardView {
    private let titleLabel = UILabel(text: "몸무게 변화", config: .body14Medium, color: .gray600)
    private let fireLabel = UILabel(text: "🔥", config: .title24)
    private let valueLabel = UILabel(text: "-2", config: .title24)
    private let unitLabel = UILabel(text: "kg", config: .body14Medium, color: .gray600)
    private let chartView = ReportLineChartView(
        values: [71.1, 70.6, 70.2, 70.0, 69.7, 69.2, 69.0],
        yLabels: ["73kg", "72kg", "71kg", "70kg", "69kg", "68kg"],
        startLabel: "5/1",
        endLabel: "6/12",
        selectedValueText: "69.2kg",
        pointColor: .primary400,
        fillColor: UIColor.primary400.withAlphaComponent(0.16)
    )

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ReportWeightCardView {
    func setLayout() {
        [
            titleLabel,
            fireLabel,
            valueLabel,
            unitLabel,
            chartView
        ].forEach(addSubview)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
        }

        fireLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.equalTo(titleLabel)
        }

        valueLabel.snp.makeConstraints {
            $0.centerY.equalTo(fireLabel)
            $0.leading.equalTo(fireLabel.snp.trailing).offset(4)
        }

        unitLabel.snp.makeConstraints {
            $0.leading.equalTo(valueLabel.snp.trailing).offset(4)
            $0.lastBaseline.equalTo(valueLabel)
        }

        chartView.snp.makeConstraints {
            $0.top.equalTo(valueLabel.snp.bottom).offset(18)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}

private final class ReportExerciseCardView: ReportCardView {
    private let titleLabel = UILabel(text: "주간 운동 현황", config: .body14Medium, color: .gray600)
    private let stopwatchLabel = UILabel(text: "⏱️", config: .title24)
    private let valueLabel = UILabel(text: "50", config: .title24)
    private let unitLabel = UILabel(text: "분", config: .body14Medium, color: .gray600)
    private let segmentedView = ReportSmallSegmentedView(items: ["운동시간", "칼로리"])
    private let chartView = ReportBarChartView(values: [24, 34, 27, 38, 36, 70, 20])

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ReportExerciseCardView {
    func setLayout() {
        [
            titleLabel,
            stopwatchLabel,
            valueLabel,
            unitLabel,
            segmentedView,
            chartView
        ].forEach(addSubview)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
        }

        stopwatchLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.equalTo(titleLabel)
        }

        valueLabel.snp.makeConstraints {
            $0.centerY.equalTo(stopwatchLabel)
            $0.leading.equalTo(stopwatchLabel.snp.trailing).offset(4)
        }

        unitLabel.snp.makeConstraints {
            $0.leading.equalTo(valueLabel.snp.trailing).offset(4)
            $0.lastBaseline.equalTo(valueLabel)
        }

        segmentedView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(22)
            $0.trailing.equalToSuperview().inset(20)
            $0.width.equalTo(142)
            $0.height.equalTo(42)
        }

        chartView.snp.makeConstraints {
            $0.top.equalTo(valueLabel.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(18)
        }
    }
}

private final class ReportConditionCardView: ReportCardView {
    private let titleLabel = UILabel(text: "컨디션 변화", config: .body14Medium, color: .gray600)
    private let conditionDotView = UIView().then {
        $0.backgroundColor = UIColor(red: 0.94, green: 0.84, blue: 1.0, alpha: 1.0)
        $0.layer.cornerRadius = 14
    }
    private let valueLabel = UILabel(text: "최악", config: .title24)
    private let chartView = ReportLineChartView(
        values: [5, 4, 3.2, 3, 2.3, 1.5, 1.1],
        yLabels: ["", "", "", ""],
        startLabel: "5/1",
        endLabel: "6/12",
        selectedValueText: nil,
        pointColor: UIColor(red: 0.94, green: 0.84, blue: 1.0, alpha: 1.0),
        fillColor: UIColor.primary400.withAlphaComponent(0.12),
        pointImages: [
            CalendarReactor.ConditionValue.veryGood.image,
            CalendarReactor.ConditionValue.good.image,
            CalendarReactor.ConditionValue.normal.image,
            CalendarReactor.ConditionValue.normal.image,
            CalendarReactor.ConditionValue.bad.image,
            CalendarReactor.ConditionValue.worst.image,
            CalendarReactor.ConditionValue.worst.image
        ]
    )

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ReportConditionCardView {
    func setLayout() {
        [
            titleLabel,
            conditionDotView,
            valueLabel,
            chartView
        ].forEach(addSubview)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
        }

        conditionDotView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
            $0.leading.equalTo(titleLabel)
            $0.size.equalTo(28)
        }

        valueLabel.snp.makeConstraints {
            $0.centerY.equalTo(conditionDotView)
            $0.leading.equalTo(conditionDotView.snp.trailing).offset(6)
        }

        chartView.snp.makeConstraints {
            $0.top.equalTo(valueLabel.snp.bottom).offset(28)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}

private final class ReportSummaryCardView: UIView {
    private let titleStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 8
    }
    private let badgeLabel = UILabel(text: "AI 분석", config: .body12Medium, color: .primary400).then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.textAlignment = .center
    }
    private let titleLabel = UILabel(text: "오늘의 리포트 요약", config: .body14Medium)
    private let descriptionLabel = UILabel(
        text: "최근 4주 동안 운동 시간이 꾸준히 증가했어요. 체중 변화는\n크지 않지만 운동 빈도는 안정적으로 유지되고 있어요.",
        config: .body14Regular,
        color: .gray700,
        lines: 2
    )

    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ReportSummaryCardView {
    func setStyle() {
        backgroundColor = UIColor.primary400.withAlphaComponent(0.1)
        layer.cornerRadius = 12
    }

    func setLayout() {
        addSubview(titleStackView)
        addSubview(descriptionLabel)

        [
            badgeLabel,
            titleLabel
        ].forEach(titleStackView.addArrangedSubview)

        badgeLabel.snp.makeConstraints {
            $0.width.equalTo(52)
            $0.height.equalTo(24)
        }

        titleStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleStackView.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(18)
        }
    }
}

private final class ReportSmallSegmentedView: UIView {
    private let selectedLabel: UILabel
    private let normalLabel: UILabel

    init(items: [String]) {
        selectedLabel = UILabel(text: items.first ?? "", config: .body12Medium, color: .primary400)
        normalLabel = UILabel(text: items.dropFirst().first ?? "", config: .body12Medium, color: .gray500)

        super.init(frame: .zero)

        setStyle()
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ReportSmallSegmentedView {
    func setStyle() {
        backgroundColor = .gray25
        layer.cornerRadius = 21
    }

    func setLayout() {
        let selectedBackgroundView = UIView().then {
            $0.backgroundColor = .white
            $0.layer.cornerRadius = 18
        }

        addSubview(selectedBackgroundView)
        addSubview(selectedLabel)
        addSubview(normalLabel)

        selectedBackgroundView.snp.makeConstraints {
            $0.leading.verticalEdges.equalToSuperview().inset(3)
            $0.width.equalToSuperview().multipliedBy(0.5).offset(-3)
        }

        selectedLabel.snp.makeConstraints {
            $0.center.equalTo(selectedBackgroundView)
        }

        normalLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.centerX.equalToSuperview().multipliedBy(1.5)
        }
    }
}

private final class ReportLineChartView: UIView {
    private let values: [CGFloat]
    private let yLabels: [String]
    private let startLabel: String
    private let endLabel: String
    private let selectedValueText: String?
    private let pointColor: UIColor
    private let fillColor: UIColor
    private let pointImages: [UIImage?]

    init(
        values: [CGFloat],
        yLabels: [String],
        startLabel: String,
        endLabel: String,
        selectedValueText: String?,
        pointColor: UIColor,
        fillColor: UIColor,
        pointImages: [UIImage?] = []
    ) {
        self.values = values
        self.yLabels = yLabels
        self.startLabel = startLabel
        self.endLabel = endLabel
        self.selectedValueText = selectedValueText
        self.pointColor = pointColor
        self.fillColor = fillColor
        self.pointImages = pointImages

        super.init(frame: .zero)

        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              values.count > 1,
              let minimumValue = values.min(),
              let maximumValue = values.max()
        else { return }

        let leftPadding: CGFloat = yLabels.contains { !$0.isEmpty } ? 38 : 0
        let rightPadding: CGFloat = 16
        let topPadding: CGFloat = 14
        let bottomPadding: CGFloat = 28
        let chartRect = rect.inset(
            by: UIEdgeInsets(
                top: topPadding,
                left: leftPadding,
                bottom: bottomPadding,
                right: rightPadding
            )
        )

        drawGrid(in: chartRect, context: context)

        let valueRange = max(maximumValue - minimumValue, 1)
        let points = values.enumerated().map { index, value in
            let x = chartRect.minX + chartRect.width * CGFloat(index) / CGFloat(values.count - 1)
            let yRatio = (value - minimumValue) / valueRange
            let y = chartRect.maxY - chartRect.height * yRatio
            return CGPoint(x: x, y: y)
        }

        drawFill(points: points, chartRect: chartRect)
        drawLine(points: points)
        drawPoints(points: points)
        drawXAxisLabels(in: chartRect)

        if let selectedValueText {
            drawSelectedValue(selectedValueText, at: points[points.count - 2], chartRect: chartRect)
        }
    }
}

private extension ReportLineChartView {
    func drawGrid(in chartRect: CGRect, context: CGContext) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        let attributes: [NSAttributedString.Key: Any] = [
            .font: LabelConfiguration.body12Regular.font,
            .foregroundColor: UIColor.gray400,
            .paragraphStyle: paragraphStyle
        ]

        context.setStrokeColor(UIColor.gray100.cgColor)
        context.setLineWidth(1 / UIScreen.main.scale)

        let lineCount = max(yLabels.count, 4)
        for index in 0..<lineCount {
            let y = chartRect.minY + chartRect.height * CGFloat(index) / CGFloat(lineCount - 1)
            context.move(to: CGPoint(x: chartRect.minX, y: y))
            context.addLine(to: CGPoint(x: chartRect.maxX, y: y))
            context.strokePath()

            guard index < yLabels.count, !yLabels[index].isEmpty else { continue }

            let labelRect = CGRect(x: 0, y: y - 8, width: chartRect.minX - 8, height: 16)
            yLabels[index].draw(in: labelRect, withAttributes: attributes)
        }
    }

    func drawFill(points: [CGPoint], chartRect: CGRect) {
        let fillPath = UIBezierPath()
        fillPath.move(to: CGPoint(x: points[0].x, y: chartRect.maxY))
        points.forEach { fillPath.addLine(to: $0) }
        fillPath.addLine(to: CGPoint(x: points.last?.x ?? chartRect.maxX, y: chartRect.maxY))
        fillPath.close()
        fillColor.setFill()
        fillPath.fill()
    }

    func drawLine(points: [CGPoint]) {
        let linePath = UIBezierPath()
        linePath.move(to: points[0])
        points.dropFirst().forEach { linePath.addLine(to: $0) }
        pointColor.setStroke()
        linePath.lineWidth = 2
        linePath.stroke()
    }

    func drawPoints(points: [CGPoint]) {
        points.enumerated().forEach { index, point in
            guard index < pointImages.count,
                  let image = pointImages[index]
            else {
                pointColor.setFill()
                UIBezierPath(ovalIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)).fill()
                return
            }

            let imageSize: CGFloat = 24
            let imageRect = CGRect(
                x: point.x - imageSize / 2,
                y: point.y - imageSize / 2,
                width: imageSize,
                height: imageSize
            )
            let clipPath = UIBezierPath(ovalIn: imageRect)
            UIColor.white.setFill()
            clipPath.fill()

            UIColor.white.setStroke()
            clipPath.lineWidth = 2
            clipPath.stroke()

            image.draw(in: imageRect.insetBy(dx: 2, dy: 2))
        }
    }

    func drawXAxisLabels(in chartRect: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: LabelConfiguration.body12Regular.font,
            .foregroundColor: UIColor.gray400
        ]
        startLabel.draw(
            in: CGRect(x: chartRect.minX, y: chartRect.maxY + 8, width: 48, height: 16),
            withAttributes: attributes
        )
        endLabel.draw(
            in: CGRect(x: chartRect.maxX - 48, y: chartRect.maxY + 8, width: 48, height: 16),
            withAttributes: attributes
        )
    }

    func drawSelectedValue(_ text: String, at point: CGPoint, chartRect: CGRect) {
        let dashPath = UIBezierPath()
        dashPath.move(to: CGPoint(x: point.x, y: point.y + 8))
        dashPath.addLine(to: CGPoint(x: point.x, y: chartRect.maxY))
        UIColor.gray400.setStroke()
        dashPath.setLineDash([3, 3], count: 2, phase: 0)
        dashPath.lineWidth = 1
        dashPath.stroke()

        let labelSize = CGSize(width: 66, height: 28)
        let labelRect = CGRect(
            x: min(max(point.x - labelSize.width / 2, chartRect.minX), chartRect.maxX - labelSize.width),
            y: max(point.y - 34, 0),
            width: labelSize.width,
            height: labelSize.height
        )
        let bubblePath = UIBezierPath(roundedRect: labelRect, cornerRadius: 14)
        UIColor.gray25.setFill()
        bubblePath.fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        text.draw(
            in: labelRect.insetBy(dx: 0, dy: 7),
            withAttributes: [
                .font: LabelConfiguration.body12Medium.font,
                .foregroundColor: UIColor.gray600,
                .paragraphStyle: paragraphStyle
            ]
        )
    }
}

private final class ReportBarChartView: UIView {
    private let values: [CGFloat]
    private let xLabels = ["월", "화", "수", "목", "금", "토", "일"]
    private let yLabels = ["90", "60", "30", "0"]

    init(values: [CGFloat]) {
        self.values = values

        super.init(frame: .zero)

        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              values.isEmpty == false
        else { return }

        let chartRect = rect.inset(by: UIEdgeInsets(top: 8, left: 38, bottom: 28, right: 0))
        drawGrid(in: chartRect, context: context)
        drawBars(in: chartRect)
        drawXAxisLabels(in: chartRect)
    }
}

private extension ReportBarChartView {
    func drawGrid(in chartRect: CGRect, context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: LabelConfiguration.body12Regular.font,
            .foregroundColor: UIColor.gray400
        ]

        context.setStrokeColor(UIColor.gray100.cgColor)
        context.setLineWidth(1 / UIScreen.main.scale)

        for index in 0..<yLabels.count {
            let y = chartRect.minY + chartRect.height * CGFloat(index) / CGFloat(yLabels.count - 1)
            context.move(to: CGPoint(x: chartRect.minX, y: y))
            context.addLine(to: CGPoint(x: chartRect.maxX, y: y))
            context.strokePath()

            yLabels[index].draw(
                in: CGRect(x: 0, y: y - 8, width: chartRect.minX - 8, height: 16),
                withAttributes: attributes
            )
        }

        let dashedY = chartRect.minY + chartRect.height * 0.22
        context.setStrokeColor(UIColor.gray300.cgColor)
        context.setLineDash(phase: 0, lengths: [3, 4])
        context.move(to: CGPoint(x: chartRect.minX, y: dashedY))
        context.addLine(to: CGPoint(x: chartRect.maxX, y: dashedY))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])
    }

    func drawBars(in chartRect: CGRect) {
        let maxValue = max(values.max() ?? 1, 1)
        let slotWidth = chartRect.width / CGFloat(values.count)
        let barWidth = min(slotWidth * 0.62, 28)

        UIColor.primary400.setFill()

        values.enumerated().forEach { index, value in
            let barHeight = chartRect.height * value / maxValue
            let x = chartRect.minX + slotWidth * CGFloat(index) + (slotWidth - barWidth) / 2
            let rect = CGRect(x: x, y: chartRect.maxY - barHeight, width: barWidth, height: barHeight)
            UIBezierPath(roundedRect: rect, cornerRadius: 8).fill()
        }
    }

    func drawXAxisLabels(in chartRect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: LabelConfiguration.body12Regular.font,
            .foregroundColor: UIColor.gray400,
            .paragraphStyle: paragraphStyle
        ]
        let slotWidth = chartRect.width / CGFloat(xLabels.count)

        xLabels.enumerated().forEach { index, label in
            let rect = CGRect(
                x: chartRect.minX + slotWidth * CGFloat(index),
                y: chartRect.maxY + 8,
                width: slotWidth,
                height: 16
            )
            label.draw(in: rect, withAttributes: attributes)
        }
    }
}
