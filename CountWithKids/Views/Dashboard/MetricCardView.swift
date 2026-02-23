import SwiftUI

struct MetricCardView: View {
    @Environment(\.appTheme) var theme
    let title: String
    let value: String
    let subtitle: String
    let chartData: [ChartBucket]
    let chartColor: Color
    let chartUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .playfulFont(size: 14, weight: .medium)
                        .foregroundColor(.secondary)

                    Text(value)
                        .playfulFont(size: 32)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .playfulFont(size: 12, weight: .regular)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            BarChartView(data: chartData, color: chartColor, unit: chartUnit)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}
