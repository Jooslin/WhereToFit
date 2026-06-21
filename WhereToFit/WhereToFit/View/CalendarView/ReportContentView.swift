//
//  ReportContentView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/16/26.
//

import SwiftUI
import UIKit

struct ReportContentSwiftUIView: View {
    let report: CalendarReactor.ReportState

    var body: some View {
        Group {
            if report.isEmpty {
                EmptyReportContentSwiftUIView()
            } else {
                ReportDashboardSwiftUIView(report: report)
            }
        }
        .background(Color.white)
    }
}

private struct EmptyReportContentSwiftUIView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: UIImage(resource: .report))
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
                .padding(.top, 118)

            Text("캘린더에서 정보를 입력하면\n리포트를 작성해드려요")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(.gray600))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 24)

            Button("정보 입력하러 가기") {}
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(.primary400))
                .clipShape(Capsule())
                .padding(.horizontal, 16)
                .padding(.top, 28)

            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 620)
    }
}

private struct ReportDashboardSwiftUIView: View {
    let report: CalendarReactor.ReportState

    var body: some View {
        VStack(spacing: 24) {
            ReportWeightCardSwiftUIView(state: report.weight)
            ReportExerciseCardSwiftUIView(state: report.exercise)
            ReportConditionCardSwiftUIView(state: report.condition)
            ReportSummaryCardSwiftUIView()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
}

private struct ReportCardContainer<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.gray100), lineWidth: 1)
            }
    }
}

private struct ReportWeightCardSwiftUIView: View {
    let state: CalendarReactor.WeightReportState

    var body: some View {
        ReportCardContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("몸무게 변화")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.gray600))

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 24, weight: .bold))
                    Text(state.changeText)
                        .font(.system(size: 24, weight: .bold))
                    Text("kg")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(.gray600))
                }
                .padding(.top, 6)

                if let emptyMessage = state.emptyMessage {
                    ReportEmptyMessageView(text: emptyMessage)
                        .frame(maxHeight: .infinity)
                } else {
                    ReportLineChartSwiftUIView(
                        values: state.values,
                        yLabels: state.yLabels,
                        startLabel: state.startLabel,
                        endLabel: state.endLabel,
                        selectedValueText: state.selectedValueText,
                        pointColor: Color(.primary400),
                        fillColor: Color(.primary400).opacity(0.16)
                    )
                    .padding(.top, 18)
                }
            }
            .padding(20)
            .frame(height: 326)
        }
    }
}

private struct ReportExerciseCardSwiftUIView: View {
    let state: CalendarReactor.ExerciseReportState

    var body: some View {
        ReportCardContainer {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("주간 운동 현황")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(.gray600))

                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("⏱️")
                                .font(.system(size: 24, weight: .bold))
                            Text(state.totalMinutesText)
                                .font(.system(size: 24, weight: .bold))
                            Text("분")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(.gray600))
                        }
                    }

                    Spacer()

                    ReportSmallSegmentedSwiftUIView()
                        .frame(width: 142, height: 42)
                        .padding(.top, 2)
                }

                if let emptyMessage = state.emptyMessage {
                    ReportEmptyMessageView(text: emptyMessage)
                        .frame(maxHeight: .infinity)
                } else {
                    ReportBarChartSwiftUIView(values: state.dailyMinutes)
                        .padding(.top, 20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(height: 294)
        }
    }
}

private struct ReportConditionCardSwiftUIView: View {
    let state: CalendarReactor.ConditionReportState

    var body: some View {
        ReportCardContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("컨디션 변화")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.gray600))

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.94, green: 0.84, blue: 1.0))
                        .frame(width: 28, height: 28)

                    Text(state.latestText)
                        .font(.system(size: 24, weight: .bold))
                }
                .padding(.top, 10)

                if let emptyMessage = state.emptyMessage {
                    ReportEmptyMessageView(text: emptyMessage)
                        .frame(maxHeight: .infinity)
                } else {
                    ReportLineChartSwiftUIView(
                        values: state.values,
                        yLabels: ["", "", "", ""],
                        startLabel: state.startLabel,
                        endLabel: state.endLabel,
                        selectedValueText: nil,
                        pointColor: Color(red: 0.94, green: 0.84, blue: 1.0),
                        fillColor: Color(.primary400).opacity(0.12),
                        pointImages: state.conditionValues.map(\.image)
                    )
                    .padding(.top, 28)
                }
            }
            .padding(20)
            .frame(height: 294)
        }
    }
}

private struct ReportSummaryCardSwiftUIView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("AI 분석")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(.primary400))
                    .frame(width: 52, height: 24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("오늘의 리포트 요약")
                    .font(.system(size: 14, weight: .medium))
            }

            Text("최근 4주 동안 운동 시간이 꾸준히 증가했어요. 체중 변화는\n크지 않지만 운동 빈도는 안정적으로 유지되고 있어요.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(.gray700))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(Color(.primary400).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ReportEmptyMessageView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color(.gray500))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ReportSmallSegmentedSwiftUIView: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color(.gray25))

            Capsule()
                .fill(Color.white)
                .padding(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(width: 71)

            HStack(spacing: 0) {
                Text("운동시간")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(.primary400))
                    .frame(maxWidth: .infinity)

                Text("칼로리")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(.gray500))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct ReportLineChartSwiftUIView: View {
    let values: [Double]
    let yLabels: [String]
    let startLabel: String
    let endLabel: String
    let selectedValueText: String?
    let pointColor: Color
    let fillColor: Color
    var pointImages: [UIImage?] = []

    var body: some View {
        GeometryReader { proxy in
            let chart = lineChartMetrics(size: proxy.size, values: values, yLabels: yLabels)

            ZStack(alignment: .topLeading) {
                ReportLineChartGridView(chart: chart, yLabels: yLabels)

                Path { path in
                    guard let first = chart.points.first else { return }
                    path.move(to: CGPoint(x: first.x, y: chart.rect.maxY))
                    chart.points.forEach { path.addLine(to: $0) }
                    path.addLine(to: CGPoint(x: chart.points.last?.x ?? chart.rect.maxX, y: chart.rect.maxY))
                    path.closeSubpath()
                }
                .fill(fillColor)

                Path { path in
                    guard let first = chart.points.first else { return }
                    path.move(to: first)
                    chart.points.dropFirst().forEach { path.addLine(to: $0) }
                }
                .stroke(pointColor, lineWidth: 2)

                ForEach(chart.points.indices, id: \.self) { index in
                    ReportLineChartPointView(
                        point: chart.points[index],
                        pointColor: pointColor,
                        image: index < pointImages.count ? pointImages[index] : nil
                    )
                }

                if let selectedValueText,
                   chart.points.count > 1 {
                    ReportSelectedValueView(
                        text: selectedValueText,
                        point: chart.points[chart.points.count - 2],
                        chartRect: chart.rect
                    )
                }

                ReportXAxisLabelsView(
                    chartRect: chart.rect,
                    startLabel: startLabel,
                    endLabel: endLabel
                )
            }
        }
    }
}

private struct ReportBarChartSwiftUIView: View {
    let values: [Double]
    private let xLabels = ["월", "화", "수", "목", "금", "토", "일"]
    private let yLabels = ["90", "60", "30", "0"]

    var body: some View {
        GeometryReader { proxy in
            let chartRect = CGRect(
                x: 38,
                y: 8,
                width: max(proxy.size.width - 38, 0),
                height: max(proxy.size.height - 36, 0)
            )
            let maxValue = max(values.max() ?? 1, 1)
            let slotWidth = values.isEmpty ? 0 : chartRect.width / CGFloat(values.count)
            let barWidth = min(slotWidth * 0.62, 28)

            ZStack(alignment: .topLeading) {
                ForEach(yLabels.indices, id: \.self) { index in
                    let y = chartRect.minY + chartRect.height * CGFloat(index) / CGFloat(yLabels.count - 1)
                    Path { path in
                        path.move(to: CGPoint(x: chartRect.minX, y: y))
                        path.addLine(to: CGPoint(x: chartRect.maxX, y: y))
                    }
                    .stroke(Color(.gray100), lineWidth: 1 / UIScreen.main.scale)

                    Text(yLabels[index])
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(.gray400))
                        .frame(width: chartRect.minX - 8, height: 16, alignment: .leading)
                        .position(x: (chartRect.minX - 8) / 2, y: y)
                }

                Path { path in
                    let y = chartRect.minY + chartRect.height * 0.22
                    path.move(to: CGPoint(x: chartRect.minX, y: y))
                    path.addLine(to: CGPoint(x: chartRect.maxX, y: y))
                }
                .stroke(Color(.gray300), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                ForEach(values.indices, id: \.self) { index in
                    let value = values[index]
                    let barHeight = chartRect.height * CGFloat(value / maxValue)
                    let x = chartRect.minX + slotWidth * CGFloat(index) + (slotWidth - barWidth) / 2
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.primary400))
                        .frame(width: barWidth, height: barHeight)
                        .position(x: x + barWidth / 2, y: chartRect.maxY - barHeight / 2)
                }

                ForEach(xLabels.indices, id: \.self) { index in
                    let labelWidth = chartRect.width / CGFloat(xLabels.count)
                    Text(xLabels[index])
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(.gray400))
                        .frame(width: labelWidth, height: 16)
                        .position(
                            x: chartRect.minX + labelWidth * CGFloat(index) + labelWidth / 2,
                            y: chartRect.maxY + 16
                        )
                }
            }
        }
    }
}

private struct ReportLineChartGridView: View {
    let chart: LineChartMetrics
    let yLabels: [String]

    var body: some View {
        let lineCount = max(yLabels.count, 4)

        ForEach(0..<lineCount, id: \.self) { index in
            let y = chart.rect.minY + chart.rect.height * CGFloat(index) / CGFloat(lineCount - 1)

            Path { path in
                path.move(to: CGPoint(x: chart.rect.minX, y: y))
                path.addLine(to: CGPoint(x: chart.rect.maxX, y: y))
            }
            .stroke(Color(.gray100), lineWidth: 1 / UIScreen.main.scale)

            if index < yLabels.count, yLabels[index].isEmpty == false {
                Text(yLabels[index])
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(.gray400))
                    .frame(width: chart.rect.minX - 8, height: 16, alignment: .trailing)
                    .position(x: (chart.rect.minX - 8) / 2, y: y)
            }
        }
    }
}

private struct ReportLineChartPointView: View {
    let point: CGPoint
    let pointColor: Color
    let image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(2)
                    .frame(width: 24, height: 24)
                    .background(Color.white)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(pointColor)
                    .frame(width: 8, height: 8)
            }
        }
        .position(point)
    }
}

private struct ReportSelectedValueView: View {
    let text: String
    let point: CGPoint
    let chartRect: CGRect

    var body: some View {
        let labelWidth: CGFloat = 66
        let labelX = min(max(point.x, chartRect.minX + labelWidth / 2), chartRect.maxX - labelWidth / 2)

        ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: CGPoint(x: point.x, y: point.y + 8))
                path.addLine(to: CGPoint(x: point.x, y: chartRect.maxY))
            }
            .stroke(Color(.gray400), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(.gray600))
                .frame(width: labelWidth, height: 28)
                .background(Color(.gray25))
                .clipShape(Capsule())
                .position(x: labelX, y: max(point.y - 20, 14))
        }
    }
}

private struct ReportXAxisLabelsView: View {
    let chartRect: CGRect
    let startLabel: String
    let endLabel: String

    var body: some View {
        Text(startLabel)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color(.gray400))
            .frame(width: 48, height: 16, alignment: .leading)
            .position(x: chartRect.minX + 24, y: chartRect.maxY + 16)

        Text(endLabel)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color(.gray400))
            .frame(width: 48, height: 16, alignment: .trailing)
            .position(x: chartRect.maxX - 24, y: chartRect.maxY + 16)
    }
}

private struct LineChartMetrics {
    let rect: CGRect
    let points: [CGPoint]
}

private func lineChartMetrics(
    size: CGSize,
    values: [Double],
    yLabels: [String]
) -> LineChartMetrics {
    guard values.count > 1,
          let minimumValue = values.min(),
          let maximumValue = values.max()
    else {
        return LineChartMetrics(rect: .zero, points: [])
    }

    let leftPadding: CGFloat = yLabels.contains { !$0.isEmpty } ? 38 : 0
    let rightPadding: CGFloat = 16
    let topPadding: CGFloat = 14
    let bottomPadding: CGFloat = 28
    let chartRect = CGRect(
        x: leftPadding,
        y: topPadding,
        width: max(size.width - leftPadding - rightPadding, 0),
        height: max(size.height - topPadding - bottomPadding, 0)
    )
    let valueRange = max(maximumValue - minimumValue, 1)
    let points = values.enumerated().map { index, value in
        let x = chartRect.minX + chartRect.width * CGFloat(index) / CGFloat(values.count - 1)
        let yRatio = CGFloat((value - minimumValue) / valueRange)
        let y = chartRect.maxY - chartRect.height * yRatio
        return CGPoint(x: x, y: y)
    }

    return LineChartMetrics(rect: chartRect, points: points)
}
